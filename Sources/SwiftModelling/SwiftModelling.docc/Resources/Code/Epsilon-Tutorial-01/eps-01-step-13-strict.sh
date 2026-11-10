# Validate the same copy again, failing on critiques as well
# Expected error: with --strict, the unsatisfied critique fails validation with status 2
swift-epsilon evl validate families.evl --model Families=families-lower.xmi -m Families.ecore --strict

# Output:
# warning: critique CapitalisedLastName on Family: Family march should start with a capital letter
#   fix: Capitalise march
# 0 errors, 1 warning
