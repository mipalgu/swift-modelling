# Save the imported metamodel as Ecore and check it
swift-ecore convert Arith.asdl Arith-asdl.ecore
swift-ecore validate Arith-asdl.ecore

# Output:
# Conversion completed: Arith-asdl.ecore
# Validation completed successfully
