# Sigma Linux build environment.
#
# Nothing is copied in: `./sigma` mounts the checkout at /app and runs itself
# inside, and everything worth keeping (downloads, ccache, signing key, the
# local repository) lives in ./cache on the host, so this image stays a pure
# toolbox that is cheap to rebuild.
FROM alpine:edge

RUN printf '%s\n' \
        https://dl-cdn.alpinelinux.org/alpine/edge/main \
        https://dl-cdn.alpinelinux.org/alpine/edge/community \
        https://dl-cdn.alpinelinux.org/alpine/edge/testing \
        > /etc/apk/repositories

# Package builds pull their own makedepends (abuild -r) from the APKBUILDs,
# so only the tools around them are listed here.
RUN apk add --no-cache \
        ruby \
        alpine-sdk ccache doas openssl \
        coreutils tar shadow umount \
        squashfs-tools xorriso mtools grub grub-bios grub-efi

# The unprivileged user abuild runs as. Matching the host user's UID keeps
# files it writes into ./cache owned by that user on the host.
ARG BUILD_UID=1000
RUN adduser -D -u "$BUILD_UID" -G abuild build \
    && addgroup build wheel \
    && printf '%s\n' 'permit nopass root as build' 'permit nopass :wheel' > /etc/doas.conf

ENV SIGMA_CONTAINER=1
WORKDIR /app
CMD ["./sigma", "build"]
