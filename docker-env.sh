#!/bin/sh

set -e

docker build -t sigma-linux .
docker run --privileged -v "$(pwd):/app" --workdir /app -it sigma-linux
