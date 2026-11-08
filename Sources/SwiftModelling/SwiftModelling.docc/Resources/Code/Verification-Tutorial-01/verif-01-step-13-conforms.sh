# The model module opens the metamodel module and fixes every object and value
grep -e "^open" -e "sig " -e "^run" -e "^check" verification/office_instance.als

# Output:
# open organisation
# open util/boolean
# one sig Company1 extends Company {}
# one sig Department2, Department3 extends Department {}
# one sig Employee4, Employee5, Employee6, Employee7 extends Employee {}
# run conforms {} for 7 but 4 Int
# check Company_UniqueDepartmentCodes_satisfied for 7 but 4 Int
# check Department_ManagerIsMember_satisfied for 7 but 4 Int
# check Department_WithinCapacity_satisfied for 7 but 4 Int
