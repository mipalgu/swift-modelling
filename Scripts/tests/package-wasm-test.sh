#!/bin/sh
# Exercise release packaging without a compiler or WASI runtime.
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
build="$temporary/build"
mkdir -p "$build/swift-modelling_ModellingGenerators.resources" \
    "$build/swift-modelling_TutorialTests.resources"
for tool in swift-ecore swift-atl swift-mtl; do
    printf '\000asm\001\000\000\000' > "$build/$tool.wasm"
done
printf 'template\n' > "$build/swift-modelling_ModellingGenerators.resources/template.mtl"
"$root/Scripts/package-wasm.sh" "$build" "$temporary/package"
for tool in swift-ecore swift-atl swift-mtl; do
    cmp "$build/$tool.wasm" "$temporary/package/$tool.wasm"
done
cmp "$build/swift-modelling_ModellingGenerators.resources/template.mtl" \
    "$temporary/package/swift-modelling_ModellingGenerators.resources/template.mtl"
test ! -e "$temporary/package/swift-modelling_TutorialTests.resources"
rm "$build/swift-mtl.wasm"
if "$root/Scripts/package-wasm.sh" "$build" "$temporary/missing-module"; then
    echo 'error: packaging accepted a missing module' >&2
    exit 1
fi
printf '\000asm\001\000\000\000' > "$build/swift-mtl.wasm"
rm -r "$build/swift-modelling_ModellingGenerators.resources"
if "$root/Scripts/package-wasm.sh" "$build" "$temporary/missing-resources"; then
    echo 'error: packaging accepted missing product resources' >&2
    exit 1
fi
echo 'WebAssembly packaging checks passed'
