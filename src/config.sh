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
export MAX_THREADS="$(nproc)"
export DISTRO_TARGET_ARCH="$(uname -m)"
export REPOS_FILE="$SRC_DIR/repositories"
export PKG_PROFILE="standard"
export BOOT_DIR="$CACHE_DIR/boot"
export SQUASHFS_DIR="$CACHE_DIR/squashfs"
export SQUASHFS_PATH="$CACHE_DIR/rootfs.squashfs"
export SQUASHFS_COMP="xz"
export SQUASHFS_EXTRA_ARGS=""
export FIRMWARE_DIR="$CACHE_DIR/firmware"
export ISO_DIR="$CACHE_DIR/iso"
export ISO_PATH="$CACHE_DIR/$PROFILENAME-linux.iso"
export ISO_VOLID="sigma-linux-cdrom"

# Allow overriding the default variables through a
# separate script, which is added to gitignore
if [ -f "$SRC_DIR/config.override.sh" ]; then
	. "$SRC_DIR/config.override.sh"
	echo "[*] Loaded config overrides"
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
echo " - DISTRO_TARGET_ARCH: $DISTRO_TARGET_ARCH"
echo " - REPOS_FILE: $REPOS_FILE"
echo " - PKG_PROFILE: $PKG_PROFILE"
echo " - SQUASHFS_DIR: $SQUASHFS_DIR"
echo " - SQUASHFS_PATH: $SQUASHFS_PATH"
echo " - SQUASHFS_COMP: $SQUASHFS_COMP"
echo " - SQUASHFS_EXTRA_ARGS: $SQUASHFS_EXTRA_ARGS"
echo " - FIRMWARE_DIR: $FIRMWARE_DIR"
echo " - ISO_DIR: $ISO_DIR"
echo " - ISO_PATH: $ISO_PATH"
echo " - ISO_VOLID: $ISO_VOLID"
