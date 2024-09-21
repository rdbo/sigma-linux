#!/bin/sh

for i in "$@"; do
	release=${i##*/}
	initramfs_path="/boot/initramfs-$release"
	if [ -f "$initramfs_path" ]; then
		continue
	fi

	initrdbo -k "$release" "$initramfs_path"
done
