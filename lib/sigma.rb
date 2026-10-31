# frozen_string_literal: true

# Sigma Linux build system. See `./sigma --help` and PLAN.md.
module Sigma
  ROOT = File.expand_path("..", __dir__)
end

require_relative "sigma/errors"
require_relative "sigma/ui"
require_relative "sigma/shell"
require_relative "sigma/config"
require_relative "sigma/profile"
require_relative "sigma/fingerprint"
require_relative "sigma/state"
require_relative "sigma/mounts"
require_relative "sigma/signing"
require_relative "sigma/ownership"
require_relative "sigma/apkbuild"
require_relative "sigma/local_packages"
require_relative "sigma/context"
require_relative "sigma/selection"
require_relative "sigma/stage"
require_relative "sigma/stages/packages"
require_relative "sigma/stages/rootfs"
require_relative "sigma/stages/squashfs"
require_relative "sigma/stages/iso"
require_relative "sigma/pipeline"
require_relative "sigma/docker"
require_relative "sigma/qemu"
require_relative "sigma/cli"
