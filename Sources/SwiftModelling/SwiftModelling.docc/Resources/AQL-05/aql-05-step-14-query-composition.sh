# Hierarchy and tree structure queries
# Navigate and analyse hierarchical structures

# Get the department hierarchy
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | d.name + ': depth '
        + (if d.subDepartments->isEmpty() then 0 else 1 endif).toString()
        + ', sub-departments ' + d.subDepartments->size().toString())"

# Output: ["Engineering: depth 1, sub-departments 2", "Product: depth 0, sub-departments 0", "Design: depth 0, sub-departments 0", "Operations: depth 0, sub-departments 0"]

# Find all descendants of a department (closure does not include the start)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let engDept = organisation.departments->select(d | d.code = 'ENG')->first()
    in engDept->closure(d | d.subDepartments)
        ->collect(d | d.name + ' (' + d.code + ')')"

# Output: ["Platform Team (ENG-PLT)", "Mobile Team (ENG-MOB)"]

# Calculate the management level of each employee
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->collect(e | let depth =
        if e.supervisor = null then 0
        else if e.supervisor.supervisor = null then 1
        else if e.supervisor.supervisor.supervisor = null then 2
        else 3 endif endif endif
    in e.name + ': level ' + depth.toString())"

# Output: ["Sarah Mitchell: level 0", "James Wong: level 1", "Emily Chen: level 2", "Michael Brown: level 2", ..., "Jack Robinson: level 2"]

# Find employees with the deepest supervision chain
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.supervisor <> null and e.supervisor.supervisor <> null)
    ->collect(e | e.name + ' -> ' + e.supervisor.name
        + ' -> ' + e.supervisor.supervisor.name)"

# Output: ["Emily Chen -> James Wong -> Sarah Mitchell", "Michael Brown -> James Wong -> Sarah Mitchell", "Ryan Hughes -> Daniel Kim -> Jessica Moore", "Alex Rivera -> Nathan Scott -> Olivia Martinez", "Jack Robinson -> Emma Wilson -> William Anderson"]

# Build the organisation tree with employee counts
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | d.name + ': direct ' + d.employees->size().toString()
        + ', in sub-departments '
        + d.subDepartments.employees->size().toString()
        + ', total '
        + (d.employees->size() + d.subDepartments.employees->size()).toString())"

# Output: ["Engineering: direct 4, in sub-departments 6, total 10", "Product: direct 4, in sub-departments 0, total 4", ..., "Operations: direct 3, in sub-departments 0, total 3"]

# Find leaf departments (no sub-departments)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
        ->union(organisation.departments.subDepartments)
    in allDepts->select(d | d.subDepartments->isEmpty())
        ->collect(d | d.name + ': sub-department '
            + organisation.departments->excludes(d).toString()
            + ', employees ' + d.employees->size().toString())"

# Output: ["Product: sub-department false, employees 4", "Design: sub-department false, employees 4", "Operations: sub-department false, employees 3", "Platform Team: sub-department true, employees 3", "Mobile Team: sub-department true, employees 3"]

# Calculate total budget including sub-departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let subDeptBudget = d.subDepartments->collect(sd | sd.budget)->sum()
        in d.name + ': own ' + d.budget.toString()
            + ', sub-departments ' + subDeptBudget.toString()
            + ', total ' + (d.budget + subDeptBudget).toString())"

# Output: ["Engineering: own 2500000.0, sub-departments 1400000.0, total 3900000.0", "Product: own 1200000.0, sub-departments 0, total 1200000.0", ..., "Operations: own 700000.0, sub-departments 0, total 700000.0"]
