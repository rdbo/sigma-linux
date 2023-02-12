#!/bin/sh

# OBS: This script must be called from 'build.sh'

MIRROR="http://dl-cdn.alpinelinux.org/alpine"
CHROOT_APKS="alpine-base alpine-baselayout alpine-conf linux-lts mdev-conf openrc busybox mdev-conf kbd-bkeymaps chrony dhcpcd e2fsprogs haveged network-extras openntpd openssl openssh tzdata"
GRUB_MOD="all_video disk part_gpt part_msdos linux normal configfile search search_label efi_gop fat iso9660 cat echo ls test true help gzio multiboot2 efi_uga"
INITFS_FEATURES="ata base bootchart cdrom ext4 mmc nvme raid scsi squashfs usb virtio simpledrm"
INITFS_CMDLINE="modules=$(printf $INITFS_FEATURES | tr ' ' ',') quiet"
KERNEL_CMDLINE=""

export SOURCE_DATE_EPOCH="$(date +%s)"

if [ "$IGNORE_SIGMA_ROOTFS" != "yes" ]; then
	CHROOT_APKS="$CHROOT_APKS $PROFILENAME-rootfs"
fi

cd "$CACHEDIR"

# create directory structure
CHROOT_DIR="$(pwd)/$PROFILENAME-linux"
mkdir -p "$CHROOT_DIR"

# install required apks
apk -X "$MIRROR/latest-stable/main" -U --allow-untrusted -p "$CHROOT_DIR" --initdb add $CHROOT_APKS

# setup grub
mkdir -p "$CHROOT_DIR/boot/grub"
cat <<- EOF > "$CHROOT_DIR/boot/grub/grub.cfg"
set timeout=5

menuentry "Linux" {
	linux	/boot/vmlinuz-$KERNEL_FLAVOR $INITFS_CMDLINE $KERNEL_CMDLINE
	initrd	/boot/initramfs-$KERNEL_FLAVOR
}
EOF

# generate grub EFI image
mkdir -p "$CHROOT_DIR/efi/boot"

case "$PROFILEARCH" in
	aarch64) grub_format="arm64-efi";   grub_efi="bootaa64.efi"   ;;
	arm*)	 grub_format="arm-efi";     grub_efi="bootarm.efi"    ;;
	x86)	 grub_format="i386-efi";    grub_efi="bootia32.efi"   ;;
	x86_64)  grub_format="x86_64-efi";  grub_efi="bootx64.efi"    ;;
	riscv64) grub_format="riscv64-efi"; grub_efi="bootriscv64.efi";;
	*)	 echo "[!] Invalid arch!"; exit 1                     ;;
esac

cat <<- EOF > "$CACHEDIR/grub_early.cfg"
search --no-floppy --set=root --label "$PROFILENAME-linux"
set prefix=(\$root)/boot/grub
EOF

grub-mkimage \
	--config="$CACHEDIR/grub_early.cfg" \
	--prefix="/boot/grub" \
	--output="$CHROOT_DIR/efi/boot/$grub_efi" \
	--format="$grub_format" \
	--compression=xz \
	$GRUB_MOD

mformat -i "${CHROOT_DIR}/boot/grub/efi.img" -C -f 1440 -N 0 ::
mcopy -i "${CHROOT_DIR}/boot/grub/efi.img" -s "${CHROOT_DIR}/efi" ::
touch -md "@${SOURCE_DATE_EPOCH}" "${CHROOT_DIR}/boot/grub/efi.img"

# generate ISO
# TODO: Make EFI + BIOS
xorrisofs \
	-output "$OUTDIR/$PROFILENAME-linux.iso" \
	-full-iso9660-filenames \
	-joliet \
	-rational-rock \
	-sysid LINUX \
	-volid "$PROFILENAME-linux" \
	-efi-boot-part \
	--efi-boot-image \
	-e boot/grub/efi.img \
	-no-emul-boot \
	"$CHROOT_DIR"

# BIOS:
#	-eltorito-alt-boot \
#	-e "$CHROOT_DIR/boot/grub/efi.img" \
#	-no-emul-boot \
#	-isohybrid-gpt-basdat \
#	-follow-links \

