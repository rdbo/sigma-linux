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

# Build kernel
echo "[*] Building kernel..."
./src/build_kernel.sh

echo "[*] Build finished successfully"
