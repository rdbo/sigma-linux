# frozen_string_literal: true

module Sigma
  # A pipeline stage: a named list of steps, the inputs that decide whether it
  # is up to date, and the outputs it leaves behind.
  #
  # A stage is fresh when its stamp matches its current inputs, it was built
  # against the current output of the stage before it, and its outputs exist.
  class Stage
    class << self
      attr_reader :stage_name, :description, :steps

      def stage(name, description, steps: [])
        @stage_name = name
        @description = description
        @steps = steps
      end
    end

    attr_reader :context

    def initialize(context, pipeline)
      @context = context
      @pipeline = pipeline
    end

    def name = self.class.stage_name
    def description = self.class.description
    def steps = self.class.steps
    def config = context.config
    def paths = context.paths
    def ui = context.ui
    def shell = context.shell
    def state = @pipeline.state

    # -- freshness ------------------------------------------------------------

    def key = "stage/#{name}"
    def stamp = state.read(key)
    def upstream = @pipeline.before(self)

    # What downstream stages record to notice that this one ran again.
    def token = stamp&.fetch("token", nil)

    # Fingerprint of everything this stage reads, besides the stage before it.
    def inputs = raise(NotImplementedError)

    # Paths that must exist for the stage to count as built.
    def outputs = []

    # [:fresh | :stale | :missing, reason]
    def status
      current = stamp
      return [:missing, "never built"] unless current
      return [:stale, "output missing"] unless outputs.all? { |p| File.exist?(p) }
      return [:stale, "inputs changed"] if current["inputs"] != inputs
      return [:stale, "#{upstream.name} changed"] if upstream && current["upstream"] != upstream.token

      [:fresh, nil]
    end

    def fresh? = status.first == :fresh

    # -- running ----------------------------------------------------------------

    # Raises unless +items+ name things this stage can do.
    def validate(items)
      unknown = items - steps.map(&:to_s)
      return if unknown.empty?

      raise Error.new("#{name} has no step `#{unknown.first}`", hint: "Steps: #{steps.join(", ")}")
    end

    # Short description of what +items+ will do, for --plan.
    def plan(items) = (items || steps).join(", ")

    # Raises if what this stage consumes isn't there.
    def check_prerequisites; end

    # Runs the selected steps (all by default) and returns a summary line.
    def run(items, force: false) # rubocop:disable Lint/UnusedMethodArgument -- used by overrides
      selected = (items || steps.map(&:to_s)).map(&:to_sym)
      prior = stamp
      started = ui.clock
      around_steps(selected) do
        selected.each { |step| context.task(name, step, label: step_label(step)) { |t| send("step_#{step}", t) } }
      end
      record(items.nil?, prior, ui.clock - started)
      summary
    end

    # Deletes what the stage produced, and its stamp.
    def clean(_items = nil)
      outputs.each { |path| Mounts.remove_tree(path) }
      state.delete(key)
    end

    protected

    def around_steps(_selected) = yield
    def step_label(step) = step.to_s
    def summary = nil

    # A whole run records the inputs it was built from. A partial run leaves
    # the recorded inputs alone (the stage as a whole wasn't redone) but still
    # takes a new token, so downstream stages see that something changed.
    def record(whole, prior, duration)
      if whole
        state.write(key, "inputs" => inputs, "upstream" => upstream&.token, "duration" => duration)
      elsif prior
        state.write(key, prior.merge("token" => nil, "duration" => duration))
      end
    end

    def relative(path) = path.to_s.delete_prefix("#{paths.root}/")

    def require_output(path, from)
      return if File.exist?(path)

      raise Error.new("#{relative(path)} is missing", hint: "Build it first: `sigma build #{from}`.")
    end
  end
end
