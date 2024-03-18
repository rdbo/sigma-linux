#!/bin/sh

set -e

git clone --depth 1 -b "$KERNEL_BRANCH" "$KERNEL_GIT" "$KERNEL_DIR"
