#!/bin/sh

# Boots the freshly built ISO in QEMU and waits until OpenRC reaches the last
# service of the default runlevel ("Starting local"): the kernel, initrdbo's
# live boot from the squashfs and the whole init sequence all worked.
#
# The ISO's own menu has no serial console, so its kernel and initramfs are
# booted directly, with the ISO's command line plus console=ttyS0 and the ISO
# attached as a CD-ROM, which is where initrdbo finds the squashfs.
#
# usage: sh .github/boot-test.sh   (from the checkout, after `./sigma build`)

set -eu

iso=out/sigma-linux.iso
boot=cache/boot
menu=cache/iso/boot/grub/grub.cfg
log=cache/logs/boot-test.log
marker="Starting local"
limit=${BOOT_TIMEOUT:-600}

for file in "$iso" "$boot/vmlinuz-sigma" "$boot/initramfs-sigma" "$menu"; do
	[ -r "$file" ] || { echo "boot-test: $file is missing; build the ISO first" >&2; exit 1; }
done

# The first entry's parameters, exactly as the ISO boots them.
cmdline="$(sed -n 's|^[[:space:]]*linux /boot/vmlinuz-sigma ||p' "$menu" | head -n 1)"
[ -n "$cmdline" ] || { echo "boot-test: no vmlinuz-sigma entry in $menu" >&2; exit 1; }

accel=""
[ -w /dev/kvm ] && accel="-enable-kvm -cpu host"

mkdir -p "${log%/*}"
: > "$log"
# shellcheck disable=SC2086 # $accel is a list of options
qemu-system-x86_64 $accel -m 4096 -smp 2 -display none -no-reboot \
	-cdrom "$iso" -kernel "$boot/vmlinuz-sigma" -initrd "$boot/initramfs-sigma" \
	-append "$cmdline console=ttyS0" -serial "file:$log" &
qemu=$!

fail() {
	kill "$qemu" 2>/dev/null || true
	echo "boot-test: $*" >&2
	echo "--- last lines of the serial console ($log):" >&2
	tail -n 60 "$log" >&2
	exit 1
}

echo "Booting ${iso} ($([ -n "$accel" ] && echo KVM || echo 'no KVM, slow')); waiting up to ${limit}s for \"$marker\""
waited=0
until grep -q "$marker" "$log"; do
	grep -q "Kernel panic" "$log" && fail "kernel panic"
	kill -0 "$qemu" 2>/dev/null || fail "QEMU exited before the system finished booting"
	[ "$waited" -lt "$limit" ] || fail "no \"$marker\" after ${limit}s"
	sleep 5
	waited=$((waited + 5))
done

kill "$qemu" 2>/dev/null || true
echo "Booted in about ${waited}s:"
grep -m 1 "Linux version" "$log" || true
grep -m 1 "OpenRC" "$log" || true
