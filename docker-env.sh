#!/bin/sh

mkdir -p cache out
docker build -t sigma-linux .
docker run -v "$(pwd)"/cache:/app/cache -v "$(pwd)"/out:/app/out -it sigma-linux sh
