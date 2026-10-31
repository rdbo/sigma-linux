# frozen_string_literal: true

require "fileutils"

module Sigma
  # The container runs as root, but the checkout belongs to someone on the
  # host. After a run, what root wrote that the host user deals with (the ISO,
  # logs, stamps, keys, downloads) is handed back to them, so out/ and friends
  # never end up root-owned. The root filesystem itself must stay root's.
  class Ownership
    def initialize(context)
      @context = context
    end

    def restore
      uid = Integer(ENV.fetch("SIGMA_HOST_UID", ""), exception: false)
      gid = Integer(ENV.fetch("SIGMA_HOST_GID", ""), exception: false)
      return unless uid && @context.shell.root?

      paths = @context.paths
      [paths.out, paths.logs, paths.state, paths.keys, paths.apk_cache].each do |path|
        FileUtils.chown_R(uid, gid, path) if File.exist?(path)
      end
      File.chown(uid, gid, paths.cache) if File.exist?(paths.cache)
    end
  end
end
