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
  # lines it printed, the first error among them (see Shell::ERROR_LINE) and
  # where the full log is.
  class CommandFailed < Error
    attr_reader :command, :status, :log_path, :tail, :first_error

    # The lines worth showing: the first error when there was one. Otherwise
    # the end of the output, which for abuild means up to its ">>> ERROR"
    # line, since the cleanup it prints afterwards explains nothing.
    def excerpt(count = 15)
      return first_error.first(count) if first_error

      marker = tail.rindex { |line| line.start_with?(">>> ERROR") }
      marker ? tail[[marker - count + 1, 0].max..marker] : tail.last(count)
    end

    def initialize(command, status, log_path: nil, tail: [], first_error: nil, hint: nil)
      @command = command
      @status = status
      @log_path = log_path
      @tail = tail
      @first_error = first_error
      super("`#{command}` exited with status #{status}", hint: hint)
    end
  end
end
