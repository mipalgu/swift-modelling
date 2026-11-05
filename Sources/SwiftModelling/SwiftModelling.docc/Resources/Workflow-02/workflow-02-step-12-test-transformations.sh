cd refactoring
mkdir -p trial

# 1. Clean the January export (refining: the output starts as a copy).
swift-atl transform CleanLegacyOrders.atl \
    --source legacy/orders-2024-01.xmi --target trial/cleaned.xmi \
    --metamodel LegacyOrders.ecore

# 2. Migrate the cleaned export to the improved metamodel.
swift-atl transform LegacyOrders2Orders.atl \
    --source trial/cleaned.xmi --target trial/migrated.xmi \
    --source-metamodel LegacyOrders.ecore --target-metamodel Orders.ecore

# 3. Validate the result, including the OCL invariants of Orders.ecore.
swift-ecore validate trial/migrated.xmi -m Orders.ecore

# 4. Compare the numbers of objects per class before and after.
swift-ecore compare trial/cleaned.xmi trial/migrated.xmi --summary \
    -m LegacyOrders.ecore -m Orders.ecore
# Output:
# OCL invariants: 26 of 26 check(s) satisfied
# Validation completed successfully
# Comparing models: cleaned.xmi -> migrated.xmi
# Objects per class:
#   Address: 0 -> 10 (+10)
#   Customer: 0 -> 4 (+4)
#   Order: 5 -> 5
#   OrderItem: 10 -> 10
#   Payment: 0 -> 5 (+5)
#   Product: 5 -> 5
#   StockLevel: 0 -> 5 (+5)

# 5. Spot checks: one customer per e-mail address, items linked to products.
swift-aql query trial/migrated.xmi -m Orders.ecore "self.customers.name"
swift-aql query trial/migrated.xmi -m Orders.ecore --context ORD-2024-004 \
    "self.items->collect(i | i.product.name + ' x ' + i.quantity.toString())"
# Output:
# ["John Smith", "Sarah Johnson", "Tech Solutions Pty Ltd", "Jane Doe"]
# ["SmartPhone X x 1", "USB-C Cable x 3"]
