doc=generated/docs/sales-report.md

# Every section of the documentation is present.
for section in "Key Figures" "Categories" "Customers" "Products" "Out of Stock"; do
    grep -q "^## $section\$" "$doc"
    echo "Section found: $section"
done

# Output:
# Section found: Key Figures
# Section found: Categories
# Section found: Customers
# Section found: Products
# Section found: Out of Stock

# Each table has one row for each metric of the report model: count the rows
# that end in a number, and compare them with what AQL counts in the model.
rows() {
    sed -n "/^## $1\$/,/^## /p" "$doc" | grep -c ' [0-9][0-9.]* |$'
}
test "$(rows Categories)" = "$(swift-aql query sales-report.xmi 'self.categoryMetrics->size()')"
test "$(rows Customers)" = "$(swift-aql query sales-report.xmi 'self.customerMetrics->size()')"
test "$(rows Products)" = "$(swift-aql query sales-report.xmi 'self.productMetrics->size()')"
echo "Table rows: $(rows Categories) categories, $(rows Customers) customers, $(rows Products) products"

# Output:
# Table rows: 4 categories, 5 customers, 10 products

# The key figures are those of the model, and no template expression was
# left unexpanded.
revenue=$(swift-aql query sales-report.xmi "self.totalRevenue")
grep "| Total revenue | $revenue |" "$doc"
if grep -n '\[' "$doc"; then
    echo "Unexpanded template text in $doc"
    exit 1
fi

# Output:
# | Total revenue | 6815.0 |
