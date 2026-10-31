# frozen_string_literal: true

require_relative "test_helper"

# Freshness: inputs, outputs and the upstream token.
class StageTest < Minitest::Test
  class Upstream < Sigma::Stage
    stage "up", "upstream", steps: %i[make]
    attr_accessor :input

    def inputs = input
    def step_make(_task) = nil
  end

  class Downstream < Sigma::Stage
    stage "down", "downstream", steps: %i[one two]
    attr_accessor :input, :output

    def inputs = input
    def outputs = [output]
    def step_one(_task) = File.write(output, "x")
    def step_two(_task) = nil
  end

  FakePipeline = Struct.new(:state, :stages) do
    def before(stage) = stage.is_a?(Downstream) ? stages.first : nil
  end

  def setup
    @dir = Dir.mktmpdir
    cfg = config("paths.cache" => File.join(@dir, "cache"))
    @context = Sigma::Context.new(cfg, quiet_ui)
    pipeline = FakePipeline.new(Sigma::State.new(File.join(@dir, "state")), [])
    @up = Upstream.new(@context, pipeline).tap { |s| s.input = "u1" }
    @down = Downstream.new(@context, pipeline).tap { |s| s.input = "d1"; s.output = File.join(@dir, "out") }
    pipeline.stages.replace([@up, @down])
  end

  def teardown = FileUtils.rm_rf(@dir)

  def test_lifecycle
    assert_equal :missing, @down.status.first
    @up.run(nil)
    @down.run(nil)
    assert @down.fresh?

    @down.input = "d2"
    assert_equal [:stale, "inputs changed"], @down.status
    @down.run(nil)
    assert @down.fresh?

    @up.run(nil) # upstream ran again: same inputs, new token
    assert_equal [:stale, "up changed"], @down.status
    @down.run(nil)

    File.delete(@down.output)
    assert_equal [:stale, "output missing"], @down.status
  end

  def test_partial_run_keeps_inputs_but_changes_token
    @up.run(nil)
    @down.run(nil)
    token = @down.token
    @down.run(["two"])
    refute_equal token, @down.token, "downstream of a partial run must notice"
    assert @down.fresh?, "a partial run doesn't invalidate the stage itself"
  end

  def test_partial_run_without_prior_whole_run_records_nothing
    @down.run(["two"])
    assert_nil @down.stamp
  end
end
