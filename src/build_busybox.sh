#!/bin/sh

set -e

cp "$SRC_DIR/busybox_config" "$BUSYBOX_DIR/.config"
cd "$BUSYBOX_DIR"
make -j "$MAX_THREADS" busybox
cd "$ROOT_DIR"
