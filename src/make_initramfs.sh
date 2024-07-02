#!/bin/sh

set -e

# Temporarily mount filesystems used by initramfs generator
mkdir -p "$SQUASHFS_DIR/sys"
mount --rbind /sys "$SQUASHFS_DIR/sys"

# Generate initramfs with booster
kernel_version="$(ls "$SQUASHFS_DIR/lib/modules" | head -1)"
chroot "$SQUASHFS_DIR" booster build --kernel-version="$kernel_version" /initramfs
mv "$SQUASHFS_DIR/initramfs" "$INITRAMFS_PATH"

# Unmount filesystems
umount -R "$SQUASHFS_DIR/sys"
