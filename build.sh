#!/bin/sh

set -e

echo "[*] Sigma Linux Builder"

echo "[*] Running config..."
. ./src/config.sh

# Fetch or update kernel
echo "[*] Fetching/updating kernel..."
if [ ! -d "$KERNEL_DIR" ]; then
	./src/fetch_kernel.sh
else
	./src/update_kernel.sh
fi

# Fetch or update busybox
echo "[*] Fetching/updating busybox..."
if [ ! -d "$BUSYBOX_DIR" ]; then
	./src/fetch_busybox.sh
else
	./src/update_busybox.sh
fi

# Build kernel
echo "[*] Building kernel..."
./src/build_kernel.sh

# Build busybox
echo "[*] Building busybox..."
./src/build_busybox.sh

echo "[*] Build finished successfully"
