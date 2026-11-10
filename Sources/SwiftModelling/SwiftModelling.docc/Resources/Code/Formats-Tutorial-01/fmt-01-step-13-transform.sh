# Run the transformation with the KM3 metamodels in place of the -- @path directives
swift-atl transform Families2Persons.atl \
  --source sample-Families.xmi --source-metamodel Families.km3 \
  --target output-Persons.xmi --target-metamodel Persons.km3

# Output (the time varies):
# Transformation completed successfully in 16.244ms
