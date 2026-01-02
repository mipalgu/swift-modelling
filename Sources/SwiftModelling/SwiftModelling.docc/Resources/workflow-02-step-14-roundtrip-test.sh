# Test round-trip transformation
# Ensures data can be converted back to legacy format

# Transform migrated data back to legacy format
swift-atl transform Orders2LegacyOrders.atl \
    --source migrated-orders-data.xmi \
    --source-metamodel orders-v2.ecore \
    --target roundtrip-legacy-data.xmi \
    --target-metamodel legacy-orders-v1.ecore

# Output:
# [INFO] Transformation completed successfully
# [INFO] Output saved to: roundtrip-legacy-data.xmi

# Compare original and round-tripped legacy models
swift-ecore compare-instances \
    legacy-orders-data.xmi \
    roundtrip-legacy-data.xmi \
    --metamodel legacy-orders-v1.ecore

# Output:
# Instance Comparison Report
# ==========================
#
# Structural Comparison:
#   Store count:     1 = 1 ✓
#   Order count:     4 = 4 ✓
#   OrderItem count: 10 = 10 ✓
#   Product count:   5 = 5 ✓
#
# Value Comparison:
#
# Order ORD-2024-001:
#   orderId:         "ORD-2024-001" = "ORD-2024-001" ✓
#   orderDate:       "2024-01-15" = "2024-01-15" ✓
#   status:          "SHIPPED" = "SHIPPED" ✓
#   customerName:    "John Smith" = "John Smith" ✓
#   customerEmail:   "john.smith@example.com" = "john.smith@example.com" ✓
#   totalAmount:     1369.98 ≈ 1389.96 ✓ (calculated, within tolerance)
#
# Order ORD-2024-004:
#   status:          "pending" → "PENDING" (normalised during migration)
#   paymentMethod:   "paypal" → "PAYPAL" (normalised during migration)
#
# Differences Summary:
#   - Status and payment method values have been normalised to uppercase
#   - Total amounts recalculated (minor rounding differences possible)
#   - Address formatting may differ slightly
#
# Round-trip Status: PASSED (semantically equivalent)

# Verify specific order details are preserved
swift-aql evaluate --model roundtrip-legacy-data.xmi \
    --expression "Order.allInstances()->any(o | o.orderId = 'ORD-2024-001').customerEmail"

# Output: "john.smith@example.com"

# Verify product data preserved through round-trip
swift-aql evaluate --model roundtrip-legacy-data.xmi \
    --expression "Product.allInstances()->collect(p | p.code + ': ' + p.stockQty.toString())"

# Output:
# Sequence{
#   'LAPTOP-001: 45',
#   'LAPTOP-002: 30',
#   'PHONE-001: 120',
#   'CABLE-001: 500',
#   'CASE-001: 80'
# }
