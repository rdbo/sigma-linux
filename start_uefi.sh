#!/bin/sh

qemu-system-x86_64 \
	-bios /usr/share/OVMF/OVMF.fd \
	-enable-kvm \
	-smp 4 \
	-m 2048 \
	-cdrom cache/sigma-linux.iso \
	$@
