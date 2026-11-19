# Check the two source metamodels and the target metamodel
swift-ecore validate ModelA.ecore

# Output:
# Validation completed successfully

swift-ecore validate ModelB.ecore

# Output:
# Validation completed successfully

swift-ecore validate Target.ecore

# Output:
# Validation completed successfully

# Check each sample model against its metamodel
swift-ecore validate modela.xmi --metamodel ModelA.ecore

# Output:
# Validation completed successfully

swift-ecore validate modelb.xmi --metamodel ModelB.ecore

# Output:
# Validation completed successfully

# Transform both sample models, with one --source option for each source model
swift-atl transform MultiModelExample.atl --source INA=modela.xmi --source INB=modelb.xmi --target OUT=target.xmi

# Output (the time varies):
# Transformation completed successfully in 5.854ms
