cd refactoring
mkdir -p reports

# For each migrated model: its statistics and the object counts before
# and after the migration, as JSON for other tools to read.
for model in migrated/*.xmi; do
    name=$(basename "$model" .xmi)
    swift-ecore statistics "$model" -m Orders.ecore \
        --format json -o "reports/$name-statistics.json"
    swift-ecore compare "legacy/$name.xmi" "$model" --summary \
        -m LegacyOrders.ecore -m Orders.ecore \
        --format json -o "reports/$name-counts.json"
done
# Output:
# Statistics written: reports/orders-2024-01-statistics.json
# Comparison written: reports/orders-2024-01-counts.json
# ...
# Comparison written: reports/orders-2024-03-counts.json

# A checksum manifest records exactly which files the migration produced.
shasum -a 256 migrated/*.xmi > reports/migrated.sha256
shasum -a 256 -c reports/migrated.sha256
# Output:
# migrated/orders-2024-01.xmi: OK
# migrated/orders-2024-02.xmi: OK
# migrated/orders-2024-03.xmi: OK

ls reports
# Output:
# migrated.sha256
# orders-2024-01-counts.json
# orders-2024-01-statistics.json
# ...
