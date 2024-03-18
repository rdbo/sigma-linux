FROM alpine:edge

RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing\n" > /etc/apk/repositories

RUN apk update

RUN apk add gcc openssl-dev elfutils-dev xorriso grub grub-efi grub-bios git gpg make musl-dev flex bison linux-headers perl mtools

WORKDIR /app
