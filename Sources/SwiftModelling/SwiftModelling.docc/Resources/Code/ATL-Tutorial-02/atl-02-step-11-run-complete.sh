# Check the target metamodel
swift-ecore validate Catalog.ecore

# Output:
# Validation completed successfully

# Check the sample library against the source metamodel
swift-ecore validate library.xmi --metamodel Library.ecore

# Output:
# Validation completed successfully

# Transform the sample library with the complete transformation
swift-atl transform LibraryTransform.atl --source IN=library.xmi --target OUT=catalog.xmi

# Output (the time varies):
# Transformation completed successfully in 60.698ms
