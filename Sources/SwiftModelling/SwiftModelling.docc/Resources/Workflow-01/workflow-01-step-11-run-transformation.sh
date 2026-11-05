# Check the rules and helpers of the transformation against both metamodels.
swift-atl transform ECommerce2Reporting.atl --validate-only \
    --source-metamodel ECommerce.ecore --target-metamodel Reporting.ecore

# Output:
# Transformation 'ECommerce2Reporting' is valid
# Metamodels: Reporting (http://www.example.org/reporting), Shop (http://www.example.org/shop)
# Rules: 4 matched, 0 called; helpers: 6

# Transform the shop data into a sales report.
swift-atl transform ECommerce2Reporting.atl \
    --source shop-data.xmi --source-metamodel ECommerce.ecore \
    --target sales-report.xmi --target-metamodel Reporting.ecore

# Output:
# Transformation completed successfully

# One report with a metric for each category, customer and product.
swift-ecore inspect sales-report.xmi --metamodel Reporting.ecore

# Output:
# Model: sales-report.xmi (XMI)
# ...
# Objects: 20
# ...
# CategoryMetric: 4
# CustomerMetric: 5
# ProductMetric: 10
# SalesReport: 1
