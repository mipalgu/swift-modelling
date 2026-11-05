# Adaptive Code Generation Output Examples
# This script demonstrates running MTL templates with conditional logic

# Run the conditional template
swift-mtl generate \
  --template ConditionalLogic.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: conditional-logic.txt"

# Run the complex conditions template
swift-mtl generate \
  --template ComplexConditions.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: complex-conditions.txt"

# Run the quantifier conditions template
swift-mtl generate \
  --template QuantifierConditions.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: quantifier-conditions.txt"

# View generated output
echo ""
echo "=== Conditional Logic Output ==="
cat ./generated/conditional-logic.txt | head -40

echo ""
echo "=== Complex Conditions Output ==="
cat ./generated/complex-conditions.txt | head -40

echo ""
echo "=== Quantifier Conditions Output ==="
cat ./generated/quantifier-conditions.txt | head -90

# Output (excerpt):
# === Conditional Logic Output ===
# Page access levels:
# - Dashboard: Protected
# - Login: Public
# - Register: Public
# Entity complexity analysis:
# - User: 6 attributes - Medium
# - Task: 7 attributes - Complex
# - Project: 6 attributes - Medium
# - Comment: 3 attributes - Simple
# === Quantifier Conditions Output ===
# Application validation summary:
# Schema validation:
#   [PASS] Every entity has a primary key
# Security validation:
#   [INFO] Mixed access - both public and protected pages
# UI completeness:
#   [PASS] All pages have components
