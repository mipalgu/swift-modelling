# Look at the metamodel that the ASDL module describes
swift-ecore inspect Arith.asdl --detail full

# Output:
# Metamodel: Arith.asdl (ASDL)
# ============================
#
# Package Arith
#   Namespace URI: urn:asdl:Arith
#   Namespace prefix: arith
#   Classes: 6 (1 abstract)
#   Enumerations: 1
#   Data types: 0
#
#   Enumeration op
#     Add = 0
#     Sub = 1
#     Mul = 2
#     Div = 3
#
#   Abstract class expr
#
#   Class Num extends expr
#     Attributes:
#       value: EInt [1..1]
#
#   Class Var extends expr
#     Attributes:
#       name: EString [1..1]
#
#   Class BinOp extends expr
#     Attributes:
#       operator: op [1..1]
#     References:
#       left: expr [1..1], containment
#       right: expr [1..1], containment
#
#   Class Let extends expr
#     Attributes:
#       name: EString [1..1]
#     References:
#       init: expr [1..1], containment
#       body: expr [1..1], containment
#
#   Class program
#     Attributes:
#       title: EString [0..1]
#     References:
#       statements: expr [0..*], containment
