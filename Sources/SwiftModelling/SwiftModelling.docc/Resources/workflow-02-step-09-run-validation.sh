# Run validation queries on migrated data
# Ensures data integrity after migration

# Execute validation transformation
swift-atl transform OrdersValidation.atl \
    --source migrated-orders-data.xmi \
    --metamodel orders-v2.ecore \
    --query-only

# Output:
# Migration Validation Report
# ===========================
#
# Orders without customer: 0
# Orphaned order items: 0
# Duplicate customer emails: 0
# Products with invalid price: 0
# Inventory below reorder level: 2
# Orders with payment mismatch: 1
# Categories without codes: 0
#
# Validation PASSED

# Generate detailed validation report
swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "Order.allInstances()->select(o | o.customer.oclIsUndefined())"

# Output: Sequence{}  (empty - all orders have customers)

# Check for data quality issues
swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "InventoryItem.allInstances()->select(i | i.stockQuantity < i.reorderLevel)->collect(i | i.product.name + ': ' + i.stockQuantity.toString() + ' (reorder at ' + i.reorderLevel.toString() + ')')"

# Output:
# Sequence{
#   'SmartPhone X: 120 (reorder at 25)',
#   'USB-C Cable: 500 (reorder at 100)'
# }
# Note: These are above reorder level, so no action needed

# Verify referential integrity
swift-ecore check-refs migrated-orders-data.xmi \
    --metamodel orders-v2.ecore

# Output:
# Referential integrity check passed.
# All references resolved successfully.
# No dangling references found.
