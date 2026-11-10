# Count the packages, classes and features of every import against the ASDL import
for grammar in xtext langium sdf3 sig; do
  swift-ecore compare Arith-asdl.ecore "Arith-$grammar.ecore" --summary
done

# Output:
# Comparing metamodels: Arith-asdl.ecore -> Arith-xtext.ecore
# Elements:
#   Packages: 1 -> 1
#   Classes: 6 -> 6
#   Enumerations: 1 -> 1
#   Data types: 0 -> 0
#   Attributes: 5 -> 5
#   References: 5 -> 5
#   Operations: 0 -> 0
# 25 differences: 3 added, 3 removed, 19 changed
# Comparing metamodels: Arith-asdl.ecore -> Arith-langium.ecore
# ...
#   Enumerations: 1 -> 0 (-1)
# ...
# 24 differences: 2 added, 3 removed, 19 changed
# Comparing metamodels: Arith-asdl.ecore -> Arith-sdf3.ecore
# Elements:
#   Packages: 1 -> 1
#   Classes: 6 -> 12 (+6)
#   Enumerations: 1 -> 0 (-1)
#   Data types: 0 -> 2 (+2)
#   Attributes: 5 -> 4 (-1)
#   References: 5 -> 6 (+1)
#   Operations: 0 -> 0
# 28 differences: 10 added, 3 removed, 15 changed
# Comparing metamodels: Arith-asdl.ecore -> Arith-sig.ecore
# ...
#   Classes: 6 -> 12 (+6)
# ...
# 36 differences: 18 added, 11 removed, 7 changed
