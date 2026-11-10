# Look at the metamodel that the Xtext grammar infers
swift-ecore inspect Arith.xtext --detail full

# Output:
# Metamodel: Arith.xtext (Xtext)
# ==============================
#
# Package arith
#   Namespace URI: http://www.example.org/arith
#   Namespace prefix: arith
#   Classes: 6
#   Enumerations: 1
#   Data types: 0
#
#   Enumeration Op
#     Add = 0
#     Sub = 1
#     Mul = 2
#     Div = 3
#
#   Class Program
#     Attributes:
#       title: EString [0..1]
#     References:
#       statements: Expr [0..*], containment
#
#   Class Expr
#
#   Class Num extends Expr
#     Attributes:
#       value: EInt [0..1]
#
#   Class Var extends Expr
#     Attributes:
#       name: EString [0..1]
#
#   Class BinOp extends Expr
#     Attributes:
#       operator: Op [0..1]
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
