# frozen_string_literal: true

require "digest"
require "etc"
require "fileutils"

module Sigma
  # Runs sigma inside the build container: `./sigma build` on the host builds
  # the image if the Dockerfile changed, then re-runs itself in a container
  # with the checkout mounted at /app and the same arguments.
  class Docker
    MOUNT = "/app"
    LABEL = "org.sigma-linux.dockerfile"
    PLATFORMS = { "x86_64" => "linux/amd64", "aarch64" => "linux/arm64" }.freeze

    def self.inside? = ENV["SIGMA_CONTAINER"] == "1"

    def initialize(config, ui)
      @config = config
      @ui = ui
      @shell = Shell.new(builder: config.builder)
    end

    def dispatch(argv)
      check_docker
      setup_binfmt if cross?
      build_image
      shell = argv.first == "shell"
      exec(*run_command(shell ? ["/bin/sh"] : ["./sigma", *argv], stdin: shell))
    end

    private

    def image = @config.fetch("docker.image")
    def dockerfile = File.join(@config.root, "Dockerfile")
    def platform = PLATFORMS.fetch(@config.arch) { raise Error, "no container platform known for arch #{@config.arch}" }
    def cross? = @config.arch != Etc.uname[:machine]

    # The UID the image's build user gets. Root on the host (some CI) has no
    # meaningful UID to match, so fall back to the usual first user.
    def build_uid = Process.uid.zero? ? 1000 : Process.uid

    def check_docker
      unless @shell.available?("docker")
        raise Error.new("docker is not installed",
                        hint: "Install Docker, or run natively inside an Alpine environment with --native.")
      end
      @shell.capture("docker", "info", "--format", "{{.ServerVersion}}")
    rescue CommandFailed => e
      raise Error.new("can't reach the Docker daemon (#{e.tail.last || "docker info failed"})",
                      hint: "Start it (e.g. `doas rc-service docker start`) and make sure you can use its socket.")
    end

    # The image is rebuilt only when the Dockerfile (or the build UID) changes;
    # the label records what it was built from.
    def build_image
      wanted = Digest::SHA256.hexdigest(File.read(dockerfile) + build_uid.to_s + platform)[0, 16]
      current = begin
        @shell.capture("docker", "image", "inspect", image, "--format", "{{index .Config.Labels \"#{LABEL}\"}}").strip
      rescue CommandFailed
        nil
      end
      return if current == wanted

      context = Context.new(@config, @ui)
      @ui.blank
      context.task(:container, "image", label: "build container image") do |task|
        @shell.run(task, "docker", "build", "--platform", platform, "--build-arg", "BUILD_UID=#{build_uid}",
                   "--label", "#{LABEL}=#{wanted}", "-t", image, "-f", dockerfile, @config.root)
        task.detail = image
      end
    end

    def setup_binfmt
      return if File.exist?("/proc/sys/fs/binfmt_misc/qemu-#{@config.arch}")
      unless File.exist?("/proc/sys/fs/binfmt_misc/register")
        raise Error.new("building for #{@config.arch} needs binfmt_misc, which isn't mounted",
                        hint: "doas modprobe binfmt_misc && doas mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc")
      end

      Context.new(@config, @ui).task(:container, "binfmt", label: "enable #{@config.arch} emulation") do |task|
        @shell.run(task, "docker", "run", "--privileged", "--rm", "tonistiigi/binfmt", "--install", @config.arch)
      end
    end

    # cache/ and out/ may be configured to live outside the checkout (another
    # disk, say); those are mounted at the same path so the config still works.
    def outside_mounts
      [@config.paths.cache, @config.paths.out].reject { |p| p.start_with?("#{@config.root}/") }.flat_map do |path|
        FileUtils.mkdir_p(path)
        ["-v", "#{path}:#{path}"]
      end
    end

    # --privileged: building the image mounts and chroots. --init: so signals
    # (Ctrl-C) reach sigma, which then unmounts before exiting.
    def run_command(command, stdin: false)
      interactive = if $stdin.tty? then ["-it"]
                    elsif stdin then ["-i"]
                    else []
                    end
      env = { "SIGMA_HOST_UID" => Process.uid, "SIGMA_HOST_GID" => Process.gid }
      %w[TERM COLORTERM NO_COLOR FORCE_COLOR].each { |name| env[name] = ENV[name] if ENV[name] }
      ["docker", "run", "--rm", "--init", "--privileged", *interactive, "--platform", platform,
       "-v", "#{@config.root}:#{MOUNT}", *outside_mounts, "-w", MOUNT,
       *env.flat_map { |k, v| ["-e", "#{k}=#{v}"] }, image, *command]
    end
  end
end
