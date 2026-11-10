# Save the inferred metamodel as Ecore and list its classes with their supertypes
swift-ecore convert Arith.xtext Arith-xtext.ecore
swift-ecore query Arith-xtext.ecore --query classes

# Output:
# Conversion completed: Arith-xtext.ecore
# Classes
# =======
# * Program
# * Expr
# * Num (extends Expr)
# * Var (extends Expr)
# * BinOp (extends Expr)
# * Let (extends Expr)
