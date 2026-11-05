cd refactoring

# 1. Update the dependent tools and regenerate their artefacts.
bash update-toolchain.sh
# Output:
# == Swift model classes from Orders.ecore
# ...
# == Order summaries from the migrated models
# ...
# == Legacy-format exports for tools still on version 1.0
# ...
# Validated 3 files: 3 valid, 0 invalid

# 2. Back up the legacy models before the release replaces them.
sh rollback-procedures.sh backup
# Output:
# Backed up 3 legacy models to backup/legacy-1.0

# 3. Assemble the release: improved metamodel, migrated models, manifest.
rm -rf release
mkdir -p release/models
cp Orders.ecore release/
cp migrated/*.xmi release/models/
(cd release && shasum -a 256 Orders.ecore models/*.xmi > SHA256SUMS)

# 4. Verify the release as a consumer would: checksums, then validation.
(cd release && shasum -a 256 -c SHA256SUMS)
swift-ecore validate release/models/*.xmi -m release/Orders.ecore
# Output:
# Orders.ecore: OK
# models/orders-2024-01.xmi: OK
# models/orders-2024-02.xmi: OK
# models/orders-2024-03.xmi: OK
# ...
# Validated 3 files: 3 valid, 0 invalid

# 5. Rehearse a rollback: restore the backup into a scratch directory and
#    check that it is identical to the legacy exports.
sh rollback-procedures.sh restore rollback-rehearsal
for legacy in legacy/*.xmi; do
    cmp "$legacy" "rollback-rehearsal/$(basename "$legacy")"
done
echo "Rollback rehearsal restored identical legacy models"
# Output:
# Restored the legacy models into rollback-rehearsal
# Rollback rehearsal restored identical legacy models
