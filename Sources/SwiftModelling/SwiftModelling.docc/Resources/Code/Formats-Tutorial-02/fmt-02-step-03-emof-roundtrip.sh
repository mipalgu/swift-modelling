# Read the EMOF document back into Ecore and compare it with the original
swift-ecore convert Company.emof Company-roundtrip.ecore
swift-ecore compare Company.ecore Company-roundtrip.ecore

# Output:
# Conversion completed: Company-roundtrip.ecore
# Comparing metamodels: Company.ecore -> Company-roundtrip.ecore
# No differences
