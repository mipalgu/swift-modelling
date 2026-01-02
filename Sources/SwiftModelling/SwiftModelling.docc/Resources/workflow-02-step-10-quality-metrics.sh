# Calculate quality metrics for the migrated model
# Measures improvements from legacy to new metamodel

# Generate model metrics
swift-ecore metrics migrated-orders-data.xmi \
    --metamodel orders-v2.ecore \
    --output metrics-report.json

# Output:
# Model Quality Metrics
# =====================
#
# Element Counts:
#   Store:          1
#   Customer:       4
#   Address:        7
#   Category:       3
#   Order:          4
#   OrderItem:     10
#   Payment:        4
#   Product:        5
#   InventoryItem:  5
#   Warehouse:      1
#   ─────────────────
#   Total:         44
#
# Structural Metrics:
#   Max containment depth: 3 (Store -> Order -> OrderItem)
#   Avg references per element: 2.3
#   Bidirectional references: 8
#   Containment relationships: 6
#
# Data Quality:
#   Required attributes filled: 100%
#   Optional attributes filled: 78%
#   Enum values valid: 100%

# Compare with legacy model metrics
swift-ecore metrics legacy-orders-data.xmi \
    --metamodel legacy-orders-v1.ecore \
    --output legacy-metrics-report.json

# Improvement Summary:
# ====================
#
# Metric                    Legacy    Migrated    Improvement
# ─────────────────────────────────────────────────────────────
# Classes used              4         10          +6 (better separation)
# Avg attributes/class      8.2       4.1         -50% (focused classes)
# String enums              2         0           -100% (proper enums)
# Denormalised data         6         0           -100% (normalised)
# Proper references         2         14          +600% (better links)
# Data duplication score    0.45      0.02        -96% (deduplication)

# Calculate normalisation score
swift-ecore normalisation-score \
    legacy-orders-data.xmi \
    migrated-orders-data.xmi

# Output:
# Normalisation Score Comparison
# ==============================
# Legacy model:   0.35 (poor - significant denormalisation)
# Migrated model: 0.92 (excellent - well normalised)
#
# Improvement: +163%
