#!/bin/sh

set -e

. ./src/config.sh

# Fetch or update kernel
if [ ! -d "$KERNEL_DIR" ]; then
	./src/fetch_kernel.sh
else
	./src/update_kernel.sh
fi

# Build kernel
./src/build_kernel.sh
