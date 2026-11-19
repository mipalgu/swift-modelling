# Check the target metamodel
swift-ecore validate Catalog.ecore

# Output:
# Validation completed successfully

# Check the sample university against the source metamodel
swift-ecore validate university.xmi --metamodel University.ecore

# Output:
# Validation completed successfully

# Transform the sample university with the complete transformation
swift-atl transform UniversityTransform.atl --source IN=university.xmi --target OUT=catalog.xmi

# Output (the time varies):
# Transformation completed successfully in 4.134ms
