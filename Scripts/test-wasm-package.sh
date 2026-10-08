#!/bin/sh
# Check an extracted WASI archive without granting access to build paths.
# Usage: Scripts/test-wasm-package.sh <wasmkit-path> <package-directory> <version>
set -eu

runtime=$1
version=$3
cd "$2"
temporary=$(mktemp -d ./smoke.XXXXXX)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

cat > "$temporary/demo.ecore" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="demo" nsURI="https://example.org/demo" nsPrefix="demo">
  <eClassifiers xsi:type="ecore:EClass" name="Thing">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="label"
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>
</ecore:EPackage>
EOF

run() {
    "$runtime" run --stack-size 67108864 --env TMPDIR=. --dir . "$@"
}
for tool in swift-ecore swift-atl swift-mtl; do
    test "$(run "$tool.wasm" --version)" = "$version"
done
run swift-ecore.wasm genmodel "$temporary/demo.ecore" --output "$temporary/demo.genmodel"
test -s "$temporary/demo.genmodel"
run swift-ecore.wasm generate --language java "$temporary/demo.genmodel" -o "$temporary/generated"
test -s "$temporary/generated/demo/Thing.java"
run swift-ecore.wasm generate --language java "$temporary/demo.ecore" -o "$temporary/direct"
diff -r "$temporary/generated" "$temporary/direct"
echo 'Extracted WebAssembly generation checks passed'
