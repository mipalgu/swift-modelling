# Save the metamodel that the Langium grammar infers, and show its features
swift-ecore convert Arith.langium Arith-langium.ecore
swift-ecore inspect Arith-langium.ecore --detail full

# Output:
# Conversion completed: Arith-langium.ecore
# Metamodel: Arith-langium.ecore (Ecore)
# ======================================
#
# Package Arith
#   Namespace URI: urn:langium:Arith
#   Namespace prefix: arith
#   Classes: 6 (1 abstract)
#   Enumerations: 0
#   Data types: 0
#
#   Class Program
#     Attributes:
#       title: EString [0..1]
#     References:
#       statements: Expr [0..*], containment
#
#   Abstract class Expr
#
#   Class Num extends Expr
#     Attributes:
#       value: EDouble [0..1]
#
#   Class Var extends Expr
#     Attributes:
#       name: EString [0..1]
#
#   Class BinOp extends Expr
#     Attributes:
#       operator: EString [0..1]
#     References:
#       left: Expr [0..1], containment
#       right: Expr [0..1], containment
#
#   Class Let extends Expr
#     Attributes:
#       name: EString [0..1]
#     References:
#       init: Expr [0..1], containment
#       body: Expr [0..1], containment
