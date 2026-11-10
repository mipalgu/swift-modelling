# Show the classes that the sum type became, with their supertypes
swift-ecore query Arith-asdl.ecore --query hierarchy

# Output:
# Class Hierarchy
# ===============
# |-- expr (abstract)
# |   |-- Num
# |   |-- Var
# |   |-- BinOp
# |   +-- Let
# +-- program
