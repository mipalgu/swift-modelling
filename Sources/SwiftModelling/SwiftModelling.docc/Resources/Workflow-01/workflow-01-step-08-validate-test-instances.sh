# Create the test instances.
bash create-test-instances.sh

# Output:
# Model created: test-instances/new-shop.xmi
# empty-shop.xmi
# invalid-shop.xmi
# new-shop.xmi
# single-order.xmi

# The complete test instances conform to the metamodel and its invariants.
for model in test-instances/empty-shop.xmi test-instances/single-order.xmi; do
    echo "== $model"
    swift-ecore validate "$model" --metamodel ECommerce.ecore
done

# Output:
# == test-instances/empty-shop.xmi
# Validation completed successfully
# == test-instances/single-order.xmi
# OCL invariants: 5 of 5 check(s) satisfied
# Validation completed successfully

# Expected error: the new shop lacks its required name, and invalid-shop.xmi
# breaks four business rules, so both are rejected.
echo "== test-instances/new-shop.xmi"
swift-ecore validate test-instances/new-shop.xmi --metamodel ECommerce.ecore \
    || echo "swift-ecore exited with status $?"
echo "== test-instances/invalid-shop.xmi"
swift-ecore validate test-instances/invalid-shop.xmi --metamodel ECommerce.ecore

# Output:
# == test-instances/new-shop.xmi
# error: Shop (/): Feature 'name' needs at least 1 value(s) but has 0
# Error: Validation failed: 1 error(s), 0 warning(s)
# swift-ecore exited with status 1
# == test-instances/invalid-shop.xmi
# Checking constraint: positivePrice (Product 'Gift Card', //@products.0) ... violated
# Checking constraint: validEmail (Customer 'Kim Park', //@customers.0) ... violated
# Checking constraint: positiveQuantity (OrderItem, //@orders.0/@items.0) ... violated
# Checking constraint: hasItems (Order 'T-003', //@orders.1) ... violated
# OCL invariants: 2 of 6 check(s) satisfied
# Error: Validation failed: 4 error(s), 0 warning(s)
