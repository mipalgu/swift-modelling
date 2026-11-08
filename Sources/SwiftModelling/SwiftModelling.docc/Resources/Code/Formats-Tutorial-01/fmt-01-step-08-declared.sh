# Keep the data types that the KM3 text declares instead of mapping them
swift-ecore convert Families.km3 Families-declared.ecore --km3-primitives declared
swift-ecore inspect Families-declared.ecore --show-attributes

# Output:
# warning: Families.km3: The package 'PrimitiveTypes' has no 'nsURI' and is registered under its name in this resource set
# Metamodel: Families-declared.ecore (Ecore)
# ...
#   Class Family
#     Attributes:
#       lastName: String [1..1]
#
#   Class Member
#     Attributes:
#       firstName: String [1..1]
#
# Package PrimitiveTypes
# ...
#   Data types: 1
#
#   Data type String
