# Check the source and target metamodels
swift-ecore validate Source.ecore

# Output:
# Validation completed successfully

swift-ecore validate Target.ecore

# Output:
# Validation completed successfully

# Check the sample model against the source metamodel
swift-ecore validate source.xmi --metamodel Source.ecore

# Output:
# Validation completed successfully

# Transform the sample model with the complete transformation
swift-atl transform OptimisationExample.atl --source IN=source.xmi --target OUT=target.xmi

# Output (the time varies):
# Transformation completed successfully in 5.259ms
