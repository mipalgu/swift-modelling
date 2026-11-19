# Check the metamodel
swift-ecore validate Model.ecore

# Output:
# Validation completed successfully

# Check the sample model against the metamodel
swift-ecore validate model.xmi --metamodel Model.ecore

# Output:
# Validation completed successfully

# Refine the sample model with the complete refactoring
swift-atl transform RefiningExample.atl --source IN=model.xmi --target OUT=refined.xmi

# Output (the time varies):
# Transformation completed successfully in 2.940ms
