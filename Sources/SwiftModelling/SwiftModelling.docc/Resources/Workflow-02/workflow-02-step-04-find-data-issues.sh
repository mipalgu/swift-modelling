cd refactoring
data=legacy/orders-2024-01.xmi

# Free-text statuses: which spellings occur, and which orders deviate?
swift-aql query "$data" -m LegacyOrders.ecore "self.orders.status->asSet()"
swift-aql query "$data" -m LegacyOrders.ecore \
    "self.orders->select(o | o.status <> o.status.toUpper()).orderId"
# Output:
# ["SHIPPED", "PENDING", "DELIVERED", "pending", "Shipped"]
# ["ORD-2024-004", "ORD-2024-005"]

# Customer details repeated in every order: e-mail addresses as typed,
# distinct e-mail addresses ignoring case, and the orders of repeat customers.
swift-aql query "$data" -m LegacyOrders.ecore "self.orders.customerEmail->asSet()->size()"
swift-aql query "$data" -m LegacyOrders.ecore \
    "self.orders.customerEmail->collect(e | e.toLower())->asSet()->size()"
swift-aql query "$data" -m LegacyOrders.ecore \
    "self.orders->select(o | self.orders->exists(p | p <> o and p.customerEmail.toLower() = o.customerEmail.toLower())).orderId"
# Output:
# 5
# 4
# ["ORD-2024-001", "ORD-2024-005"]

# Items name products by a code string: which codes match no product?
swift-aql query "$data" -m LegacyOrders.ecore \
    "self.orders.items.productCode->reject(c | self.products.code->includes(c))"
# Output:
# ["cable-001"]

# Stored totals: which orders do not add up to the sum of their items?
swift-aql query "$data" -m LegacyOrders.ecore \
    "self.orders->select(o | (o.totalAmount - o.items.lineTotal->sum()).abs() > 0.005).orderId"
swift-aql query "$data" -m LegacyOrders.ecore --context ORD-2024-004 \
    "self.totalAmount.toString() + ' stored, ' + self.items.lineTotal->sum().toString() + ' from the items'"
# Output:
# ["ORD-2024-004"]
# 949.98 stored, 958.97 from the items
