#!/bin/sh

set -e

kernel_version="$(ls "$SQUASHFS_DIR/lib/modules" | head -n 1)"
dracut -c "$SRC_DIR/dracut.conf" --force --kver "$kernel_version" -r "$SQUASHFS_DIR" "$INITRAMFS_PATH"
