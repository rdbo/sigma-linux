# frozen_string_literal: true

require_relative "test_helper"

class PackagesTest < Minitest::Test
  def local
    @local ||= Sigma::LocalPackages.new(File.join(Sigma::ROOT, "packages"),
                                        shell: Sigma::Shell.new(builder: "build"), carch: "x86_64")
  end

  def test_reads_real_apkbuilds
    kernel = local["linux-sigma"]
    assert_equal %w[linux-sigma linux-sigma-dev linux-sigma-doc], kernel.outputs
    assert_includes kernel.local_sources, "sigma.x86_64.config"
    assert_equal ["initramfs-generator"], kernel.depends
  end

  def test_resolves_subpackages_and_provides
    assert_equal "linux-sigma", local["linux-sigma-dev"].name
    assert_equal "initrdbo", local["initramfs-generator"].name
    assert_nil local["busybox"]
  end

  def test_profile_needs_only_what_it_names
    needed = local.for_profile(Sigma::Profile.new(File.join(Sigma::ROOT, "profiles"), "standard").packages).map(&:name)
    assert_equal 11, needed.size
    %w[sigma-dwl sigma-st simplex-chat].each { |unused| refute_includes needed, unused }
  end

  def test_build_order_puts_dependencies_first
    order = local.for_profile(%w[linux-sigma]).map(&:name)
    assert_equal %w[initrdbo linux-sigma], order, "linux-sigma depends on initramfs-generator (initrdbo)"
  end

  def test_ccache_delta_counts_one_builds_hits
    stage = Sigma::Stages::Packages.allocate
    before = { "direct_cache_hit" => 614, "preprocessed_cache_hit" => 3, "cache_miss" => 22_172 }
    after = { "direct_cache_hit" => 1085, "preprocessed_cache_hit" => 139, "cache_miss" => 40_147 }
    assert_equal [607, 18_582], stage.send(:ccache_delta, before, after)
    assert_nil stage.send(:ccache_delta, nil, after)
  end

  def test_unknown_package
    assert_raises(Sigma::Error) { local.for_names(%w[nope]) }
  end
end
