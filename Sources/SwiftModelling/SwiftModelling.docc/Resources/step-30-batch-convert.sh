for file in *.xmi; do
  swift-ecore convert "$file" "${file%.xmi}.json" --metamodel Company.ecore --force
done

# Output:
# Conversion completed: company-model.json
# Conversion completed: company-roundtrip.json
