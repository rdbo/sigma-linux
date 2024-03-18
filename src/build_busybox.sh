#!/bin/sh

cd "$BUSYBOX_DIR"
make defconfig
make -j "$MAX_THREADS" busybox
cd "$ROOT_DIR"
