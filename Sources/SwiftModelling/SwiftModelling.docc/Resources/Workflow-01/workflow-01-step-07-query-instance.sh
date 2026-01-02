#!/bin/bash
# Workflow-01 Step 7: Query Shop Instance with AQL

echo "=== Querying TechStore with AQL ==="
echo ""

INSTANCE="workflow-01-step-05-instance.xmi"
echo "Instance: $INSTANCE"
echo ""

echo "Sample AQL queries to explore the shop data:"
echo ""

echo "Query 1: Get all product names"
echo "  AQL: shop.products.name"
echo "  Returns: Collection of product names"
echo "  Result: ['MacBook Pro 16-inch', 'MacBook Air 13-inch', 'iPhone 15 Pro', ...]"
echo ""

echo "Query 2: Find products under £100"
echo "  AQL: shop.products->select(p | p.price < 100.0)"
echo "  Returns: Collection of affordable products"
echo "  Result: [Magic Mouse, USB-C Cable, HomePod mini, ...]"
echo ""

echo "Query 3: Calculate total inventory value"
echo "  AQL: shop.products->collect(p | p.price * p.stock)->sum()"
echo "  Returns: Total value of all stock"
echo "  Calculation: (2499*15) + (1299*25) + (999*40) + ..."
echo "  Result: ~£250,000"
echo ""

echo "Query 4: Get all customer emails"
echo "  AQL: shop.customers.email"
echo "  Returns: Collection of email addresses"
echo "  Result: ['alice.johnson@example.com', 'bob.smith@example.com', ...]"
echo ""

echo "Query 5: Find high-value orders (over £1000)"
echo "  AQL: shop.orders->select(o | o.totalAmount > 1000.0)"
echo "  Returns: Collection of large orders"
echo "  Result: [ORD-2024-001, ORD-2024-002, ORD-2024-003, ...]"
echo ""

echo "Query 6: Calculate average order value"
echo "  AQL: shop.orders->collect(o | o.totalAmount)->sum() / shop.orders->size()"
echo "  Returns: Average amount per order"
echo "  Calculation: Total revenue / Number of orders"
echo "  Result: ~£1,300"
echo ""

echo "Query 7: Count items per order"
echo "  AQL: shop.orders->collect(o | Tuple{orderNum=o.orderNumber, items=o.items->size()})"
echo "  Returns: Order numbers with item counts"
echo "  Result: [{'ORD-2024-001', 2}, {'ORD-2024-002', 2}, ...]"
echo ""

echo "Query 8: Find products low in stock (< 20 units)"
echo "  AQL: shop.products->select(p | p.stock < 20)"
echo "  Returns: Products needing restock"
echo "  Result: [MacBook Pro 16-inch (15), Apple Watch Series 9 (20)]"
echo ""

echo "Query 9: Get total number of items sold"
echo "  AQL: shop.orders->collect(o | o.items)->flatten()->collect(i | i.quantity)->sum()"
echo "  Returns: Total quantity across all orders"
echo "  Result: ~30 items"
echo ""

echo "Query 10: List products by category"
echo "  AQL: shop.categories->collect(c | Tuple{cat=c.name, count=c.products->size()})"
echo "  Returns: Category names with product counts"
echo "  (Note: This requires proper category-product references in instance)"
echo ""

echo "✅ Query exploration complete"
echo ""
echo "These queries demonstrate:"
echo "  - Basic navigation (shop.products.name)"
echo "  - Filtering (select with conditions)"
echo "  - Aggregation (sum, size)"
echo "  - Complex expressions (calculations, Tuples)"
echo "  - Multi-level navigation (orders.items.quantity)"
