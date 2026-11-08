# Make a copy whose only problem is a last name in lower case, and validate it
sed 's/lastName="March"/lastName="march"/' sample-Families.xmi > families-lower.xmi
swift-epsilon evl validate families.evl --model Families=families-lower.xmi -m Families.ecore

# Output:
# warning: critique CapitalisedLastName on Family: Family march should start with a capital letter
#   fix: Capitalise march
# 0 errors, 1 warning
