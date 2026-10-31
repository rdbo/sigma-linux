# frozen_string_literal: true

require_relative "test_helper"

class SelectionTest < Minitest::Test
  STAGES = %w[packages rootfs squashfs iso].freeze

  def parse(*args) = Sigma::Selection.parse(args, STAGES)
  def pairs(*args) = parse(*args).entries.map { |e| [e.stage, e.items] }

  def test_nothing_selects_everything_incrementally
    selection = parse
    assert selection.incremental?
    assert_equal STAGES, selection.stages
  end

  def test_named_stage_is_explicit
    selection = parse("rootfs")
    refute selection.incremental?
    assert_equal [["rootfs", nil]], pairs("rootfs")
  end

  def test_ranges
    assert_equal %w[rootfs squashfs iso], parse("rootfs..").stages
    assert_equal %w[packages rootfs squashfs], parse("..squashfs").stages
    assert_equal %w[rootfs squashfs], parse("rootfs..squashfs").stages
    assert_equal STAGES, parse("..").stages
  end

  def test_items_merge_and_whole_wins
    assert_equal [["packages", %w[linux-sigma initrdbo]]], pairs("packages:linux-sigma", "packages:initrdbo,linux-sigma")
    assert_equal [["packages", nil]], pairs("packages:linux-sigma", "packages")
    assert_equal [["packages", nil]], pairs("packages", "packages:linux-sigma")
  end

  def test_result_is_in_pipeline_order
    assert_equal [["rootfs", %w[configure]], ["iso", nil]], pairs("iso", "rootfs:configure")
  end

  def test_errors
    error = assert_raises(Sigma::Error) { parse("rotfs") }
    assert_match(/did you mean `rootfs`/, error.message)
    assert_raises(Sigma::Error) { parse("iso..rootfs") }
    assert_raises(Sigma::Error) { parse("packages:") }
    assert_raises(Sigma::Error) { parse("rootfs:configure..iso") }
  end
end
