# Check the complete metamodel
swift-ecore validate Report.ecore

# Output:
# Validation completed successfully

# Transform the sample project with the complete transformation
swift-atl transform ProjectTransform.atl --source IN=project.xmi --target OUT=report.xmi

# Output (the time varies):
# Transformation completed successfully in 11.840ms
