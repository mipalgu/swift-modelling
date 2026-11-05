#!/bin/bash
#
# Comprehensive Code Generation Example
# Runs every template of this tutorial on the web application model
#
# Each template demonstrates a group of AQL expressions within MTL
# and writes one file into the output directory.
#

set -e

# Configuration
MODEL_FILE="webapp-model.xmi"
METAMODEL_FILE="WebApp.ecore"
OUTPUT_DIR="./generated"
TEMPLATES=(
    BasicGeneration.mtl
    PropertyAccess.mtl
    NavigationTemplate.mtl
    SafeNavigation.mtl
    CollectionIteration.mtl
    FilteredIteration.mtl
    CollectTransform.mtl
    ConditionalLogic.mtl
    ComplexConditions.mtl
    QuantifierConditions.mtl
    LetBindings.mtl
    QueryLibrary.mtl
    CrossReferences.mtl
)

echo "=========================================="
echo "AQL in MTL - Comprehensive Generation"
echo "=========================================="
echo ""

# Check for required files
for file in "$MODEL_FILE" "$METAMODEL_FILE" "${TEMPLATES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: '$file' not found; save it from the earlier steps"
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"

# Run each template with the model and its metamodel
for template in "${TEMPLATES[@]}"; do
    echo "Running $template"
    swift-mtl generate \
        --template "$template" \
        --model "$MODEL_FILE" \
        --metamodel "$METAMODEL_FILE" \
        --output "$OUTPUT_DIR"
done

echo ""
echo "=========================================="
echo "Generation Complete"
echo "=========================================="
echo ""
echo "Generated files:"
find "$OUTPUT_DIR" -type f \( -name '*.md' -o -name '*.txt' \) | sort

echo ""
echo "Key AQL features demonstrated:"
echo "  - Navigation: app.pages, entity.attributes"
echo "  - Collection operations: ->size(), ->select(), ->reject(), ->collect()"
echo "  - Quantifiers: ->exists(), ->forAll()"
echo "  - Conditionals: [if] blocks and if-then-else expressions"
echo "  - Let bindings: [let x = expression]"
echo "  - Templates as queries: reusable templates called from other templates"

# Output (excerpt):
# AQL in MTL - Comprehensive Generation
# Running BasicGeneration.mtl
# ✓ Generation complete
# Running LetBindings.mtl
# ✓ Generation complete
# Running QueryLibrary.mtl
# ✓ Generation complete
# Running CrossReferences.mtl
# ✓ Generation complete
# Generation Complete
# Generated files:
# ./generated/cross-references.txt
# ./generated/let-bindings.txt
# ./generated/query-library-demo.txt
