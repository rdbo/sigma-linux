#!/bin/sh

set -e

mkdir -p "$INITRD_DIR"
cd "$INITRD_DIR"

# Install initramfs helper packages
if [ ! -d "$INITRD_DIR/etc/apk" ]; then
	apk add --initdb -p "$INITRD_DIR"

	apk add \
		-p "$INITRD_DIR" \
		--allow-untrusted \
		--no-cache \
		--repositories-file="$REPOS_FILE" \
		linux-edge busybox cryptsetup eudev lsblk kmod bash file
else
	echo "[*] Skipped installing APKs in initramfs, '/etc/apk' exists"
fi

# Compress files into initramfs
find . | cpio -R root:root -H newc -o | gzip > "$INITRAMFS_PATH"

cd "$ROOT_DIR"
