FROM alpine:edge

# Setup packages
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing\n" > /etc/apk/repositories
RUN apk update
RUN apk add gcc openssl-dev elfutils-dev xorriso grub grub-efi grub-bios git gpg make musl-dev flex bison linux-headers perl mtools squashfs-tools alpine-sdk doas

# Create build user
RUN adduser -D build -G abuild
RUN addgroup build wheel

# Setup abuild for build user
RUN echo "permit nopass :wheel" > /etc/doas.conf
USER build
RUN abuild-keygen -i -a -n

USER root

WORKDIR /app
