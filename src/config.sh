#!/bin/sh

set -e

export PROFILENAME="sigma"
export SYSNAME="Sigma Linux"
export ROOT_DIR="$(dirname -- "$(readlink -f -- "$0")")"
export CACHE_DIR="$ROOT_DIR/cache"
export SRC_DIR="$ROOT_DIR/src"
export REPO_DIR="$CACHE_DIR/repo"
export APK_DIR="$SRC_DIR/apk"
export APKTEMP_DIR="$CACHE_DIR/apk"
export BUILD_USER="build" # User with abuild setup
export MAX_THREADS="11"
export TARGET_ARCH="$(uname -m)"
export KERNEL_GIT="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/"
export KERNEL_BRANCH="v6.10.10"
export KERNEL_DIR="$CACHE_DIR/linux"
export INITRD_DIR="$CACHE_DIR/initrd"
export INITRAMFS_PATH="$CACHE_DIR/initramfs"
export INITRAMFS_MODS="$SRC_DIR/initramfs_modules"
export INITRAMFS_MODPROBE="iso9660,squashfs,overlay,ext4,cdrom,loop"
export REPOS_FILE="$SRC_DIR/repositories"
export SQUASHFS_DIR="$CACHE_DIR/squashfs"
export SQUASHFS_PATH="$CACHE_DIR/rootfs.squashfs"
export SQUASHFS_COMP="xz"
export SQUASHFS_EXTRA_ARGS=""
export ISO_DIR="$CACHE_DIR/iso"
export ISO_PATH="$CACHE_DIR/$PROFILENAME-linux.iso"
export ISO_VOLID="sigma-linux-cdrom"

# Allow overriding the default variables through a
# separate script, which is added to gitignore
if [ -f "$SRC_DIR/config.override.sh" ]; then
	echo "[*] Loaded config overrides"
	. "$SRC_DIR/config.override.sh"
fi

echo "Config:"
echo " - PROFILENAME: $PROFILENAME"
echo " - SYSNAME: $SYSNAME"
echo " - ROOT_DIR: $ROOT_DIR"
echo " - CACHE_DIR: $CACHE_DIR"
echo " - SRC_DIR: $SRC_DIR"
echo " - REPO_DIR: $REPO_DIR"
echo " - APK_DIR: $APK_DIR"
echo " - APKTEMP_DIR: $APKTEMP_DIR"
echo " - BUILD_USER: $BUILD_USER"
echo " - MAX_THREADS: $MAX_THREADS"
echo " - TARGET_ARCH: $TARGET_ARCH"
echo " - KERNEL_GIT: $KERNEL_GIT"
echo " - KERNEL_BRANCH: $KERNEL_BRANCH"
echo " - KERNEL_DIR: $KERNEL_DIR"
echo " - INITRD_DIR: $INITRD_DIR"
echo " - INITRAMFS_PATH: $INITRAMFS_PATH"
echo " - INITRAMFS_MODS: $INITRAMFS_MODS"
echo " - INITRAMFS_MODPROBE: $INITRAMFS_MODPROBE"
echo " - REPOS_FILE: $REPOS_FILE"
echo " - SQUASHFS_DIR: $SQUASHFS_DIR"
echo " - SQUASHFS_PATH: $SQUASHFS_PATH"
echo " - SQUASHFS_COMP: $SQUASHFS_COMP"
echo " - SQUASHFS_EXTRA_ARGS: $SQUASHFS_EXTRA_ARGS"
echo " - ISO_DIR: $ISO_DIR"
echo " - ISO_PATH: $ISO_PATH"
echo " - ISO_VOLID: $ISO_VOLID"

mkdir -p "$CACHE_DIR"
chmod 777 "$CACHE_DIR" # Allow read-write for build user
