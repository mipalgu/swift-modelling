cd refactoring

# Two more monthly exports of the legacy system, with the usual problems:
# a status with a trailing space, a lower-case payment method, and a
# repeat customer whose e-mail address is typed in upper case.
cat > legacy/orders-2024-02.xmi <<'XMI'
<?xml version="1.0" encoding="UTF-8"?>
<legacy:Store xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:legacy="http://www.example.org/legacy/orders/1.0"
    name="Harbourside Electronics">
  <products code="LAPTOP-001" name="ProBook 15" desc="15-inch professional laptop"
      price="1299.99" category="Computers" stockQty="44" reorderLevel="10"
      warehouseLocation="A-12-3"/>
  <products code="PHONE-001" name="SmartPhone X" desc="Dual-SIM smartphone"
      price="899.0" category="Mobile" stockQty="117" reorderLevel="25"
      warehouseLocation="B-05-1"/>
  <products code="CASE-001" name="Laptop Sleeve 15" desc="Sleeve for 15-inch laptops"
      price="49.99" category="Accessories" stockQty="77" reorderLevel="20"
      warehouseLocation="C-02-1"/>
  <orders orderId="ORD-2024-006" orderDate="2024-02-03" status="delivered "
      customerName="Sarah Johnson" customerEmail="S.Johnson@example.org"
      customerPhone="+61 3 7010 4321"
      shippingAddress="4 Business Park Rd, Melbourne VIC 3000, Australia"
      billingAddress="PO Box 789, Melbourne VIC 3001, Australia"
      totalAmount="899.0" taxAmount="89.9" paymentMethod="invoice"
      lastModified="2024-02-06">
    <items productCode="PHONE-001" productName="SmartPhone X" qty="1"
        unitPrice="899.0" lineTotal="899.0"/>
  </orders>
  <orders orderId="ORD-2024-007" orderDate="2024-02-11" status="PROCESSING"
      customerName="Mei Chen" customerEmail="mei.chen@example.com"
      customerPhone="+61 8 5550 2468"
      shippingAddress="8 Rundle Mall, Adelaide SA 5000, Australia"
      billingAddress="8 Rundle Mall, Adelaide SA 5000, Australia"
      totalAmount="1349.98" taxAmount="135.0" paymentMethod="CREDIT_CARD"
      cardLastFour="1881" lastModified="2024-02-11">
    <items productCode="LAPTOP-001" productName="ProBook 15" qty="1"
        unitPrice="1299.99" lineTotal="1299.99"/>
    <items productCode="CASE-001" productName="Laptop Sleeve 15" qty="1"
        unitPrice="49.99" lineTotal="49.99"/>
  </orders>
</legacy:Store>
XMI

cat > legacy/orders-2024-03.xmi <<'XMI'
<?xml version="1.0" encoding="UTF-8"?>
<legacy:Store xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:legacy="http://www.example.org/legacy/orders/1.0"
    name="Harbourside Electronics">
  <products code="LAPTOP-002" name="UltraBook Air" desc="Lightweight laptop"
      price="999.99" category="Computers" stockQty="28" reorderLevel="8"
      warehouseLocation="A-12-4"/>
  <products code="CABLE-001" name="USB-C Cable" desc="2 m charging cable"
      price="19.99" category="Accessories" stockQty="430" reorderLevel="100"
      warehouseLocation="C-01-1"/>
  <orders orderId="ORD-2024-008" orderDate="2024-03-02" status="CANCELLED"
      customerName="Jane Doe" customerEmail="jane.doe@example.net"
      customerPhone="0491 570 156"
      shippingAddress="5/22 George St, Perth WA 6000"
      billingAddress="5/22 George St, Perth WA 6000"
      totalAmount="199.9" taxAmount="19.99" paymentMethod="PayPal"
      notes="Cancelled by the customer" lastModified="2024-03-03">
    <items productCode="CABLE-001" productName="USB-C Cable" qty="10"
        unitPrice="19.99" lineTotal="199.9"/>
  </orders>
  <orders orderId="ORD-2024-009" orderDate="2024-03-15" status="Pending"
      customerName="Tom Nguyen" customerEmail="tom.nguyen@example.net"
      customerPhone="+61 2 5550 7777"
      shippingAddress="21 Crown St, Surry Hills NSW 2010, Australia"
      billingAddress="21 Crown St, Surry Hills NSW 2010, Australia"
      totalAmount="1019.98" taxAmount="102.0" paymentMethod="BANK_TRANSFER"
      lastModified="2024-03-15">
    <items productCode="LAPTOP-002" productName="UltraBook Air" qty="1"
        unitPrice="999.99" lineTotal="999.99"/>
    <items productCode="CABLE-001" productName="USB-C Cable" qty="1"
        unitPrice="19.99" lineTotal="19.99"/>
  </orders>
</legacy:Store>
XMI

# All three exports must load with the legacy metamodel.
swift-ecore validate legacy/*.xmi -m LegacyOrders.ecore
# Output:
# legacy/orders-2024-01.xmi: valid
# legacy/orders-2024-02.xmi: valid
# legacy/orders-2024-03.xmi: valid
# Validated 3 files: 3 valid, 0 invalid
