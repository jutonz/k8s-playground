#!/usr/bin/ruby

require "thor"
require "pty"
require "rainbow"

class Docker < Thor
  # When pushing updated container versions, update these constants. They are
  # used when pushing, pulling, and building images.
  VERSIONS = {
    "dev" => {
      "base" => 5,
      "ruby" => 9,
      "psql" => 7
    },
    "prod" => {
      "nginx" => 18,
      "rails" => 7,
      "psql"  => 1
    }
  }.freeze

  #ALL_IMAGES = %w(base ruby psql nginx rails).freeze
  ALL_IMAGES = {
    "dev"  => %w(base ruby psql),
    "prod" => %w(nginx rails psql)
  }.freeze

  desc "build", "Build images. Pass image name to build a specific one; otherwise builds all"
  option :env, default: "dev", type: :string
  def build(*images)
    env = options[:env]
    images = ALL_IMAGES[env] if images.empty?
    images = Array(images)

    puts "Generating build script for #{images.join(", ")}"
    commands = []

    images.each do |image|
      version    = VERSIONS.dig env, image
      tag        = "jutonz/k8s-playground-#{env}-#{image}:#{version}"
      dockerfile = "docker/#{env}/#{image}/Dockerfile"

      commands << "#{sudo}docker #{docker_opts} build -f #{dockerfile} -t #{tag} ."
    end

    stream_output commands.join(" && "), exec: true
  end

  desc "push", "Upload locally built images to the remote store"
  option :env, default: "dev", type: :string
  def push(*images)
    env = options[:env]
    images = ALL_IMAGES[env] if images.empty?
    images = Array(images)

    push_cmds = []

    images.each do |image|
      version = VERSIONS.dig env, image
      tag_cmd = "#{sudo}docker tag jutonz/k8s-playground-#{env}-#{image}:#{version} jutonz/k8s-playground-#{env}-#{image}:latest"
      puts tag_cmd
      `#{tag_cmd}`

      push_cmds << "#{sudo}docker push jutonz/k8s-playground-#{env}-#{image}:#{version}"
    end

    push_cmd = push_cmds.join " && "
    stream_output push_cmd, exec: true
  end

  desc "pull", "Pull the latest remote images to your local machine"
  option :env, default: "dev", type: :string
  def pull(*images)
    env    = options[:env]
    images = ALL_IMAGES[env] if images.empty?
    images = Array(images)

    pull_cmds = []

    images.each do |image|
      version = VERSIONS.dig env, image
      pull_cmds << "#{sudo}docker pull jutonz/k8s-playground-#{env}-#{image}:#{version}"
    end

    pull_cmd = pull_cmds.join " && "
    stream_output pull_cmd, exec: true
  end

  desc "up", "Start your dockerized app server"
  option :env, default: "dev", type: :string
  def up
    if `which docker-compose`.chomp.empty?
      error = "Could not find docker-compose executible in path. Please " \
        "install it to continue"
      puts Rainbow(error).fg :red
      exit 1
    end

    pidfile = "tmp/pids/server.pid"
    FileUtils.rm pidfile if File.exist? pidfile

    env = options[:env]
    compose_file = File.expand_path "docker/#{env}/docker-compose.yml"

    up_args = %w(
      --abort-on-container-exit
      --force-recreate
    ).join(" ")
    up_args = ''

    stream_output "#{sudo}docker-compose -f #{compose_file} up #{up_args}", exec: true
  end

  desc "initdb", "Setup initial postgres database"
  def initdb
    local_data_dir = File.expand_path "../tmp/psql", __FILE__
    `#{sudo}rm -r #{local_data_dir}` if File.exists? local_data_dir # todo prompt

    container = "psql"
    version = VERSIONS.dig "dev", container
    container = "jutonz/k8s-playground-dev-psql:#{version}"
    stream_output "#{sudo}docker run --rm --volume #{local_data_dir}:/var/lib/postgresql/data --volume #{`pwd`.chomp}:/tmp/code #{container} /bin/bash -c /etc/initdb.sh", exec: true
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

  desc "bash CONTAINER", "Create a new instance of the given image with a bash prompt"
  option :env, default: "dev", type: :string
  def bash(image = "ruby")
    env     = options[:env]
    version = VERSIONS.dig env, image
    image   = "jutonz/k8s-playground-#{env}-#{image}:#{version}"
    stream_output "#{sudo}docker run -it --rm --volume #{`pwd`.chomp}:/root #{image} /bin/bash", exec: true
  end

  desc "connect CONTAINER", "Connect to a running container"
  option :env, default: "dev", type: :string
  def connect(image = "ruby")
    env     = options[:env]
    version = VERSIONS.dig env, image
    image   = "jutonz/k8s-playground-#{env}-#{image}:#{version}"

    cmd = "#{sudo}docker ps --filter ancestor=#{image} -aq"
    puts cmd
    container = `#{cmd}`.chomp

    if container.empty?
      puts Rainbow("No running containers for image #{image}").red
      exit 1
    end

    stream_output "#{sudo}docker exec -it #{container} /bin/bash", exec: true
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
