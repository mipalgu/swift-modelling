cd refactoring

# Write the migrated January model back in the legacy format.
swift-atl transform Orders2LegacyOrders.atl \
    --source trial/migrated.xmi --target trial/round-trip.xmi \
    --source-metamodel Orders.ecore --target-metamodel LegacyOrders.ecore
swift-ecore validate trial/round-trip.xmi -m LegacyOrders.ecore

# Compare it with the cleaned export. lastModified is dropped on purpose,
# so it is ignored; every other difference needs an explanation.
swift-ecore compare trial/cleaned.xmi trial/round-trip.xmi \
    -m LegacyOrders.ecore --ignore Order.lastModified
# Output:
# ~ object Order 'ORD-2024-004' (//@orders.3) shippingAddress: "5/22 George St, Perth WA 6000" -> "5/22 George St, Perth WA 6000, Australia"
# ~ object Order 'ORD-2024-004' (//@orders.3) billingAddress: "5/22 George St, Perth WA 6000" -> "5/22 George St, Perth WA 6000, Australia"
# ~ object Order 'ORD-2024-004' (//@orders.3) totalAmount: 949.98 -> 958.97
# ~ object Order 'ORD-2024-004' (//@orders.3) taxAmount: 95.0 -> 95.9
# 4 differences: 0 added, 0 removed, 4 changed
