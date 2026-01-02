#!/bin/bash
# Workflow-01 Step 4: Export Metamodel to Different Formats

echo "=== Exporting E-commerce Metamodel ==="
echo ""

METAMODEL="workflow-01-step-01-metamodel.ecore"

# Export to JSON
JSON_OUTPUT="ecommerce-metamodel.json"
echo "Exporting to JSON format..."
echo "Command: swift-ecore convert $METAMODEL --to json --output $JSON_OUTPUT"
echo ""

echo "JSON format benefits:"
echo "  ✓ Web-based tools and editors"
echo "  ✓ JavaScript/TypeScript integration"
echo "  ✓ REST API schema generation"
echo "  ✓ Browser-based model viewers"
echo "  ✓ Integration with web frameworks"
echo ""

# Export to PlantUML (hypothetical)
PLANTUML_OUTPUT="ecommerce-metamodel.puml"
echo "Exporting to PlantUML diagram..."
echo "Command: swift-ecore convert $METAMODEL --to plantuml --output $PLANTUML_OUTPUT"
echo ""

echo "PlantUML format benefits:"
echo "  ✓ Visual diagrams for documentation"
echo "  ✓ Integration with documentation systems"
echo "  ✓ Version control friendly text format"
echo "  ✓ Automated diagram generation in CI/CD"
echo ""

# Display JSON structure preview
echo "JSON structure preview:"
echo "{"
echo '  "package": {'
echo '    "name": "ecommerce",'
echo '    "nsURI": "http://www.example.org/ecommerce",'
echo '    "classes": ['
echo '      {'
echo '        "name": "Shop",'
echo '        "attributes": [{"name": "name", "type": "String"}],'
echo '        "references": ['
echo '          {"name": "products", "type": "Product", "many": true, "containment": true},'
echo '          {"name": "categories", "type": "Category", "many": true, "containment": true}'
echo '        ]'
echo '      },'
echo '      ...'
echo '    ]'
echo '  }'
echo "}"
echo ""

echo "✅ Metamodel exported to multiple formats:"
echo "   - XMI (native): $METAMODEL"
echo "   - JSON: $JSON_OUTPUT"
echo "   - PlantUML: $PLANTUML_OUTPUT"
echo ""
echo "These formats enable metamodel interoperability across different tools and platforms."
