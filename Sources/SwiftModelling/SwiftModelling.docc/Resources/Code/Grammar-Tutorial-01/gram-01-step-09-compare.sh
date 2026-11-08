# Compare the two imports of the same language
swift-ecore compare Arith-asdl.ecore Arith-sig.ecore

# Output:
# Comparing metamodels: Arith-asdl.ecore -> Arith-sig.ecore
# ~ package Arith name: Arith -> Arith_sig
# ~ package Arith nsURI: urn:asdl:Arith -> urn:sdf3:Arith_sig
# ~ package Arith nsPrefix: arith -> arith_sig
# - class expr: abstract
# ~ class Num supertypes: expr -> Expr
# - attribute Num.value: EInt [1..1]
# + attribute Num.int1: INT [1..1]
# ...
# ~ class BinOp supertypes: expr -> Expr
# - reference BinOp.left: expr [1..1], containment
# - attribute BinOp.operator: op [1..1]
# - reference BinOp.right: expr [1..1], containment
# + reference BinOp.expr1: Expr [1..1], containment
# + reference BinOp.op1: Op [1..1], containment
# + reference BinOp.expr2: Expr [1..1], containment
# ...
# - enumeration op: Add, Sub, Mul, Div
# - class program
# + class Program: abstract
# + class ProgramProgram: extends Program
# + class Expr: abstract
# + class Op: abstract
# + class Add: extends Op
# ...
# + data type ID: java.lang.String
# + data type INT: java.lang.String
# 36 differences: 18 added, 11 removed, 7 changed
