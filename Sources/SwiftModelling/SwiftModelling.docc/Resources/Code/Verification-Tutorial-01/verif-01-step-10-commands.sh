# The commands that the Alloy Analyzer runs
grep -e "^run" -e "^check" verification/organisation.als

# Output:
# run instance { invariants } for 4 but 5 Int, exactly 4 String
# check Company_UniqueDepartmentCodes_holds for 4 but 5 Int, exactly 4 String
# check Department_ManagerIsMember_holds for 4 but 5 Int, exactly 4 String
# check Department_WithinCapacity_holds for 4 but 5 Int, exactly 4 String
