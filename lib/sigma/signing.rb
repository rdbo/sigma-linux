# frozen_string_literal: true

require "fileutils"
require "securerandom"

module Sigma
  # The key that signs the local repository. It lives in cache/keys/ so it
  # survives container rebuilds, which means the image can verify our packages
  # like any other instead of installing them --allow-untrusted.
  class Signing
    def initialize(context)
      @context = context
      @dir = context.paths.keys
    end

    def private_key = Dir[File.join(@dir, "*.rsa")].min
    def public_key = private_key && "#{private_key}.pub"

    # Creates the key pair on first use. apk finds a public key by the file
    # name abuild-sign embeds, so the name must stay stable once generated.
    def ensure(task)
      return private_key if private_key

      FileUtils.mkdir_p(@dir)
      @context.give_to_builder(@dir)
      key = File.join(@dir, "#{@context.config.id}-#{SecureRandom.hex(4)}.rsa")
      # Generated as the builder, who signs with it; private stays 0600.
      @context.shell.run(task, "openssl", "genrsa", "-out", key, "4096", as: :builder)
      @context.shell.run(task, "openssl", "rsa", "-in", key, "-pubout", "-out", "#{key}.pub", as: :builder)
      File.chmod(0o600, key)
      key
    end

    # Lets this machine's apk (abuild -r installing local makedepends) trust
    # the repository. Only possible, and only needed, as root in the container.
    def trust_here
      return unless @context.shell.root? && public_key

      FileUtils.mkdir_p("/etc/apk/keys")
      FileUtils.cp(public_key, "/etc/apk/keys/")
    end
  end
end
