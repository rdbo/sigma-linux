#!/bin/sh

set -e

pngtopnm "$SRC_DIR/bootlogo.png" | ppmquant -fs 223 | pnmtoplainpnm > "$KERNEL_DIR/drivers/video/logo/logo_linux_clut224.ppm"
