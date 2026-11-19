# Check the source metamodel and the two target metamodels
swift-ecore validate Source.ecore

# Output:
# Validation completed successfully

swift-ecore validate TargetA.ecore

# Output:
# Validation completed successfully

swift-ecore validate TargetB.ecore

# Output:
# Validation completed successfully

# Check the sample model against the source metamodel
swift-ecore validate source.xmi --metamodel Source.ecore

# Output:
# Validation completed successfully

# Transform the sample model, with one --target option for each target model
swift-atl transform MultiModelExample.atl --source IN=source.xmi --target OUTA=targeta.xmi --target OUTB=targetb.xmi

# Output (the time varies):
# Transformation completed successfully in 2.242ms
