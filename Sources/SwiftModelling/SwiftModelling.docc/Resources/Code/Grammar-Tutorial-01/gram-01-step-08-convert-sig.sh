# Save the imported signature as Ecore and list its class names and features
swift-ecore convert Arith-sig.str Arith-sig.ecore
grep -o 'name="[^"]*"' Arith-sig.ecore

# Output:
# warning: Arith-sig.str: line 6, column 5: The constructor 'Program' of 'Program' clashes with another classifier and is named 'ProgramProgram'
# ...
# name="Arith_sig"
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
# ...
# name="ID"
# name="INT"
