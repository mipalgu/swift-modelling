swift-ecore query ProjectA.xmi --metamodel Organisation.ecore --query "find Department"

# Output:
# Objects matching 'Department'
# Found 1 match(es)
# 1. Department 'Project Alpha' (/)
#    name = "Project Alpha"
#    relatedDepartments -> Department 'IT' in SharedDeps.xmi#it
#    employees: 2 contained object(s)
