# All files of this tutorial live in the refactoring directory.
cd refactoring

# Check that the legacy metamodel and its data load cleanly.
swift-ecore validate LegacyOrders.ecore
swift-ecore validate legacy/orders-2024-01.xmi -m LegacyOrders.ecore

# Size metrics of the metamodel: which classes carry the most features?
swift-ecore statistics LegacyOrders.ecore
# Output:
# Classes: 4
# Attributes: 28
# Classes by number of features:
#   Order: 15 (15 declared)
#   Product: 8 (8 declared)
#   OrderItem: 5 (5 declared)

# The attributes of each class, to see what the largest class mixes.
swift-ecore inspect LegacyOrders.ecore --show-attributes

# Size metrics of the data: objects per class.
swift-ecore statistics legacy/orders-2024-01.xmi -m LegacyOrders.ecore
# Output:
# Objects per class:
#   Order: 5
#   OrderItem: 10
#   Product: 5
#   Store: 1
