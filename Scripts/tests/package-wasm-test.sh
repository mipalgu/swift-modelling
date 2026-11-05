#!/bin/sh
# Exercise release packaging without a compiler or WASI runtime.
# The tools are those named in Scripts/tools.txt, one per line.
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
tools=$(cat "$root/Scripts/tools.txt")
products=$(sed -n '/\.executable(/{n;s/.*name: "\(.*\)".*/\1/p;}' "$root/Package.swift")
if [ "$products" != "$tools" ]; then
    echo 'error: Scripts/tools.txt does not list the executable products of Package.swift' >&2
    exit 1
fi
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
build="$temporary/build"
mkdir -p "$build/swift-modelling_ModellingGenerators.resources" \
    "$build/swift-modelling_TutorialTests.resources"
for tool in $tools; do
    printf '\000asm\001\000\000\000' > "$build/$tool.wasm"
    missing=$tool
done
printf 'template\n' > "$build/swift-modelling_ModellingGenerators.resources/template.mtl"
"$root/Scripts/package-wasm.sh" "$build" "$temporary/package"
for tool in $tools; do
    cmp "$build/$tool.wasm" "$temporary/package/$tool.wasm"
done
cmp "$build/swift-modelling_ModellingGenerators.resources/template.mtl" \
    "$temporary/package/swift-modelling_ModellingGenerators.resources/template.mtl"
test ! -e "$temporary/package/swift-modelling_TutorialTests.resources"
rm "$build/$missing.wasm"
if "$root/Scripts/package-wasm.sh" "$build" "$temporary/missing-module"; then
    echo 'error: packaging accepted a missing module' >&2
    exit 1
fi
printf '\000asm\001\000\000\000' > "$build/$missing.wasm"
rm -r "$build/swift-modelling_ModellingGenerators.resources"
if "$root/Scripts/package-wasm.sh" "$build" "$temporary/missing-resources"; then
    echo 'error: packaging accepted missing product resources' >&2
    exit 1
fi
echo 'WebAssembly packaging checks passed'
