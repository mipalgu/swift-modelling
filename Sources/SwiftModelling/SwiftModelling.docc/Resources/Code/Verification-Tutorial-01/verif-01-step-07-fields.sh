# The fields of a department, with their multiplicities
grep -A 6 "^sig Department" verification/organisation.als

# Output:
# sig Department extends EObject {
#   name: one String,
#   code: one String,
#   capacity: one Int,
#   members: set Employee,
#   manager: lone Employee
# }
