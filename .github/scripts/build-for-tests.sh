#!/bin/bash
set -e

echo "Building executables for testing..."
swift build --scratch-path /tmp/build-swift-modelling --configuration debug

echo ""
echo "Built executables:"
if [ "$(uname)" = "Darwin" ]; then
    if [ "$(uname -m)" = "arm64" ]; then
        ls -lh /tmp/build-swift-modelling/arm64-apple-macosx/debug/swift-* 2>/dev/null || echo "No executables found"
    else
        ls -lh /tmp/build-swift-modelling/x86_64-apple-macosx/debug/swift-* 2>/dev/null || echo "No executables found"
    fi
else
    ls -lh /tmp/build-swift-modelling/*-unknown-linux-gnu/debug/swift-* 2>/dev/null || echo "No executables found"
fi

echo ""
echo "Ready for testing!"
