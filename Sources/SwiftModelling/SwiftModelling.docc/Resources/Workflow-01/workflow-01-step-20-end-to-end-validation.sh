# Stop at the first command or check that fails.
set -e

# Run the whole chain again for the shop data and the valid test instances:
# validate, transform, validate the report, generate and type-check the Swift
# code, then compare the revenue in the source model with every artefact.
for model in shop-data.xmi test-instances/single-order.xmi test-instances/empty-shop.xmi; do
    out="e2e/$(basename "$model" .xmi)"
    mkdir -p "$out"
    echo "== $model"
    swift-ecore validate "$model" --metamodel ECommerce.ecore
    swift-atl transform ECommerce2Reporting.atl --quiet \
        --source "$model" --source-metamodel ECommerce.ecore \
        --target "$out/sales-report.xmi" --target-metamodel Reporting.ecore
    swift-ecore validate "$out/sales-report.xmi" --metamodel Reporting.ecore
    swift-mtl generate GenerateSwiftClasses.mtl --metamodel Reporting.ecore \
        --model "$out/sales-report.xmi" --output "$out/generated/swift"
    swift-mtl generate GenerateJSONAPI.mtl --metamodel Reporting.ecore \
        --model "$out/sales-report.xmi" --output "$out/generated/json"
    swift-mtl generate GenerateDocumentation.mtl --metamodel Reporting.ecore \
        --model "$out/sales-report.xmi" --output "$out/generated/docs"
    swiftc -typecheck "$out/generated/swift/SalesReportAPI.swift"

    # Adding 0.0 makes the sum a real number, also for a shop without orders.
    revenue=$(swift-aql query "$model" --metamodel ECommerce.ecore \
        "0.0 + self.orders.items->collect(i | i.quantity * i.unitPrice)->sum()")
    test "$(swift-aql query "$out/sales-report.xmi" 'self.totalRevenue')" = "$revenue"
    grep -q "totalRevenue: $revenue," "$out/generated/swift/SalesReportAPI.swift"
    grep -q "\"totalRevenue\": $revenue," "$out/generated/json/sales-report.json"
    grep -q "| Total revenue | $revenue |" "$out/generated/docs/sales-report.md"
    echo "Revenue $revenue agrees in the model, the report, Swift, JSON and Markdown"
done

# Output:
# == shop-data.xmi
# OCL invariants: 48 of 48 check(s) satisfied
# ...
# Revenue 6815.0 agrees in the model, the report, Swift, JSON and Markdown
# == test-instances/single-order.xmi
# ...
# Revenue 25.0 agrees in the model, the report, Swift, JSON and Markdown
# == test-instances/empty-shop.xmi
# ...
# Revenue 0.0 agrees in the model, the report, Swift, JSON and Markdown

# The chain is reproducible: the second run produced exactly the same report
# and artefacts as the steps before.
diff sales-report.xmi e2e/shop-data/sales-report.xmi
diff -r generated e2e/shop-data/generated
shasum -a 256 e2e/shop-data/generated/*/*.*

# Output:
# ...  e2e/shop-data/generated/docs/sales-report.md
# ...  e2e/shop-data/generated/json/sales-report.json
# ...  e2e/shop-data/generated/json/sales-report.schema.json
# ...  e2e/shop-data/generated/swift/SalesReportAPI.swift
