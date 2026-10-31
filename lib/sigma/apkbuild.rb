# frozen_string_literal: true

module Sigma
  # Metadata of one APKBUILD. Read by sourcing the file in sh, as abuild does,
  # so variables built from other variables come out right. APKBUILDs are
  # shell scripts; we never interpret them ourselves.
  class Apkbuild
    FIELDS = %w[pkgname pkgver pkgrel arch depends makedepends checkdepends subpackages provides source].freeze

    attr_reader :dir, :name, :pkgver, :pkgrel, :arch, :depends, :makedepends, :checkdepends,
                :subpackages, :provides, :sources

    def self.read(dir, shell:, carch:)
      script = <<~SH
        . ./APKBUILD || exit 1
        #{FIELDS.map { |f| %(printf '%s\\0' "$#{f}") }.join("\n")}
      SH
      env = { "CARCH" => carch, "CBUILD_ARCH" => carch, "CTARGET_ARCH" => carch,
              "startdir" => dir, "srcdir" => File.join(dir, "src"), "pkgdir" => File.join(dir, "pkg") }
      values = shell.capture("sh", "-c", script, env: env, chdir: dir).split("\0", -1)
      new(dir, FIELDS.zip(values).to_h)
    rescue CommandFailed => e
      raise Error, "#{File.basename(dir)}/APKBUILD: could not be read (#{e.tail.last || e.message})"
    end

    def initialize(dir, fields)
      @dir = dir
      @name = fields["pkgname"]
      @pkgver = fields["pkgver"]
      @pkgrel = fields["pkgrel"]
      @arch = words(fields["arch"])
      @depends = names(fields["depends"])
      @makedepends = names(fields["makedepends"])
      @checkdepends = names(fields["checkdepends"])
      @subpackages = words(fields["subpackages"]).map { |s| s.split(":").first }
      @provides = words(fields["provides"]).map { |p| p.split(/[<>=~]/).first }
      @sources = words(fields["source"])
      raise Error, "#{File.basename(dir)}/APKBUILD: pkgname/pkgver/pkgrel missing" if [@name, @pkgver, @pkgrel].any?(&:empty?)
    end

    def version = "#{pkgver}-r#{pkgrel}"

    # Every package name this APKBUILD produces.
    def outputs = [name, *subpackages]

    # Names this APKBUILD answers to when something depends on it.
    def aliases = [*outputs, *provides]

    # Local files abuild expects next to the APKBUILD (not URLs).
    def local_sources
      sources.reject { |s| s.include?("://") }.map { |s| s.split("::").last }
    end

    private

    def words(value) = value.to_s.split

    # Dependency names without version constraints; conflicts (!foo) dropped.
    def names(value)
      words(value).reject { |d| d.start_with?("!") }.map { |d| d.split(/[<>=~]/).first }
    end
  end
end
