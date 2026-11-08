# Import the grammar again, naming the features after the labels of the placeholders
swift-ecore convert Arith.sdf3 Arith-sdf3.ecore --sdf3-labels
grep -o 'name="[^"]*"' Arith-sdf3.ecore

# Output:
# warning: Arith.sdf3: line 11, column 11: The constructor 'Program' of 'Program' clashes with another classifier and is named 'ProgramProgram'
# name="Arith"
# name="Program"
# name="ProgramProgram"
# name="title"
# name="statements"
# name="Expr"
# name="Num"
# name="value"
# name="Var"
# name="name"
# name="BinOp"
# name="left"
# name="operator"
# name="right"
# name="Let"
# name="name"
# name="init"
# name="body"
# ...
# name="ID"
# name="INT"
