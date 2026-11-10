# Check the model against its metamodel, then export the metamodel and the model
swift-ecore validate office.xmi --metamodel Organisation.ecore
swift-ecore generate Organisation.ecore --language alloy --model office.xmi --output verification
ls verification

# Output:
# OCL invariants: 7 of 7 check(s) satisfied
# Validation completed successfully
# Generated 2 files in: .../verification
# office_instance.als
# organisation.als
