FROM alpine:edge

# Setup packages
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing\n" > /etc/apk/repositories
RUN apk update
RUN apk add gcc openssl-dev elfutils-dev xorriso grub grub-efi grub-bios git gpg make musl-dev flex bison linux-headers perl mtools squashfs-tools alpine-sdk doas netpbm netpbm-extras

# Create build user
RUN adduser -D build -G abuild
RUN addgroup build wheel

# Setup abuild for build user
RUN echo "permit nopass keepenv :wheel" > /etc/doas.conf
USER build
RUN abuild-keygen -i -a -n
# Fix for building helix
RUN git config --global http.postBuffer 1048576000
RUN git config --global http.version HTTP/1.1
USER root

# river dependencies
RUN apk add libevdev-dev libxkbcommon-dev pixman-dev scdoc wayland-dev wayland-protocols wlroots-dev zig xwayland seatd
# helix dependencies
RUN apk add cargo
# suckless dependencies
RUN apk add libx11-dev libxft-dev harfbuzz-dev fontconfig-dev freetype-dev gd-dev glib-dev
# wvkbd dependencies
RUN apk add libxkbcommon-dev glib-dev wayland-dev pango-dev cairo-dev

# Fix for building helix
RUN git config --global http.postBuffer 1048576000
RUN git config --global http.version HTTP/1.1

WORKDIR /app
