# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"

module Sigma
  # Stamps recording what was built from what, as small JSON files under
  # cache/state/. Keys look like "stage/rootfs" or "package/linux-sigma".
  #
  # Every stamp carries a `token` that changes whenever its producer runs;
  # downstream stages record the token they were built against, which is how
  # "rootfs ran again" makes squashfs stale even if rootfs's inputs didn't change.
  class State
    def initialize(dir)
      @dir = dir
    end

    def read(key)
      path = path_for(key)
      File.exist?(path) ? JSON.parse(File.read(path)) : nil
    rescue JSON::ParserError
      nil
    end

    def write(key, data)
      path = path_for(key)
      FileUtils.mkdir_p(File.dirname(path))
      stamp = data.merge("token" => data["token"] || SecureRandom.hex(8), "finished_at" => Time.now.to_i)
      File.write("#{path}.tmp", JSON.pretty_generate(stamp))
      File.rename("#{path}.tmp", path)
      stamp
    end

    def delete(key)
      FileUtils.rm_f(path_for(key))
    end

    def keys(prefix)
      Dir[File.join(@dir, prefix, "*.json")].map { |f| "#{prefix}/#{File.basename(f, ".json")}" }
    end

    private

    def path_for(key) = File.join(@dir, "#{key}.json")
  end
end
