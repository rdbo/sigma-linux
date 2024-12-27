#!/bin/sh

# linux-sigma
if [ ! -d "$APKTEMP_DIR/linux-sigma" ]; then
	mkdir -p "$APKTEMP_DIR/linux-sigma"
	cp -r "$APK_DIR/linux-sigma/." "$APKTEMP_DIR/linux-sigma/."
	cd "$APKTEMP_DIR/linux-sigma"
	abuild checksum
fi

# initrdbo
if [ ! -d "$APKTEMP_DIR/initrdbo" ]; then
	mkdir -p "$APKTEMP_DIR/initrdbo"
	cp -r "$APK_DIR/initrdbo/." "$APKTEMP_DIR/initrdbo/."
	cd "$APKTEMP_DIR/initrdbo"
	abuild checksum
fi

# sigma-conf
if [ ! -d "$APKTEMP_DIR/sigma-conf" ]; then
	mkdir -p "$APKTEMP_DIR/sigma-conf/"
	cp "$APK_DIR/sigma-conf/APKBUILD" "$APKTEMP_DIR/sigma-conf/"
	cd "$APK_DIR/sigma-conf"
	tar -czf "$APKTEMP_DIR/sigma-conf/rootfs.tar.gz" rootfs
	cd "$APKTEMP_DIR/sigma-conf"
	abuild checksum
fi

# sigma-firacode-nerd
if [ ! -d "$APKTEMP_DIR/sigma-firacode-nerd" ]; then
	cp -r "$APK_DIR/sigma-firacode-nerd/" "$APKTEMP_DIR/"
fi

# sigma-material-symbols
if [ ! -d "$APKTEMP_DIR/sigma-material-symbols" ]; then
	cp -r "$APK_DIR/sigma-material-symbols/" "$APKTEMP_DIR/"
fi

# sigma-sent
if [ ! -d "$APKTEMP_DIR/sigma-sent" ]; then
	mkdir -p "$APKTEMP_DIR/sigma-sent/"
	cp "$APK_DIR/sigma-sent/APKBUILD" "$APKTEMP_DIR/sigma-sent/"
	cd "$APK_DIR/sigma-sent"
	tar -czf "$APKTEMP_DIR/sigma-sent/sent.tar.gz" sent
	cd "$APKTEMP_DIR/sigma-sent"
	abuild checksum
fi

# sigma-st
if [ ! -d "$APKTEMP_DIR/sigma-st" ]; then
	cp -r "$APK_DIR/sigma-st/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-st"
	abuild checksum
fi

# sigma-vt323
if [ ! -d "$APKTEMP_DIR/sigma-vt323" ]; then
	cp -r "$APK_DIR/sigma-vt323/" "$APKTEMP_DIR/"
fi

# sigma-wvkbd
if [ ! -d "$APKTEMP_DIR/sigma-wvkbd" ]; then
	cp -r "$APK_DIR/sigma-wvkbd/" "$APKTEMP_DIR/"
	cd "$APKTEMP_DIR/sigma-wvkbd"
	abuild checksum
fi

# sigma-flat-remix-gtk
if [ ! -d "$APKTEMP_DIR/sigma-flat-remix-gtk" ]; then
	cp -r "$APK_DIR/sigma-flat-remix-gtk/" "$APKTEMP_DIR/"
fi

# simplex-chat
if [ ! -d "$APKTEMP_DIR/simplex-chat" ]; then
	cp -r "$APK_DIR/simplex-chat/" "$APKTEMP_DIR/"
fi
