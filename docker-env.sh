#!/bin/sh

set -e

docker build -t sigma-linux .
docker run --privileged -v "$(pwd):/app" -it sigma-linux sh
