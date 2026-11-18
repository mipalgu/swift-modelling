# Check the metamodel with the highlights
swift-ecore validate Report.ecore

# Output:
# Validation completed successfully

# Transform the sample project with the lazy rule that is called twice
swift-atl transform ProjectHighlights.atl --source IN=project.xmi --target OUT=report-highlights.xmi

# Output (the time varies):
# Transformation completed successfully in 8.389ms
