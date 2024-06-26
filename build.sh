#!/bin/sh

set -e

if [ "$(id -u)" != "0" ]; then
	echo "[!] Run as root"
	exit 1
fi

echo "[*] Sigma Linux Builder"

echo "[*] Running config..."
. ./src/config.sh

# Skip fetch/update if .config is found
if [ ! -e "$KERNEL_DIR/.config" ]; then
	# Fetch or update kernel
	echo "[*] Fetching/updating kernel..."
	if [ ! -d "$KERNEL_DIR" ]; then
		./src/fetch_kernel.sh
	else
		./src/update_kernel.sh
	fi
else
	echo "[*] Skipped updating kernel, file '$KERNEL_DIR/.config' exists"
fi

# Fetch or update busybox
if [ ! -e "$BUSYBOX_DIR/.config" ]; then
	echo "[*] Fetching/updating busybox..."
	if [ ! -d "$BUSYBOX_DIR" ]; then
		./src/fetch_busybox.sh
	else
		./src/update_busybox.sh
	fi
else
	echo "[*] Skipped updating busybox, file '$BUSYBOX_DIR/.config' exists"
fi

# Skip building kernel if .config is found
if [ ! -e "$KERNEL_DIR/.config" ]; then
	# Patch kernel boot logo
	echo "[*] Patching boot logo..."
	./src/patch_boot_logo.sh

	# Build kernel
	echo "[*] Building kernel..."
	./src/build_kernel.sh
else
	echo "[*] Skipped building kernel, file '$KERNEL_DIR/.config' exists"
fi

# Skip building busybox if .config is found
if [ ! -e "$BUSYBOX_DIR/.config" ]; then
	# Build busybox
	echo "[*] Building busybox..."
	./src/build_busybox.sh
else
	echo "[*] Skipped building busybox, file '$BUSYBOX_DIR/.config' exists"
fi

# Build local repository
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
echo "[*] Building ISO..."
./src/build_iso.sh

echo "[*] Build finished successfully"
