FROM alpine:edge

WORKDIR /app

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk update
RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso squashfs-tools sudo mtools dosfstools grub-efi grub-bios

RUN adduser -D build -G abuild
RUN echo "%abuild ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/abuild
RUN addgroup build wheel

RUN chown -R build:abuild /app
USER build
RUN abuild-keygen -i -a -n

RUN mkdir -p cache out
RUN chown build:abuild cache out
COPY --chown=build:abuild . .
