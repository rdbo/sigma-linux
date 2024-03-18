#!/bin/sh

set -e

mkdir -p "$ISO_DIR"

# Copy vmlinuz to ISO dir
cp "$KERNEL_DIR/linux/arch/$TARGET_ARCH/boot/bzImage" "$ISO_DIR/vmlinuz"

# Install kernel modules to ISO dir
cd "$KERNEL_DIR"
make INSTALL_MOD_PATH="$ISO_DIR" modules_install
