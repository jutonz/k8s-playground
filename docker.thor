#!/usr/local/bin/ruby

require "pty"

class Docker < Thor
  # When pushing updated container versions, update these constants. They are
  # used when pushing, pulling, and building images.
  BASE_IMAGE_VERSION = 5
  RUBY_IMAGE_VERSION = 6
  PSQL_IMAGE_VERSION = 5

  ALL_IMAGES = %w(base ruby psql).freeze

  desc "build", "Build images. Pass image name to build a specific one; otherwise builds all"
  def build(*images)
    images = ALL_IMAGES if images == nil
    images = Array(images)

    puts "Generating build script for #{images.join(", ")}"
    bash = "#!/bin/bash -x\n"

    images.each do |image|
      version    = self.class.const_get "#{image.upcase}_IMAGE_VERSION"
      tag        = "jutonz/k8s-playground-dev-#{image}:#{version}"
      dockerfile = "docker/dev/#{image}/Dockerfile"

      bash += "#{sudo}docker #{docker_opts} build -f #{dockerfile} -t #{tag} .\n"
    end

    Tempfile.open ["build-script", ".sh"] do |tempfile|
      tempfile.write bash
      tempfile.flush

      puts "Build script written to #{tempfile.path}"

      puts "I will need your password to make the build script executable"
      `sudo chmod +x #{tempfile.path}`

      exec "/bin/bash -c #{tempfile.path}" # totally legit
    end
  end

  desc "push", "Upload locally built images to the remote store"
  def push(images = "all")
    images = ALL_IMAGES if images == "all"
    images = Array(images)

    push_cmds = []

    images.each do |image|
      version = self.class.const_get "#{image.upcase}_IMAGE_VERSION"
      tag_cmd = "#{sudo}docker tag jutonz/k8s-playground-dev-#{image}:#{version} jutonz/k8s-playground-dev-#{image}:latest"
      puts tag_cmd
      `#{tag_cmd}`

      push_cmds << "#{sudo}docker push jutonz/k8s-playground-dev-#{image}:#{version}"
      push_cmds << "#{sudo}docker push jutonz/k8s-playground-dev-#{image}:latest"
    end

    push_cmd = push_cmds.join " && "
    stream_output push_cmd, exec: true
  end

  desc "pull", "Pull the latest remote images to your local machine"
  def pull(images = "all")
    images = ALL_IMAGES if images == "all"
    images = Array(images)

    pull_cmds = []

    images.each do |image|
      version = self.class.const_get "#{image.upcase}_IMAGE_VERSION"
      pull_cmds << "#{sudo}docker pull jutonz/k8s-playground-dev-#{image}:#{version}"
    end

    pull_cmd = pull_cmds.join " && "
    stream_output pull_cmd, exec: true
  end

  desc "up", "Start your dockerized app server"
  def up
    # Pull remote images and start containers
    # Meant for devs who don't know anything about docker
    #
    # docker run jutonz/k8s-playground/base
  end

  desc "cleanup", "cleans up dangling docker images"
  def cleanup
    dangling = `#{sudo}docker images --filter dangling=true -q`.split("\n")

    if dangling.none?
      puts "No images to cleanup. Yay!"
      exit 0
    end

    puts "Cleaning up dangling images: #{dangling.join(", ")}"
    stream_output "#{sudo}docker rmi -f #{dangling.join(" ")}", exec: true
  end

  desc "ssh CONTAINER", "ssh into the given container"
  def ssh(container = "ruby")
    version   = self.class.const_get "#{container.upcase}_IMAGE_VERSION"
    container = "jutonz/k8s-playground-dev-#{container}:#{version}"
    stream_output "#{sudo}docker run -it --rm --network=bridge --cap-add=SYS_ADMIN --volume #{`pwd`.chomp}:/root #{container} /bin/bash", exec: true
  end

  no_commands do
    def stream_output(string, print_command: true, exec: false)
      puts string if print_command
      if exec
        exec string
      else
        PTY.spawn string do |stdout, stdin, pid|
          stdout.each { |line| puts line }
        end
      end
    end

    def sudo
      `uname`.chomp == "Darwin" ? "" : "sudo " # use sudo on linux hosts
    end

    def docker_opts
      return "" unless ENV["JENKINS"]
      opts = "--tls"

      if host = ENV["DOCKER_HOST_IP"]
        opts += " --host tcp://#{host}"
      end

      opts
    end

    def docker_cmd
      cmd = Cocaine::CommandLine.new "docker"
    end
  end
end
