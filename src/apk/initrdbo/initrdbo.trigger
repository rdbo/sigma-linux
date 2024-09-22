#!/bin/sh

for flavor in "$@"; do
	release="/usr/share/kernel/$flavor/kernel.release"
	initramfs_path="/boot/initramfs-$flavor"
	if [ -f "$initramfs_path" ]; then
		cp "$initramfs_path" "/boot/initramfs-$flavor.old"
		rm "$initramfs_path"
	fi

	initrdbo -k "$release" "$initramfs_path"
done
