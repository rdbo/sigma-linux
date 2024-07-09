#!/bin/sh

set -e

kernel_version="$(ls "$SQUASHFS_DIR/lib/modules" | head -1)"
echo "[*] Generating initramfs with dracut..."
dracut \
	-o "dash mksh caps biosdevname" \
	-c "$DRACUT_CONFIG" \
	-r "$SQUASHFS_DIR" \
	--kver "$kernel_version" \
	--kmoddir "$SQUASHFS_DIR/lib/modules/$kernel_version" \
	--force "$INITRAMFS_PATH"
