#!/bin/sh

set -e

mkdir -p "$ISO_DIR"
mkdir -p "$ISO_DIR/boot"
mkdir -p "$ISO_DIR/boot/grub"

# Copy vmlinuz to ISO dir
cp "$KERNEL_DIR/arch/$TARGET_ARCH/boot/bzImage" "$ISO_DIR/boot/vmlinuz"

# NOTE: The modules won't be installed because the kernel is configured
#       so that the required modules are builtin
# Install kernel modules to ISO dir
# cd "$KERNEL_DIR"
# make INSTALL_MOD_PATH="$ISO_DIR" modules_install

# Copy kernel config to ISO dir
cp "$KERNEL_DIR/.config" "$ISO_DIR/boot/config"

# Copy initramfs to ISO dir
cp "$INITRAMFS_PATH" "$ISO_DIR/boot/initramfs"

# Copy squashfs to ISO dir
cp "$SQUASHFS_PATH" "$ISO_DIR/rootfs.squashfs"

# Copy GRUB wallpaper to /boot/grub
cp "$SRC_DIR/grub_wallpaper.png" "$ISO_DIR/boot/grub/wallpaper.png"

# Copy GRUB config to ISO dir
# NOTE: The vt.* kernel parameters are used for changing the virtual terminal (VT) theme
# Sane defaults:
# red: 1,222,57,255,0,118,44,204,128,255,0,255,0,255,0,255
# green: 1,56,181,199,111,38,181,204,128,0,255,255,0,0,255,255
# blue: 1,43,74,6,184,113,233,204,128,0,0,0,255,255,255,255
vt_default_red="16,222,57,255,0,118,44,204,128,255,0,255,0,255,0,255"
vt_default_green="26,56,181,199,111,38,181,204,128,0,255,255,0,0,255,255"
vt_default_blue="32,43,74,6,184,113,233,204,128,0,0,0,255,255,255,255"
cat <<- EOF > "$ISO_DIR/boot/grub/grub.cfg"
set timeout=5

insmod all_video
loadfont /boot/grub/fonts/unicode.pf2

insmod gfxterm
set gfxmode=640x480
terminal_output gfxterm

insmod png
background_image /boot/grub/wallpaper.png

menuentry "$SYSNAME" {
	echo "Loading vmlinuz..."
	linux /boot/vmlinuz vt.color=0x03 vt.default_red=$vt_default_red vt.default_grn=$vt_default_green vt.default_blu=$vt_default_blue
	echo "Loading initrd..."
	initrd /boot/initramfs
}
EOF

# Build ISO
grub-mkrescue "$ISO_DIR" -o "$ISO_PATH" -volid "$ISO_VOLID"
