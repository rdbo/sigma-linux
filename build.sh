#!/bin/sh

set -e

if [ "$(id -u)" != "0" ]; then
	echo "[!] Run as root"
	exit 1
fi

echo "[*] Sigma Linux Builder"

echo "[*] Running config..."
. ./src/config.sh

# Fetch or update kernel
echo "[*] Fetching/updating kernel..."
if [ ! -d "$KERNEL_DIR" ]; then
	./src/fetch_kernel.sh
else
	./src/update_kernel.sh
fi

# Fetch or update busybox
echo "[*] Fetching/updating busybox..."
if [ ! -d "$BUSYBOX_DIR" ]; then
	./src/fetch_busybox.sh
else
	./src/update_busybox.sh
fi

# Build kernel
echo "[*] Building kernel..."
./src/build_kernel.sh

# Build busybox
echo "[*] Building busybox..."
./src/build_busybox.sh

# Make initramfs
echo "[*] Making initramfs..."
./src/make_initramfs.sh

# Build ISO
echo "[*] Building ISO..."
./src/build_iso.sh

echo "[*] Build finished successfully"
