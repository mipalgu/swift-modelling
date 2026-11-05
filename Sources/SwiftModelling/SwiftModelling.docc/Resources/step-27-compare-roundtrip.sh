swift-ecore convert company-roundtrip.xmi company-roundtrip.json --metamodel Company.ecore
diff company-model.json company-roundtrip.json && echo "No differences"

# Output:
# Conversion completed: company-roundtrip.json
# No differences
