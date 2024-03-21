#!/bin/sh

set -e

docker build -t sigma-linux .
docker run -v "$(pwd):/app" -it sigma-linux sh
