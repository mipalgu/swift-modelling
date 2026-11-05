cd refactoring

# What if the cleaning step were skipped? Migrate the raw export ...
swift-atl transform LegacyOrders2Orders.atl -q \
    --source legacy/orders-2024-01.xmi --target trial/uncleaned.xmi \
    --source-metamodel LegacyOrders.ecore --target-metamodel Orders.ecore

# ... and the invariants and multiplicities of Orders.ecore reject it:
# John Smith appears twice, once with a mixed-case e-mail address, and
# the item with product code cable-001 has no product.
# Expected error: validation fails
swift-ecore validate trial/uncleaned.xmi -m Orders.ecore
# Output:
# Checking constraint: lowerCaseEmail (Customer 'John Smith', //@customers.4) ... violated
# error: OrderItem (//@orders.3/@items.1): Feature 'product' needs at least 1 value(s) but has 0
# Error: Validation failed: 2 error(s), 0 warning(s)
