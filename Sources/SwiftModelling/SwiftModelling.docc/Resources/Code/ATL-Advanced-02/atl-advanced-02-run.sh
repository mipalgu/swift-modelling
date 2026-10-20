# Run the Organisation2Directory transformation
swift-atl transform organisation2directory.atl \
  --source IN=sample-company.xmi \
  --target OUT=output-directory.xmi

# The metamodels are found through the -- @path directives in the
# transformation, which name organisation.ecore and directory.ecore beside it.
#
# Output (the time varies):
# Transformation completed successfully in 3.5ms
