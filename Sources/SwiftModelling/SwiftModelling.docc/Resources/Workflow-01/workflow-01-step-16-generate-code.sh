# Check the syntax and structure of the three templates.
swift-mtl validate GenerateSwiftClasses.mtl GenerateJSONAPI.mtl GenerateDocumentation.mtl

# Output:
# Valid: 3
# Errors: 0

# Generate the Swift API, the JSON schema and data, and the documentation
# from the sales report.
swift-mtl generate GenerateSwiftClasses.mtl --metamodel Reporting.ecore \
    --model sales-report.xmi --output generated/swift
swift-mtl generate GenerateJSONAPI.mtl --metamodel Reporting.ecore \
    --model sales-report.xmi --output generated/json
swift-mtl generate GenerateDocumentation.mtl --metamodel Reporting.ecore \
    --model sales-report.xmi --output generated/docs

# Output:
# Generation complete
# Generation complete
# Generation complete

# The generated artefacts and their sizes in lines.
wc -l generated/swift/SalesReportAPI.swift generated/json/sales-report.schema.json \
    generated/json/sales-report.json generated/docs/sales-report.md

# Output:
# 142 generated/swift/SalesReportAPI.swift
# 52 generated/json/sales-report.schema.json
# 31 generated/json/sales-report.json
# 49 generated/docs/sales-report.md
# 274 total
