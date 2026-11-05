# Navigate: the number of products in each category. Category.products is
# filled from Product.category, its opposite.
swift-aql query shop-data.xmi "self.categories->collect(c | c.name + ': ' + c.products->size().toString())"

# Select: the products under 100, and the products that are out of stock.
swift-aql query shop-data.xmi "self.products->select(p | p.price < 100)->collect(p | p.name)"
swift-aql query shop-data.xmi "self.products->select(p | p.stock = 0)->collect(p | p.sku)"

# Follow references: the orders of one customer, and what an order contains.
swift-aql query shop-data.xmi "self.customers->select(c | c.name = 'Alice Nguyen')->first().orders->collect(o | o.orderNumber)"
swift-aql query shop-data.xmi --context ORD-004 "self.items->collect(i | i.quantity.toString() + ' x ' + i.product.name)"

# Aggregate: the number of orders, the units sold and the revenue.
swift-aql query shop-data.xmi "self.orders->size()"
swift-aql query shop-data.xmi "self.orders.items->collect(i | i.quantity)->sum()"
swift-aql query shop-data.xmi "self.orders.items->collect(i | i.quantity * i.unitPrice)->sum()"

# Output:
# ["Computers: 2", "Phones: 2", "Accessories: 3", "Audio: 3"]
# ["Wireless Keyboard", "Wireless Mouse", "USB-C Cable"]
# ["EAR-01"]
# ["ORD-001", "ORD-003"]
# ["1 x Laptop 16", "1 x Wireless Keyboard", "1 x Wireless Mouse"]
# 8
# 20
# 6815.0
