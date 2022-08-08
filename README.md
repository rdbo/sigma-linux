# Sigma Linux
## A Linux distribuition based on Alpine Linux

![screenshot-desktop](screenshots/screenshot-desktop.png)
![screenshot-apps](screenshots/screenshot-apps.png)

# License
All the files in this repository follow the license in the file `LICENSE`, unless explicitly said otherwise (e.g through a CREDITS or a LICENSE file)

# Software
- Display Manager: LightDM
- Window Manager: BSPWM
- Compositor: Picom
- Status Bar: Polybar
- Terminal: Alacritty
- Browser: Firefox

# Building
Use Alpine Linux.  
Run the following commands as root.
Install the required packages:
```
apk update
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools sudo mtools dosfstools grub-efi
```

Create a build user:
```
adduser build -G abuild
```

Give administrative access to the build user:
```
echo "%abuild ALL=(ALL) ALL" > /etc/sudoers.d/abuild
```

Change to the build user:
```
su - build
```

Create signing keys for the build user:
```
abuild-keygen -i -a
```

Clone this repository if you haven't yet:
```
git clone --depth 1 <url>
```

Enter the repository folder and clone 'aports':
```
cd sigma-linux
git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
```

Start the build process:
```
./build.sh
```

The output ISO file will be in the 'iso' folder inside the project directory, along with a sha256 checksum.

OBS: Clearing the cache might be needed for a rebuild:
```
rm -rf cache
```
