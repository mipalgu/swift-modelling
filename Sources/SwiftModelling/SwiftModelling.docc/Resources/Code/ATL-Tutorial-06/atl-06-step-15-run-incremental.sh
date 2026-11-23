# Check the target metamodel
swift-ecore validate Target.ecore

# Output:
# Validation completed successfully

# Run the single rule on the sample garden and watch its trace
swift-atl transform DebugExample.atl --source IN=source.xmi --target OUT=target.xmi

# Output (the time varies):
# SimpleTransform name: 'Garden'
# SimpleTransform name: 'Vegetable Bed'
# SimpleTransform name: 'Herb Spiral'
# Transformation completed successfully in 1.648ms
