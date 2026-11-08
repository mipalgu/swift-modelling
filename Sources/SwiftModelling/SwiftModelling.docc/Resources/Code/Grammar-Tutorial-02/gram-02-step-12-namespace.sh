# Import the Langium grammar into the namespace of the Xtext import, and compare again
swift-ecore convert Arith.langium Arith-langium-ns.ecore \
  --ns-uri http://www.example.org/arith --ns-prefix arith
swift-ecore compare Arith-xtext.ecore Arith-langium-ns.ecore

# Output:
# Conversion completed: Arith-langium-ns.ecore
# Comparing metamodels: Arith-xtext.ecore -> Arith-langium-ns.ecore
# ~ package arith name: arith -> Arith
# ~ class Expr abstract: false -> true
# ~ attribute Num.value type: EInt -> EDouble
# ~ attribute BinOp.operator type: Op -> EString
# - enumeration Op: Add, Sub, Mul, Div
# 5 differences: 0 added, 1 removed, 4 changed
