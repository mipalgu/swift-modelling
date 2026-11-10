# Look at the metamodel that the Stratego signature describes
swift-ecore inspect Arith-sig.str --detail full

# Output:
# warning: Arith-sig.str: line 6, column 5: The constructor 'Program' of 'Program' clashes with another classifier and is named 'ProgramProgram'
# warning: Arith-sig.str: line 6, column 15: The sort 'ID' is not defined in this module; it is assumed to be lexical
# warning: Arith-sig.str: line 7, column 15: The sort 'INT' is not defined in this module; it is assumed to be lexical
# Metamodel: Arith-sig.str (SDF3)
# ===============================
#
# Package Arith_sig
#   Namespace URI: urn:sdf3:Arith_sig
#   Namespace prefix: arith_sig
#   Classes: 12 (3 abstract)
#   Enumerations: 0
#   Data types: 2
#
#   Data type ID (java.lang.String)
#
#   Data type INT (java.lang.String)
#
#   Abstract class Program
#
#   Class ProgramProgram extends Program
#     Attributes:
#       id1: ID [0..1]
#     References:
#       expr1: Expr [0..*], containment
# ...
#   Class BinOp extends Expr
#     References:
#       expr1: Expr [1..1], containment
#       op1: Op [1..1], containment
#       expr2: Expr [1..1], containment
# ...
#   Abstract class Op
#   Class Add extends Op
#   Class Sub extends Op
#   Class Mul extends Op
#   Class Div extends Op
