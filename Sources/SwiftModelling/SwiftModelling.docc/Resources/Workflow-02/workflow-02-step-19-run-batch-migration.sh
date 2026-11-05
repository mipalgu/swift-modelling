cd refactoring

# Migrate every legacy export, then check the results.
bash migrate-all-instances.sh
bash validate-migration.sh
# Output:
# Migrating orders-2024-01.xmi
# Migrating orders-2024-02.xmi
# Migrating orders-2024-03.xmi
# Migrated 3 file(s), skipped 0
# == Validating the migrated models
# ...
# Validated 3 files: 3 valid, 0 invalid
# == Comparing object counts with the cleaned exports
# orders-2024-01.xmi: orders 5 (as expected)
# orders-2024-01.xmi: items 10 (as expected)
# orders-2024-01.xmi: products 5 (as expected)
# orders-2024-01.xmi: customers 4 (as expected)
# ...
# orders-2024-03.xmi: customers 2 (as expected)
# All count checks passed

# A second run finds nothing left to do.
bash migrate-all-instances.sh
# Output:
# Skipping orders-2024-01.xmi: already migrated
# ...
# Migrated 0 file(s), skipped 3
