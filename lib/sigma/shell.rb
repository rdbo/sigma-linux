# frozen_string_literal: true

require "open3"

module Sigma
  # Runs external commands. Output never goes straight to the terminal: it is
  # fed line by line to the running UI task, which writes it to the task's log
  # and shows the latest line (or every line, in verbose mode).
  class Shell
    TAIL_LINES = 80

    def initialize(builder:)
      @builder = builder
    end

    def root? = Process.uid.zero?

    # Runs +cmd+ as part of +task+. Raises CommandFailed on a non-zero exit.
    #
    #   as: :builder  run as the unprivileged abuild user (only matters as root)
    #   input:        string written to the command's stdin
    #   heavy:        long CPU-bound work (compiling, compressing); runs at
    #                 lower CPU priority so the machine stays usable
    def run(task, *cmd, env: {}, chdir: nil, as: nil, input: nil, heavy: false)
      cmd = cmd.flatten.map(&:to_s)
      argv, spawn_env = wrap(heavy ? ["nice", "-n", "10", *cmd] : cmd, env, as)
      task.log&.puts("$ #{display(cmd, env)}")
      tail = []

      status = Open3.popen2e(spawn_env, *argv, **spawn_options(chdir)) do |stdin, out, wait|
        stdin.write(input) if input
        stdin.close
        each_line(out) do |line|
          task.output(line)
          tail << line
          tail.shift if tail.size > TAIL_LINES
        end
        wait.value
      end

      return if status.success?

      # The log has the full command with its environment; the error keeps
      # to the command itself.
      raise CommandFailed.new(display(cmd, {}), status.exitstatus || status.termsig,
                              log_path: task.log&.path, tail: tail)
    rescue Errno::ENOENT
      raise Error.new("command not found: #{cmd.first}",
                      hint: "Is it installed? Building inside the container (the default) provides every tool.")
    end

    # Runs a query and returns its stdout. For short commands whose output we
    # parse; failures raise with stderr attached.
    def capture(*cmd, env: {}, chdir: nil, as: nil)
      cmd = cmd.flatten.map(&:to_s)
      argv, spawn_env = wrap(cmd, env, as)
      out, err, status = Open3.capture3(spawn_env, *argv, **spawn_options(chdir))
      return out if status.success?

      raise CommandFailed.new(display(cmd, env), status.exitstatus, tail: err.lines.last(TAIL_LINES).map(&:chomp))
    rescue Errno::ENOENT
      raise Error, "command not found: #{cmd.first}"
    end

    def available?(command)
      ENV.fetch("PATH", "").split(":").any? { |dir| File.executable?(File.join(dir, command)) }
    end

    private

    # Dropping privileges goes through doas (configured in the Dockerfile).
    # doas resets the environment to the target user's, so ours is passed
    # explicitly via env(1).
    def wrap(cmd, env, as)
      if as == :builder && root?
        pairs = env.map { |k, v| "#{k}=#{v}" }
        [["doas", "-u", @builder, "--", "env", *pairs, *cmd], {}]
      else
        [cmd, env.transform_keys(&:to_s).transform_values(&:to_s)]
      end
    end

    def spawn_options(chdir)
      chdir ? { chdir: chdir.to_s } : {}
    end

    # A copy-pasteable rendering of a command, quoted for humans.
    def display(cmd, env)
      (env.map { |k, v| "#{k}=#{quote(v.to_s)}" } + cmd.map { |c| quote(c) }).join(" ")
    end

    def quote(arg)
      return arg if arg.match?(%r{\A[\w./:=@%+,-]+\z})

      "'#{arg.gsub("'") { %q('\\'') }}'"
    end

    # Splits on both \n and \r so progress bars (curl, wget) become lines.
    def each_line(io)
      buffer = +""
      loop do
        buffer << io.readpartial(65_536).force_encoding(Encoding::UTF_8).scrub
        while (match = buffer.match(/\r\n|\r|\n/))
          # A trailing lone \r may be the first half of a \r\n still in flight.
          break if match[0] == "\r" && match.end(0) == buffer.length

          yield buffer.slice!(0, match.end(0)).chomp
        end
      end
    rescue EOFError
      yield buffer unless buffer.empty?
    end
  end
end
