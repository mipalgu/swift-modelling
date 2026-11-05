#!/bin/sh
# Brings the tools that depend on the order models up to date with
# Orders 2.0, and keeps the legacy format available for the rest.
set -eu

echo "== Swift model classes from Orders.ecore"
swift-ecore generate Orders.ecore --language swift --output generated/swift

echo "== Order summaries from the migrated models"
for model in migrated/*.xmi; do
    name=$(basename "$model" .xmi)
    swift-mtl generate OrderSummary.mtl --model "$model" \
        --metamodel Orders.ecore --output "generated/summaries/$name"
done

echo "== Legacy-format exports for tools still on version 1.0"
mkdir -p generated/legacy-format
for model in migrated/*.xmi; do
    name=$(basename "$model")
    swift-atl transform Orders2LegacyOrders.atl -q \
        --source "$model" --target "generated/legacy-format/$name" \
        --source-metamodel Orders.ecore --target-metamodel LegacyOrders.ecore
done
swift-ecore validate generated/legacy-format/*.xmi -m LegacyOrders.ecore
