# frozen_string_literal: true

require "digest"
require "json"

module Sigma
  # Content hashes that decide whether something needs rebuilding.
  module Fingerprint
    module_function

    # Hash of arbitrary values (strings, arrays, hashes, numbers).
    def of(*parts)
      Digest::SHA256.hexdigest(JSON.generate(parts))
    end

    # Hash of a file or directory tree: relative paths, contents, symlink
    # targets and the executable bit. Timestamps are ignored on purpose, so a
    # fresh checkout of the same content is "unchanged".
    def tree(path)
      digest = Digest::SHA256.new
      return digest.hexdigest unless File.exist?(path) || File.symlink?(path)
      return Digest::SHA256.file(path).hexdigest if File.file?(path) && !File.symlink?(path)

      Dir.glob("**/*", File::FNM_DOTMATCH, base: path).sort.each do |relative|
        next if relative.end_with?("/.", "/..") || relative == "."

        full = File.join(path, relative)
        if File.symlink?(full)
          digest << "L #{relative} -> #{File.readlink(full)}\0"
        elsif File.file?(full)
          digest << "F #{relative} #{File.executable?(full) ? "x" : "-"} #{Digest::SHA256.file(full).hexdigest}\0"
        elsif File.directory?(full)
          digest << "D #{relative}\0"
        end
      end
      digest.hexdigest
    end
  end
end
