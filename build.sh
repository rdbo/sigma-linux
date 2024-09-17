#!/bin/sh

set -e

if [ "$(id -u)" != "0" ]; then
	echo "[!] Run as root"
	exit 1
fi

echo "[*] Sigma Linux Builder"

echo "[*] Running config..."
. ./src/config.sh

# Setup APKs and build local repository
echo "[*] Setting up APKs..."
doas -u "$BUILD_USER" -- ./src/setup_apks.sh

echo "[*] Building local repository..."
doas -u "$BUILD_USER" -- ./src/build_repo.sh

# Skip making squashfs if rootfs.squashfs is found
if [ ! -e "$SQUASHFS_PATH" ]; then
	# Make squashfs
	echo "[*] Making squashfs..."
	./src/make_squashfs.sh
else
	echo "[*] Skipped making squashfs, file '$SQUASHFS_PATH' exists"
fi

# Make initramfs
echo "[*] Making initramfs..."
./src/make_initramfs.sh

# Build ISO
echo "[*] Making ISO..."
./src/make_iso.sh

echo "[*] Build finished successfully"
