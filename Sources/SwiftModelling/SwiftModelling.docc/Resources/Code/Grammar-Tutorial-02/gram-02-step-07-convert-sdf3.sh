# Import the SDF3 grammar with the default feature names and list the names
swift-ecore convert Arith.sdf3 Arith-sdf3-generated.ecore
grep -o 'name="[^"]*"' Arith-sdf3-generated.ecore

# Output:
# warning: Arith.sdf3: line 11, column 11: The constructor 'Program' of 'Program' clashes with another classifier and is named 'ProgramProgram'
# name="Arith"
# name="Program"
# name="ProgramProgram"
# name="id1"
# name="expr1"
# name="Expr"
# name="Num"
# name="int1"
# name="Var"
# name="id1"
# name="BinOp"
# name="expr1"
# name="op1"
# name="expr2"
# name="Let"
# name="id1"
# name="expr1"
# name="expr2"
# ...
# name="ID"
# name="INT"
