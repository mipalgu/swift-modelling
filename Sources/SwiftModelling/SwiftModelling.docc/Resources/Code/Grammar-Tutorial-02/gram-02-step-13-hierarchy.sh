# Show the inheritance of the Xtext import: supertypes, subclasses and inherited features
swift-ecore inspect Arith-xtext.ecore --show-supertypes

# Output:
# Metamodel: Arith-xtext.ecore (Ecore)
# ====================================
# ...
#   Class Expr
#     Subclasses: Num, Var, BinOp, Let
#
#   Class Num extends Expr
#   Class Var extends Expr
#   Class BinOp extends Expr
#   Class Let extends Expr
#
# Inheritance hierarchy:
#   Program
#   Expr
#     Num
#     Var
#     BinOp
#     Let
