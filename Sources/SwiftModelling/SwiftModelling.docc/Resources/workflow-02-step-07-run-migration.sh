# Run the migration transformation
# Converts legacy model instances to new metamodel format

# Execute the ATL transformation
swift-atl transform LegacyOrders2Orders.atl \
    --source legacy-orders-data.xmi \
    --source-metamodel legacy-orders-v1.ecore \
    --target migrated-orders-data.xmi \
    --target-metamodel orders-v2.ecore \
    --verbose

# Output:
# [INFO] Loading source metamodel: legacy-orders-v1.ecore
# [INFO] Loading target metamodel: orders-v2.ecore
# [INFO] Loading source model: legacy-orders-data.xmi
# [INFO] Compiling transformation: LegacyOrders2Orders.atl
# [INFO] Executing transformation...
#
# [PROGRESS] Processing Store elements: 1
# [PROGRESS] Processing Order elements: 4
# [PROGRESS] Processing OrderItem elements: 10
# [PROGRESS] Processing Product elements: 5
#
# [INFO] Created elements:
#   - Store: 1
#   - Customer: 4 (deduplicated from 4 orders)
#   - Address: 7 (unique addresses)
#   - Category: 3 (from 3 unique category paths)
#   - Order: 4
#   - OrderItem: 10
#   - Payment: 4
#   - Product: 5
#   - InventoryItem: 5
#   - Warehouse: 1
#
# [INFO] Transformation completed in 0.45 seconds
# [INFO] Output saved to: migrated-orders-data.xmi

# Verify the migration was successful
swift-ecore validate migrated-orders-data.xmi \
    --metamodel orders-v2.ecore

# Output:
# Validation successful. No errors found.
# Model conforms to Orders (v2.0) metamodel.
