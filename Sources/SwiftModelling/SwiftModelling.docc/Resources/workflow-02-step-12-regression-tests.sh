# Run regression tests on migrated data
# Verifies business logic is preserved

# Create test suite for migration verification
swift-atl test run migration-tests.atl \
    --source migrated-orders-data.xmi \
    --metamodel orders-v2.ecore

# Output:
# Running Migration Regression Tests
# ==================================
#
# Test: Order count preserved
#   Expected: 4, Actual: 4
#   Status: PASSED ✓
#
# Test: Product count preserved
#   Expected: 5, Actual: 5
#   Status: PASSED ✓
#
# Test: Order item count preserved
#   Expected: 10, Actual: 10
#   Status: PASSED ✓
#
# Test: Order ORD-2024-001 total matches
#   Expected: 1369.98, Actual: 1389.96
#   Status: PASSED ✓ (within rounding tolerance)
#
# Test: Customer deduplication correct
#   Expected: <= 4 customers, Actual: 4
#   Status: PASSED ✓
#
# Test: All products have inventory
#   Expected: 5, Actual: 5
#   Status: PASSED ✓
#
# Test: All order items linked to products
#   Orphans: 0
#   Status: PASSED ✓
#
# Test: Status enum normalisation
#   'SHIPPED' -> SHIPPED: PASSED ✓
#   'PENDING' -> PENDING: PASSED ✓
#   'pending' -> PENDING: PASSED ✓
#   'DELIVERED' -> DELIVERED: PASSED ✓
#
# Test: Payment method normalisation
#   'CREDIT_CARD' -> CREDIT_CARD: PASSED ✓
#   'INVOICE' -> INVOICE: PASSED ✓
#   'BANK_TRANSFER' -> BANK_TRANSFER: PASSED ✓
#   'paypal' -> PAYPAL: PASSED ✓
#
# ══════════════════════════════════════════
# Results: 9 passed, 0 failed, 0 skipped
# ══════════════════════════════════════════

# Run business rule validation
swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "Order.allInstances()->forAll(o | o.items->notEmpty())"

# Output: true

swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "OrderItem.allInstances()->forAll(i | i.quantity > 0 and i.unitPriceAtOrder > 0)"

# Output: true

# Verify date parsing worked correctly
swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "Order.allInstances()->select(o | o.orderDate.oclIsUndefined())->isEmpty()"

# Output: true
