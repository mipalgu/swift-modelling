cd refactoring

# What if the cleaning step were skipped? Migrate the raw export ...
swift-atl transform LegacyOrders2Orders.atl -q \
    --source legacy/orders-2024-01.xmi --target trial/uncleaned.xmi \
    --source-metamodel LegacyOrders.ecore --target-metamodel Orders.ecore

# ... and the invariants and multiplicities of Orders.ecore reject it:
# John Smith appears twice, once with a mixed-case e-mail address, the
# item with product code cable-001 has no product, and two orders whose
# status and payment method are not in capitals have neither. An unset
# status would read as the first literal, which the Eclipse Modeling
# Framework accepts; --require-explicit-values reports it instead.
# Expected error: validation fails
swift-ecore validate trial/uncleaned.xmi -m Orders.ecore --require-explicit-values
# Output:
# Checking constraint: lowerCaseEmail (Customer 'John Smith', //@customers.4) ... violated
# OCL invariants: 27 of 28 check(s) satisfied
# error: Payment (//@orders.3/@payment): Feature 'method' needs at least 1 value(s) but has 0
# error: OrderItem (//@orders.3/@items.1): Feature 'product' needs at least 1 value(s) but has 0
# error: Order 'ORD-2024-004' (//@orders.3): Feature 'status' needs at least 1 value(s) but has 0
# error: Payment '4242' (//@orders.4/@payment): Feature 'method' needs at least 1 value(s) but has 0
# error: Order 'ORD-2024-005' (//@orders.4): Feature 'status' needs at least 1 value(s) but has 0
# Error: Validation failed: 6 error(s), 0 warning(s)
