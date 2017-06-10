class Docker < Thor
  desc "build", "builds the docker image stack"
  def build
    puts "Generating build script"

    # This is basically a lightweight docker-compose replacement as the real
    # thing is, to be completely honest, pretty annoying to setup with a remote
    # tls-enabled docker host.
    bash = <<~EOL
      #!/bin/bash -x

      docker #{docker_opts} build -f docker/dev/base/Dockerfile -t jutonz/k8s-playground/dev/base .
      docker #{docker_opts} build -f docker/dev/ruby/Dockerfile -t jutonz/k8s-playground/dev/ruby .
    EOL

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
  def push
    # Push to docker hub/ecr/whatever
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
    dangling = `docker images --filter dangling=true -q`.split("\n")

    if dangling.none?
      puts "No images to cleanup. Yay!"
      exit 0
    end

    puts "Cleaning up dangling images: #{dangling.join(", ")}"
    stream_output "docker rmi -f #{dangling.join(" ")}", exec: true
  end

  desc "ssh CONTAINER", "ssh into the given container"
  def ssh(container = "jutonz/k8s-playground/dev/app")
    stream_output "docker run -it --rm --network=bridge --cap-add=SYS_ADMIN #{container} /bin/bash", exec: true
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
