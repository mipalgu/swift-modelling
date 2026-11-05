# The report conforms to the reporting metamodel, including its invariants:
# the category sales add up to the revenue, the customer orders to the orders.
swift-ecore validate sales-report.xmi --metamodel Reporting.ecore

# Output:
# OCL invariants: 2 of 2 check(s) satisfied
# Validation completed successfully

# The key figures of the report.
swift-aql query sales-report.xmi "self.totalRevenue"
swift-aql query sales-report.xmi "self.categoryMetrics->collect(m | m.categoryName + ': ' + m.totalSales.toString())"
swift-aql query sales-report.xmi "self.customerMetrics->sortedBy(m | -m.totalSpent)->first().customerName"

# Output:
# 6815.0
# ["Computers: 4200.0", "Phones: 1700.0", "Accessories: 345.0", "Audio: 570.0"]
# "Chloe Martin"

# Recompute the revenue and the units sold from the shop data, and compare
# them with the report: the script stops if a figure differs.
shop_revenue=$(swift-aql query shop-data.xmi "self.orders.items->collect(i | i.quantity * i.unitPrice)->sum()")
report_revenue=$(swift-aql query sales-report.xmi "self.totalRevenue")
test "$shop_revenue" = "$report_revenue"
shop_units=$(swift-aql query shop-data.xmi "self.orders.items->collect(i | i.quantity)->sum()")
report_units=$(swift-aql query sales-report.xmi "self.productMetrics->collect(p | p.unitsSold)->sum()")
test "$shop_units" = "$report_units"
echo "Shop data and report agree: revenue $report_revenue, units sold $report_units"

# Output:
# Shop data and report agree: revenue 6815.0, units sold 20
