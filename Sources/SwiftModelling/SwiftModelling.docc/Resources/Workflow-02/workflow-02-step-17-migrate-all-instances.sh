#!/bin/sh
# Cleans and migrates every legacy export in legacy/ to migrated/.
# A file that already has a migrated model is skipped, so an interrupted
# run can simply be started again; delete a migrated model to redo it.
set -eu

mkdir -p cleaned migrated
migrated=0
skipped=0
for legacy in legacy/*.xmi; do
    name=$(basename "$legacy")
    if [ -f "migrated/$name" ]; then
        echo "Skipping $name: already migrated"
        skipped=$((skipped + 1))
        continue
    fi
    echo "Migrating $name"
    swift-atl transform CleanLegacyOrders.atl -q \
        --source "$legacy" --target "cleaned/$name" \
        --metamodel LegacyOrders.ecore
    swift-atl transform LegacyOrders2Orders.atl -q \
        --source "cleaned/$name" --target "migrated/$name" \
        --source-metamodel LegacyOrders.ecore --target-metamodel Orders.ecore
    migrated=$((migrated + 1))
done
echo "Migrated $migrated file(s), skipped $skipped"
