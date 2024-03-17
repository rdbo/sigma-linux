#!/bin/sh

export PROFILENAME="sigma"
export ROOT_DIR="$(dirname -- "$(readlink -f -- "$0")")"
export CACHE_DIR="$ROOT_DIR/cache"
export SRC_DIR="$ROOT_DIR/src"
export KERNEL_GIT="https://github.com/torvalds/linux"
export KERNEL_BRANCH="v6.8"
export KERNEL_DIR="$CACHE_DIR/linux"

mkdir -p "$CACHE_DIR"
