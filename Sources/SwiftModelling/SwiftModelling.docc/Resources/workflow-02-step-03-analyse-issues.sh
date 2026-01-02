# Analyse legacy metamodel for design issues
# Uses swift-ecore to identify potential problems

# Validate the legacy metamodel structure
swift-ecore validate legacy-orders-v1.ecore

# Output:
# Validation complete. Found 8 potential issues:
#
# [WARNING] Order: Class has 14 attributes (recommended max: 7)
#   - Consider extracting related attributes into separate classes
#
# [WARNING] Order.status: String type used for enumerable values
#   - Consider using EEnum for: PENDING, SHIPPED, DELIVERED, CANCELLED
#
# [WARNING] Order: Contains denormalised customer data
#   - customerName, customerEmail, customerPhone should reference Customer class
#
# [WARNING] Order: Address stored as single string
#   - shippingAddress, billingAddress should use structured Address class
#
# [WARNING] OrderItem: No reference to Product class
#   - productCode string duplicates Product.code relationship
#
# [WARNING] OrderItem.qty: Abbreviated attribute name
#   - Consider renaming to 'quantity' for clarity
#
# [WARNING] Product: Mixed concerns detected
#   - Inventory attributes (stockQty, reorderLevel, warehouseLocation)
#     should be in separate InventoryItem class
#
# [WARNING] Product.desc: Abbreviated attribute name
#   - Consider renaming to 'description' for clarity

# Generate detailed analysis report
swift-ecore analyse legacy-orders-v1.ecore \
    --report-format markdown \
    --output analysis-report.md

# Check for circular dependencies
swift-ecore check-deps legacy-orders-v1.ecore

# Output:
# No circular dependencies found.
# Reference graph: Store -> Order -> OrderItem
#                  Store -> Product
