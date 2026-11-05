# Create the test instances.
bash create-test-instances.sh

# Output:
# Model created: test-instances/new-shop.xmi
# empty-shop.xmi
# invalid-shop.xmi
# new-shop.xmi
# single-order.xmi

# The complete test instances conform to the metamodel and its invariants.
# Given several files, validate checks each of them and counts the results.
swift-ecore validate test-instances/empty-shop.xmi test-instances/single-order.xmi \
    --metamodel ECommerce.ecore

# Output:
# Validating: test-instances/empty-shop.xmi
# test-instances/empty-shop.xmi: valid
# Validating: test-instances/single-order.xmi
# OCL invariants: 4 of 4 check(s) satisfied
# test-instances/single-order.xmi: valid
# Validated 2 files: 2 valid, 0 invalid

# Expected error: the new shop lacks its required name, and invalid-shop.xmi
# breaks four business rules, so both are rejected.
swift-ecore validate test-instances/new-shop.xmi test-instances/invalid-shop.xmi \
    --metamodel ECommerce.ecore || echo "swift-ecore exited with status $?"

# Output:
# Validating: test-instances/new-shop.xmi
# error: Shop (/): Feature 'name' needs at least 1 value(s) but has 0
# test-instances/new-shop.xmi: invalid (1 error(s), 0 warning(s))
# Validating: test-instances/invalid-shop.xmi
# Checking constraint: positivePrice (Product 'Gift Card', //@products.0) ... violated
# Checking constraint: validEmail (Customer 'Kim Park', //@customers.0) ... violated
# Checking constraint: positiveQuantity (OrderItem, //@orders.0/@items.0) ... violated
# OCL invariants: 1 of 4 check(s) satisfied
# error: Order 'T-003' (//@orders.1): Feature 'items' needs at least 1 value(s) but has 0
# test-instances/invalid-shop.xmi: invalid (4 error(s), 0 warning(s))
# Validated 2 files: 0 valid, 2 invalid
# Error: Validation failed for 2 of 2 files: test-instances/new-shop.xmi, test-instances/invalid-shop.xmi
# swift-ecore exited with status 1
