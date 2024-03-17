#!/bin/sh

cp "$SRC_DIR/kconfig" "$KERNEL_DIR/.config"
cd "$KERNEL_DIR"
yes "" | make CFLAGS="-DUTS_SYSNAME=\"Sigma Linux\"" -j 11 bzImage modules
cd "$ROOT_DIR"
