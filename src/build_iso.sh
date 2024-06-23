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
# default_red: 0x00,0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa,0x55,0xff,0x55,0xff,0x55,0xff,0x55,0xff
# default_grn: 0x00,0x00,0xaa,0x55,0x00,0x00,0xaa,0xaa,0x55,0x55,0xff,0xff,0x55,0x55,0xff,0xff
# default_blu: 0x00,0x00,0x00,0x00,0xaa,0xaa,0xaa,0xaa,0x55,0x55,0x55,0x55,0xff,0xff,0xff,0xff
# NOTE: The VT color table is not in order!
#       From 'drivers/tty/vt/vt.c':
#       ```
#       const unsigned char color_table[] = { 0, 4, 2, 6, 1, 5, 3, 7,
#				              8,12,10,14, 9,13,11,15 };
#       ```
#       This means that color "3" will actually be mapped to the RGB indices of color "6", for
#       example.
vt_default_red=0x10,0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa,0x55,0xff,0x55,0xff,0x55,0xff,0x00,0xff
vt_default_grn=0x1a,0x00,0xaa,0x55,0x00,0x00,0xaa,0xaa,0x55,0x55,0xff,0xff,0x55,0x55,0xff,0xff
vt_default_blu=0x20,0x00,0x00,0x00,0xaa,0xaa,0xaa,0xaa,0x55,0x55,0x55,0x55,0xff,0xff,0xc8,0xff

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
	linux /boot/vmlinuz vt.color=0x0B vt.default_red=$vt_default_red vt.default_grn=$vt_default_grn vt.default_blu=$vt_default_blu sigmamodules=$INITRAMFS_MODPROBE splash
	echo "Loading initrd..."
	initrd /boot/initramfs
}
EOF

# Build ISO
grub-mkrescue "$ISO_DIR" -o "$ISO_PATH" -volid "$ISO_VOLID"
