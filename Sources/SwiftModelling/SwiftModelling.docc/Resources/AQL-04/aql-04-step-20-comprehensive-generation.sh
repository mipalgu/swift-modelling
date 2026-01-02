#!/bin/bash
#
# Comprehensive Code Generation Example
# Demonstrates running MTL templates with AQL expressions
#
# This script shows how to invoke the swift-mtl tool to generate
# code from a web application model using the templates that
# demonstrate AQL expressions within MTL.
#

set -e

# Configuration
MODEL_FILE="webapp-instance.xmi"
METAMODEL_FILE="webapp-metamodel.ecore"
OUTPUT_DIR="./generated"

echo "=========================================="
echo "AQL in MTL - Comprehensive Generation"
echo "=========================================="
echo ""

# Check for required files
if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: Model file '$MODEL_FILE' not found"
    exit 1
fi

if [ ! -f "$METAMODEL_FILE" ]; then
    echo "Error: Metamodel file '$METAMODEL_FILE' not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# ============================================
# Step 1: Basic Template - Navigation Demo
# ============================================
echo "Step 1: Running basic template (navigation expressions)..."
swift-mtl generate \
    --template aql-04-step-03-basic-template.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR/docs"

echo "  Generated: README.md"
echo ""

# ============================================
# Step 2: Collection Operations Demo
# ============================================
echo "Step 2: Running collection operations template..."
swift-mtl generate \
    --template aql-04-step-05-collection-operations.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR/docs"

echo "  Generated: collection-ops.txt"
echo ""

# ============================================
# Step 3: Select and Reject Demo
# ============================================
echo "Step 3: Running select/reject template..."
swift-mtl generate \
    --template aql-04-step-06-select-and-reject.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR/docs"

echo "  Generated: filtering.txt"
echo ""

# ============================================
# Step 4: String Operations Demo
# ============================================
echo "Step 4: Running string operations template..."
swift-mtl generate \
    --template aql-04-step-10-string-operations.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR/docs"

echo "  Generated: string-ops.txt"
echo ""

# ============================================
# Step 5: Type Operations Demo
# ============================================
echo "Step 5: Running type operations template..."
swift-mtl generate \
    --template aql-04-step-11-type-operations.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR/docs"

echo "  Generated: type-ops.txt"
echo ""

# ============================================
# Step 6: File Generation Demo
# ============================================
echo "Step 6: Running file generation template..."
swift-mtl generate \
    --template aql-04-step-18-file-generation.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR"

echo "  Generated: README.md, *.model.swift, *ViewModel.swift"
echo "  Generated: Routes.swift, styles/app.css"
echo ""

# ============================================
# Step 7: Advanced Patterns (Full Application)
# ============================================
echo "Step 7: Running advanced patterns template..."
swift-mtl generate \
    --template aql-04-step-19-advanced-patterns.mtl \
    --model "$MODEL_FILE" \
    --metamodel "$METAMODEL_FILE" \
    --output "$OUTPUT_DIR"

echo "  Generated: AppConfiguration.swift"
echo "  Generated: schema.sql"
echo "  Generated: APIRoutes.swift"
echo "  Generated: ViewModels/*.swift"
echo "  Generated: Validation.swift"
echo ""

# ============================================
# Summary of Generated Files
# ============================================
echo "=========================================="
echo "Generation Complete!"
echo "=========================================="
echo ""
echo "Generated file structure:"
echo ""

# Display generated structure (if tree is available)
if command -v tree &> /dev/null; then
    tree "$OUTPUT_DIR"
else
    find "$OUTPUT_DIR" -type f | sort | while read -r file; do
        echo "  $file"
    done
fi

echo ""
echo "Key AQL features demonstrated:"
echo "  - Navigation: app.pages, entity.attributes"
echo "  - Collection ops: ->size(), ->select(), ->reject()"
echo "  - Quantifiers: ->exists(), ->forAll()"
echo "  - String ops: .toUpperCase(), .substituteAll()"
echo "  - Type ops: oclIsTypeOf(), oclAsType()"
echo "  - Conditionals: if-then-else expressions"
echo "  - Let bindings: [let x = expression]"
echo "  - Sorting: ->sortedBy()"
echo "  - Arithmetic: +, -, *, /, ->sum()"
echo ""

# ============================================
# AQL Expression Examples Summary
# ============================================
echo "=========================================="
echo "AQL Expression Quick Reference"
echo "=========================================="
echo ""
echo "Navigation:"
echo "  app.pages                    - Access collection"
echo "  page.components              - Chained navigation"
echo "  comp.oclAsType(Form).fields  - Type cast navigation"
echo ""
echo "Filtering:"
echo "  ->select(p | p.requiresAuth)       - Keep matching"
echo "  ->reject(a | a.isPrimaryKey)       - Exclude matching"
echo "  ->exists(a | a.isPrimaryKey)       - Any match?"
echo "  ->forAll(a | a.name <> null)       - All match?"
echo ""
echo "Transformation:"
echo "  ->collect(e | e.name)              - Map to values"
echo "  ->sortedBy(e | e.name)             - Order by key"
echo "  ->flatten()                        - Flatten nested"
echo ""
echo "Aggregation:"
echo "  ->size()                           - Count elements"
echo "  ->sum()                            - Sum numbers"
echo "  ->first(), ->last()                - Get endpoints"
echo ""
echo "String Operations:"
echo "  .toUpperCase(), .toLowerCase()     - Case conversion"
echo "  .substituteAll('a', 'b')           - Replace all"
echo "  .startsWith(), .endsWith()         - Prefix/suffix test"
echo ""
echo "Type Operations:"
echo "  .oclIsTypeOf(Form)                 - Exact type check"
echo "  .oclIsKindOf(Component)            - Inheritance check"
echo "  .oclAsType(Form)                   - Cast to type"
echo ""
echo "Conditional Expressions:"
echo "  if cond then val1 else val2 endif  - Inline conditional"
echo ""
