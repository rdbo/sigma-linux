#!/bin/sh

set -e

mkdir -p "$ISO_DIR"

# Copy vmlinuz to ISO dir
cp "$KERNEL_DIR/arch/$TARGET_ARCH/boot/bzImage" "$ISO_DIR/vmlinuz"

# NOTE: The modules won't be installed because the kernel is configured
#       so that the required modules are builtin
# Install kernel modules to ISO dir
# cd "$KERNEL_DIR"
# make INSTALL_MOD_PATH="$ISO_DIR" modules_install

# Copy kernel config to ISO dir
cp "$KERNEL_DIR/.config" "$ISO_DIR/config"

# Copy initramfs to ISO dir
cp "$INITRAMFS_PATH" "$ISO_DIR"

# Copy GRUB config to ISO dir
mkdir -p "$ISO_DIR/boot/grub"
cat <<- EOF > "$ISO_DIR/boot/grub/grub.cfg"
menuentry "$SYSNAME" {
	echo "Loading vmlinuz..."
	linux /vmlinuz
	echo "Loading initrd..."
	initrd /initramfs
}
EOF

# Build ISO
grub-mkrescue "$ISO_DIR" -o "$ISO_PATH" -volid "$ISO_VOLID"
