# Compare the Langium import with the Xtext import, which share the same rules
swift-ecore compare Arith-xtext.ecore Arith-langium.ecore

# Output:
# Comparing metamodels: Arith-xtext.ecore -> Arith-langium.ecore
# ~ package arith name: arith -> Arith
# ~ package arith nsURI: http://www.example.org/arith -> urn:langium:Arith
# ~ class Expr abstract: false -> true
# ~ attribute Num.value type: EInt -> EDouble
# ~ attribute BinOp.operator type: Op -> EString
# - enumeration Op: Add, Sub, Mul, Div
# 6 differences: 0 added, 1 removed, 5 changed
