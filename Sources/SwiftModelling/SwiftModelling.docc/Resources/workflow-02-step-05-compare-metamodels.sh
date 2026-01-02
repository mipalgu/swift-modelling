# Compare legacy and improved metamodels
# Identify differences and generate migration requirements

# Generate comparison report
swift-ecore compare \
    legacy-orders-v1.ecore \
    orders-v2.ecore \
    --output comparison-report.md

# Output:
# Metamodel Comparison Report
# ===========================
#
# Source: LegacyOrders (v1.0)
# Target: Orders (v2.0)
#
# ADDED CLASSES:
#   + Address (new structured type)
#   + Customer (extracted from Order)
#   + Category (replaces string attribute)
#   + Payment (extracted from Order)
#   + InventoryItem (extracted from Product)
#   + Warehouse (new entity)
#   + NamedElement (new abstract base)
#
# MODIFIED CLASSES:
#   ~ Order
#     - Removed: customerName, customerEmail, customerPhone
#     - Removed: shippingAddress (String), billingAddress (String)
#     - Removed: totalAmount, taxAmount (derived values)
#     - Removed: paymentMethod, cardLastFour
#     + Added: customer (reference to Customer)
#     + Added: shippingAddress (reference to Address)
#     + Added: billingAddress (reference to Address)
#     + Added: payment (containment to Payment)
#     ~ Changed: status (String -> OrderStatus enum)
#     ~ Changed: orderDate (String -> EDate)
#
#   ~ OrderItem
#     - Removed: productCode, productName (denormalised)
#     - Removed: lineTotal (derived value)
#     + Added: product (reference to Product)
#     ~ Renamed: qty -> quantity
#
#   ~ Product
#     - Removed: stockQty, reorderLevel, warehouseLocation
#     + Added: inventory (reference to InventoryItem)
#     + Added: category (reference to Category)
#     ~ Renamed: desc -> description

# Generate migration requirements document
swift-ecore migration-plan \
    legacy-orders-v1.ecore \
    orders-v2.ecore \
    --format detailed

# Output:
# Migration Requirements
# ======================
#
# 1. Extract Customer from Order
#    - Create Customer for each unique customerEmail
#    - Link Order to Customer via customer reference
#
# 2. Parse Address strings
#    - Parse shippingAddress and billingAddress strings
#    - Create structured Address objects
#
# 3. Create Categories
#    - Parse category string (e.g., "Electronics/Computers")
#    - Create Category hierarchy
#
# 4. Link OrderItem to Product
#    - Match OrderItem.productCode to Product.code
#    - Create product reference
#
# 5. Separate Inventory
#    - Create InventoryItem for each Product
#    - Parse warehouseLocation to create Warehouse references
#
# 6. Normalise Enumerations
#    - Map status strings to OrderStatus enum
#    - Map paymentMethod strings to PaymentMethod enum
