# Validate the copy with a missing first name and a last name in lower case
# Expected error: a constraint is not satisfied, so validation fails with status 2
swift-epsilon evl validate families.evl --model Families=families-errors.xmi -m Families.ecore

# Output:
# warning: critique CapitalisedLastName on Family: Family sailor should start with a capital letter
#   fix: Capitalise sailor
# error: constraint HasFirstName on Member: A member of family sailor has no first name
#   fix: Name the member Unknown
# 1 error, 1 warning
