# Check the extended metamodel
swift-ecore validate Report.ecore

# Output:
# Validation completed successfully

# Transform the sample project with the two lazy rules
swift-atl transform ProjectTransform.atl --source IN=project.xmi --target OUT=report.xmi

# Output (the time varies):
# Transformation completed successfully in 42.247ms
