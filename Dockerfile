FROM alpine:edge

WORKDIR /app

RUN apk update
RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools sudo mtools dosfstools grub-efi

RUN adduser -D build -G abuild
RUN echo "%abuild ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/abuild
RUN addgroup build wheel

COPY . .

RUN find . -exec chown build:abuild {} \;

USER build
RUN abuild-keygen -i -a -n
