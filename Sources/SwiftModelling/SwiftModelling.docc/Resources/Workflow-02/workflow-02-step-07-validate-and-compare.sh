cd refactoring

# The improved metamodel must be well formed.
swift-ecore validate Orders.ecore

# Its size metrics: more, but smaller, classes than the legacy metamodel.
swift-ecore statistics Orders.ecore
# Output:
# Classes: 8
# OCL invariants: 8
# Classes by number of features:
#   Order: 9 (9 declared)
#   Product: 6 (6 declared)
#   Address: 5 (5 declared)

# What changed between the two versions?
swift-ecore compare LegacyOrders.ecore Orders.ecore
# Output:
# Comparing metamodels: LegacyOrders.ecore -> Orders.ecore
# ...
# - attribute Product.desc: EString [0..1]
# ...
# + attribute Product.description: EString [0..1]
# ...
# ~ attribute Order.status type: EString -> OrderStatus
# ...
# - attribute Order.customerName: EString [0..1]
# ...
# ~ reference Order.shippingAddress type: EString -> Address
# ...
# + reference Order.customer: Customer [1..1]
# ...
# + reference OrderItem.product: Product [1..1]
# + attribute OrderItem.quantity: EInt [0..1]
# + enumeration OrderStatus: PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED
# ...
# + class Customer
# + class Address
# ...
# 46 differences: 13 added, 16 removed, 17 changed
