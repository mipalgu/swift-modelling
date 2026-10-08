#!/bin/sh
# Assemble WASI command modules with adjacent SwiftPM resource bundles.
# Usage: Scripts/package-wasm.sh <build-directory> <package-directory>
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <build-directory> <package-directory>" >&2
    exit 64
fi

build_directory=$1
package_directory=$2
mkdir -p "$package_directory"
for tool in swift-ecore swift-atl swift-mtl; do
    cp "$build_directory/$tool.wasm" "$package_directory/"
done

found=0
for bundle in "$build_directory"/*.resources; do
    [ -d "$bundle" ] || continue
    case $(basename "$bundle") in
        *Tests.resources | *-tests.resources) continue ;;
    esac
    cp -R "$bundle" "$package_directory/"
    found=1
done
if [ "$found" -eq 0 ]; then
    echo "error: no product resource bundles found in $build_directory" >&2
    exit 1
fi
