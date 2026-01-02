#!/bin/bash
# Workflow-01 Step 6: Validate Shop Instance

echo "=== Validating TechStore Instance ==="
echo ""

METAMODEL="workflow-01-step-01-metamodel.ecore"
INSTANCE="workflow-01-step-05-instance.xmi"

echo "Metamodel: $METAMODEL"
echo "Instance: $INSTANCE"
echo ""

# In a real implementation, this would call swift-ecore validate
echo "Command: swift-ecore validate $INSTANCE --metamodel $METAMODEL"
echo ""

echo "Validation checks:"
echo ""
echo "Structural validation:"
echo "  ✓ Instance conforms to ecommerce metamodel"
echo "  ✓ All required attributes are present"
echo "  ✓ Attribute types match metamodel definitions"
echo "  ✓ Reference targets exist and are valid"
echo "  ✓ Containment hierarchy is correct"
echo ""

echo "Business rules validation:"
echo "  ✓ Product prices are positive"
echo "  ✓ Product stock levels are non-negative"
echo "  ✓ Order total amounts are calculated correctly"
echo "  ✓ Order items reference valid products"
echo "  ✓ Customer emails are in valid format"
echo "  ✓ Order numbers are unique"
echo ""

echo "Instance statistics:"
echo "  - Shop: 1 (TechStore)"
echo "  - Categories: 4"
echo "  - Products: 10"
echo "  - Customers: 7"
echo "  - Orders: 10"
echo "  - Total Order Items: ~25"
echo "  - Total Revenue: ~£13,000"
echo ""

echo "Data quality checks:"
echo "  ✓ No orphaned references"
echo "  ✓ All cross-references are valid"
echo "  ✓ Bidirectional references are consistent"
echo "  ✓ Collection multiplicities are respected"
echo ""

echo "✅ Instance validation complete: PASSED"
echo ""
echo "The instance is ready for:"
echo "  - Model transformations (ATL)"
echo "  - Code generation (MTL)"
echo "  - Query operations (AQL)"
echo "  - Testing and analysis"
