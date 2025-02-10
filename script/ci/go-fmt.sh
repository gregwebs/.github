#!/usr/bin/env bash
set -euo pipefail

gofiles=$(find . -name '*.go' | grep -v '/\.')
if [[ -n "$(gofmt -l $gofiles)" ]] ; then
    gofmt -d $gofiles
    echo "go files need formatting" >&2
    gofmt -l $gofiles >&2
    echo "go files need formatting" >&2
    exit 1
fi
gofmt -s -w $gofiles