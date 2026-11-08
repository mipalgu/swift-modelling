# The facts state the multiplicities, the opposite references and the containment
grep -A 3 -e "^fact Multiplicities" -e "^fact Opposites" -e "^fact Containment" \
  verification/organisation.als

# Output:
# fact Multiplicities {
#   all o: Company | #o.departments <= 8
# }
# ...
# fact Opposites {
#   Department <: members = ~(Employee <: department)
# }
# ...
# fact Containment {
#   all o: EObject | lone contents.o
#   no o: EObject | o in o.^contents
# }
