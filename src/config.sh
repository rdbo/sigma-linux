#!/bin/sh

set -e

export PROFILENAME="sigma"
export SYSNAME="Sigma Linux"
export ROOT_DIR="$(dirname -- "$(readlink -f -- "$0")")"
export CACHE_DIR="$ROOT_DIR/cache"
export SRC_DIR="$ROOT_DIR/src"
export MAX_THREADS="11"
export TARGET_ARCH="$(uname -m)"
export KERNEL_GIT="https://github.com/torvalds/linux"
export KERNEL_BRANCH="v6.8"
export KERNEL_DIR="$CACHE_DIR/linux"
export BUSYBOX_GIT="https://git.busybox.net/busybox"
export BUSYBOX_BRANCH="1_36_1"
export BUSYBOX_DIR="$CACHE_DIR/busybox"
export INITRD_DIR="$CACHE_DIR/initrd"
export INITRAMFS_PATH="$CACHE_DIR/initramfs"
export ISO_DIR="$CACHE_DIR/iso"

echo "Config:"
echo " - PROFILENAME: $PROFILENAME"
echo " - SYSNAME: $SYSNAME"
echo " - ROOT_DIR: $ROOT_DIR"
echo " - CACHE_DIR: $CACHE_DIR"
echo " - SRC_DIR: $SRC_DIR"
echo " - KERNEL_GIT: $KERNEL_GIT"
echo " - KERNEL_BRANCH: $KERNEL_BRANCH"
echo " - KERNEL_DIR: $KERNEL_DIR"

mkdir -p "$CACHE_DIR"
