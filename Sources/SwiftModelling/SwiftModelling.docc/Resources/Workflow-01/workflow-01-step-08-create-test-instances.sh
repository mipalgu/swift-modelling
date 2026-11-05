#!/bin/bash
# Creates small test instances of the shop metamodel in test-instances/.
set -e
mkdir -p test-instances

# A new shop, created from the metamodel: one Shop object without any values.
swift-ecore create --metamodel ECommerce.ecore --root-class Shop \
    --output test-instances/new-shop.xmi --force

# A shop that has a name but no products, customers or orders yet.
cat > test-instances/empty-shop.xmi <<'XMI'
<?xml version="1.0" encoding="UTF-8"?>
<shop:Shop xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:shop="http://www.example.org/shop" name="Opening Soon"/>
XMI

# The smallest complete shop: one product, one customer and one order.
cat > test-instances/single-order.xmi <<'XMI'
<?xml version="1.0" encoding="UTF-8"?>
<shop:Shop xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:shop="http://www.example.org/shop" name="Corner Shop">
  <categories xmi:id="books" name="Books"/>
  <products xmi:id="BK-01" name="Notebook" sku="BK-01" price="12.5" stock="3" category="books"/>
  <customers xmi:id="sam" name="Sam Lee" email="sam@example.com"/>
  <orders orderNumber="T-001" date="2026-04-01" paymentMethod="CASH" customer="sam">
    <items quantity="2" unitPrice="12.5" product="BK-01"/>
  </orders>
</shop:Shop>
XMI

# A shop that breaks the business rules: a negative price, an email address
# without @, an order item with a quantity of zero and an order without items.
cat > test-instances/invalid-shop.xmi <<'XMI'
<?xml version="1.0" encoding="UTF-8"?>
<shop:Shop xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:shop="http://www.example.org/shop" name="Broken Shop">
  <categories xmi:id="misc" name="Miscellaneous"/>
  <products xmi:id="GIFT" name="Gift Card" sku="GIFT" price="-10.0" stock="5" category="misc"/>
  <customers xmi:id="kim" name="Kim Park" email="kim.example.com"/>
  <orders orderNumber="T-002" date="2026-04-02" paymentMethod="CARD" customer="kim">
    <items quantity="0" unitPrice="10.0" product="GIFT"/>
  </orders>
  <orders orderNumber="T-003" date="2026-04-03" paymentMethod="CARD" customer="kim"/>
</shop:Shop>
XMI

ls test-instances
