# Check the source metamodel
swift-ecore validate Source.ecore

# Output:
# Validation completed successfully

# Check the sample garden against the source metamodel
swift-ecore validate source.xmi --metamodel Source.ecore

# Output:
# Validation completed successfully

# Evaluate the query over the sample garden
# Expected error: the Garden has no parent, so the helper cannot join its label
swift-atl query ParentLabels.atl --source source.xmi

# Output:
# Query failed: Invalid operation: Binary operation requires non-nil operands
