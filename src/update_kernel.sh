#!/bin/sh

set -e

cd "$KERNEL_DIR"
git reset --hard HEAD
git fetch origin "$KERNEL_BRANCH" --depth 1
git checkout FETCH_HEAD
cd ..
