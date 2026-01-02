# Reconcile data between source and target models
# Ensures no data was lost during migration

# Generate reconciliation report
swift-atl reconcile \
    --source legacy-orders-data.xmi \
    --source-metamodel legacy-orders-v1.ecore \
    --target migrated-orders-data.xmi \
    --target-metamodel orders-v2.ecore \
    --mapping LegacyOrders2Orders.atl

# Output:
# Data Reconciliation Report
# ==========================
#
# Source Model Summary:
#   Orders: 4
#   Products: 5
#   Order Items: 10
#
# Target Model Summary:
#   Orders: 4 ✓
#   Products: 5 ✓
#   Order Items: 10 ✓
#   Customers: 4 (derived from orders)
#   Addresses: 7 (parsed from strings)
#   Categories: 3 (parsed from strings)
#   Payments: 4 (extracted from orders)
#
# Field-Level Reconciliation:
# ──────────────────────────────────────────────────────
# Source Field                  -> Target Field      Status
# ──────────────────────────────────────────────────────
# Order.orderId                 -> Order.orderId       ✓
# Order.orderDate               -> Order.orderDate     ✓
# Order.status                  -> Order.status        ✓ (normalised)
# Order.customerName            -> Customer.name       ✓
# Order.customerEmail           -> Customer.email      ✓
# Order.customerPhone           -> Customer.phone      ✓
# Order.shippingAddress (str)   -> Address (struct)    ✓ (parsed)
# Order.billingAddress (str)    -> Address (struct)    ✓ (parsed)
# Order.totalAmount             -> Payment.amount      ✓
# Order.paymentMethod           -> Payment.method      ✓ (normalised)
# OrderItem.productCode         -> OrderItem.product   ✓ (resolved)
# OrderItem.qty                 -> OrderItem.quantity  ✓ (renamed)
# OrderItem.unitPrice           -> OrderItem.unitPriceAtOrder ✓
# Product.desc                  -> Product.description ✓ (renamed)
# Product.stockQty              -> InventoryItem.stockQuantity ✓
# ──────────────────────────────────────────────────────
#
# Reconciliation Status: PASSED
# All source data successfully migrated to target model.

# Verify specific values
swift-aql evaluate --model migrated-orders-data.xmi \
    --expression "Order.allInstances()->collect(o | o.orderId + ': ' + o.customer.name)"

# Output:
# Sequence{
#   'ORD-2024-001: John Smith',
#   'ORD-2024-002: Sarah Johnson',
#   'ORD-2024-003: Tech Solutions Pty Ltd',
#   'ORD-2024-004: Jane Doe'
# }
