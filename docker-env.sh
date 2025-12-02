#!/bin/sh

set -e

echo "[*] Loading config..."
. src/config.sh >& /dev/null

set_docker_arch() {
	local osarch="$1"
	local dockerarch=""
	case "$osarch" in
		x86_64) dockerarch="linux/amd64";;
		aarch64) dockerarch="linux/aarch64";;
		*) echo "[!] Failed to start docker for cross compilation target: unknown OS arch"; exit 1;;
	esac

	export DOCKER_DEFAULT_PLATFORM="$dockerarch"
	echo "DOCKER_DEFAULT_PLATFORM=$DOCKER_DEFAULT_PLATFORM"
}

if [ "$DISTRO_TARGET_ARCH" != "$(uname -m)" ]; then
	if [ ! -e "/proc/sys/fs/binfmt_misc/qemu-$DISTRO_TARGET_ARCH" ]; then
		# Install binfmt
		echo "[*] Setting up binfmt for cross compilation..."
		doas modprobe binfmt_misc
		doas mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc/
		docker run --privileged --rm tonistiigi/binfmt --install all
	fi

	echo "[*] Setting up cross target docker..."
	set_docker_arch "$DISTRO_TARGET_ARCH"
fi

echo "[*] Building Dockerfile..."
docker build -t sigma-linux .

echo "[*] Starting Docker environment..."
docker run --privileged -v "$(pwd):/app" --workdir /app -it sigma-linux sh
