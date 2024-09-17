#!/bin/sh

# NOTE: Run as the build user!

set -e

mkdir -p "$REPO_DIR" "$APKTEMP_DIR"

# Get existing APKs in repo (if any)
apklist="$(find cache/repo/ -name "*.apk" | sed 's|.*/||')"
is_apk_indexed() {
	printf "%s" "$apklist" | tr ' ' '\n' | grep "^$1-" > /dev/null
	return $?
}

# Build APKs
for apk in $(ls "$APKTEMP_DIR"); do
	echo "[*] Building ${apk}..."
	if is_apk_indexed "$apk"; then
		echo "[*] Skipped building APK '${apk}', already indexed"
		continue
	fi

	cd "$APKTEMP_DIR/$apk"
	abuild -kK -rf -P "$REPO_DIR"
done

# Return to root dir
cd "$ROOT_DIR"
