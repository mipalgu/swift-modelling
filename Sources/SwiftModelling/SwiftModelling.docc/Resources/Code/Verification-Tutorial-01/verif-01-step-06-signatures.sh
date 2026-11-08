# Every class is a signature, and every enumeration literal a one sig
grep "sig " verification/organisation.als

# Output:
# abstract sig EObject {}
# sig Company extends EObject {
# sig Department extends EObject {
# sig Employee extends EObject {
# abstract sig EmploymentKind {}
# one sig EmploymentKind_FULL_TIME, EmploymentKind_PART_TIME extends EmploymentKind {}
