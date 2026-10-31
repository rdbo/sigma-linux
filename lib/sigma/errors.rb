# frozen_string_literal: true

module Sigma
  # An error meant for the user: rendered as a box with an optional hint,
  # never as a Ruby backtrace.
  class Error < StandardError
    attr_reader :hint

    def initialize(message, hint: nil)
      super(message)
      @hint = hint
    end
  end

  # A command exited non-zero. Carries what is needed to explain it: the last
  # lines it printed and where the full log is.
  class CommandFailed < Error
    attr_reader :command, :status, :log_path, :tail

    # The lines worth showing: abuild prints cleanup after its ">>> ERROR"
    # line, so when there is one, the window ends there instead.
    def excerpt(count = 15)
      marker = tail.rindex { |line| line.start_with?(">>> ERROR") }
      marker ? tail[[marker - count + 1, 0].max..marker] : tail.last(count)
    end

    def initialize(command, status, log_path: nil, tail: [], hint: nil)
      @command = command
      @status = status
      @log_path = log_path
      @tail = tail
      super("`#{command}` exited with status #{status}", hint: hint)
    end
  end
end
