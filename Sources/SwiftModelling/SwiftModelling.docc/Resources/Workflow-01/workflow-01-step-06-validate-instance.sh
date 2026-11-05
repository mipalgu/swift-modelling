# Validate the shop data against the metamodel. This checks classes, feature
# types, multiplicities and references, and evaluates every OCL invariant of
# the metamodel for every object.
swift-ecore validate shop-data.xmi --metamodel ECommerce.ecore

# Output:
# OCL invariants: 40 of 40 check(s) satisfied
# Validation completed successfully

# Count the objects of each class.
swift-ecore inspect shop-data.xmi --metamodel ECommerce.ecore

# Output:
# Model: shop-data.xmi (XMI)
# ...
# Objects: 43
# ...
# Category: 4
# Customer: 5
# Order: 8
# OrderItem: 15
# Product: 10
# Shop: 1
