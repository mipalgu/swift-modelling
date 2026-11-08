# Compare the Xtext import with the ASDL import in full
swift-ecore compare Arith-asdl.ecore Arith-xtext.ecore

# Output:
# Comparing metamodels: Arith-asdl.ecore -> Arith-xtext.ecore
# ~ package Arith name: Arith -> arith
# ~ package Arith nsURI: urn:asdl:Arith -> http://www.example.org/arith
# - class expr: abstract
# ~ class Num supertypes: expr -> Expr
# ~ attribute Num.value multiplicity: [1..1] -> [0..1]
# ~ class Var supertypes: expr -> Expr
# ~ attribute Var.name multiplicity: [1..1] -> [0..1]
# ~ class BinOp supertypes: expr -> Expr
# ~ reference BinOp.left type: expr -> Expr
# ~ reference BinOp.left multiplicity: [1..1] -> [0..1]
# ~ attribute BinOp.operator type: op -> Op
# ~ attribute BinOp.operator multiplicity: [1..1] -> [0..1]
# ~ reference BinOp.right type: expr -> Expr
# ~ reference BinOp.right multiplicity: [1..1] -> [0..1]
# ~ class Let supertypes: expr -> Expr
# ~ attribute Let.name multiplicity: [1..1] -> [0..1]
# ~ reference Let.init type: expr -> Expr
# ~ reference Let.init multiplicity: [1..1] -> [0..1]
# ~ reference Let.body type: expr -> Expr
# ~ reference Let.body multiplicity: [1..1] -> [0..1]
# - enumeration op: Add, Sub, Mul, Div
# - class program
# + class Program
# + class Expr
# + enumeration Op: Add, Sub, Mul, Div
# 25 differences: 3 added, 3 removed, 19 changed
