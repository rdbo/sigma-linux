# frozen_string_literal: true

require_relative "test_helper"

class ShellTest < Minitest::Test
  def shell = Sigma::Shell.new(builder: "build")
  def task = Sigma::UI::Task.new(quiet_ui, "test", nil)

  def failure(script)
    shell.run(task, "sh", "-c", script)
    flunk "expected the command to fail"
  rescue Sigma::CommandFailed => e
    e
  end

  # Parallel make: the real error, then a hundred lines of other jobs.
  def test_excerpt_is_the_first_error_with_its_include_chain
    error = failure(<<~SH)
      echo "  CC      a.o"
      echo "In file included from x.h:1,"
      echo "                 from y.c:2:"
      echo "x.h:3:4: error: unknown type name 'foo'"
      echo "    3 | foo bar;"
      i=0; while [ $i -lt 100 ]; do echo "  CC      noise$i.o"; i=$((i+1)); done
      echo "y.c:9:1: error: second"
      echo ">>> ERROR: pkg: build failed"
      exit 1
    SH
    excerpt = error.excerpt
    assert_equal "In file included from x.h:1,", excerpt.first
    assert_equal "x.h:3:4: error: unknown type name 'foo'", excerpt[2]
    assert_equal Sigma::Shell::FIRST_ERROR_LINES, excerpt.size
    refute_includes excerpt, "  CC      a.o"
  end

  def test_without_an_error_line_the_excerpt_ends_at_abuilds_marker
    error = failure(%(echo one; echo ">>> ERROR: pkg: build failed"; echo cleanup; exit 1))
    assert_nil error.first_error
    assert_equal ["one", ">>> ERROR: pkg: build failed"], error.excerpt
  end

  def test_error_lines_in_a_successful_command_are_ignored
    assert_nil shell.run(task, "sh", "-c", "echo 'x.c:1:1: error: harmless'")
  end

  def test_error_line_pattern
    ["swab.h:48:15: error: unknown type name", "error[E0425]: cannot find value",
     "ERROR: modpost: missing symbol", "configure: error: no compiler"].each do |line|
      assert_match Sigma::Shell::ERROR_LINE, line
    end
    ["  CC      drivers/base/error.o", "cc1: all warnings being treated as errors",
     ">>> ERROR: pkg: build failed"].each do |line|
      refute_match Sigma::Shell::ERROR_LINE, line
    end
  end
end
