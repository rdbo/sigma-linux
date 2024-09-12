#!/bin/sh

set -e

dracut -r "$SQUASHFS_DIR" "$INITRAMFS_PATH"
