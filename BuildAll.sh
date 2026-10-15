#!/bin/sh
cd "$(dirname "$0")" && exec sh jbuild/make/buildall.sh "$@"
