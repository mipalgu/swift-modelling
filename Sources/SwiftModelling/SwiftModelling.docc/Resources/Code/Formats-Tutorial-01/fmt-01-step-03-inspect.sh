# Show the packages, classes and features of the KM3 metamodel
swift-ecore inspect Families.km3 --detail full

# Output:
# Metamodel: Families.km3 (KM3)
# =============================
#
# Package Families
#   Namespace URI: http://www.example.org/families
#   Namespace prefix: families
#   Classes: 2
#   Enumerations: 0
#   Data types: 0
#
#   Class Family
#     Attributes:
#       lastName: EString [1..1]
#     References:
#       father: Member [1..1], containment, opposite Member.familyFather
#       mother: Member [1..1], containment, opposite Member.familyMother
#       sons: Member [0..*], containment, opposite Member.familySon
#       daughters: Member [0..*], containment, opposite Member.familyDaughter
#
#   Class Member
#     Attributes:
#       firstName: EString [1..1]
#     References:
#       familyFather: Family [0..1], container, opposite Family.father
#       familyMother: Family [0..1], container, opposite Family.mother
#       familySon: Family [0..1], container, opposite Family.sons
#       familyDaughter: Family [0..1], container, opposite Family.daughters
