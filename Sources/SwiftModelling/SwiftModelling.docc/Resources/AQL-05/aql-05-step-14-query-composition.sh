# Hierarchy and tree structure queries
# Navigate and analyse hierarchical structures

# Get full department hierarchy
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | Tuple{
        parent = d.name,
        children = d.subDepartments->collect(sd | sd.name),
        depth = if d.subDepartments->isEmpty() then 0 else 1 endif})"

# Output: [{parent: "Engineering", children: ["Platform Team", "Mobile Team"], depth: 1}, ...]

# Find all descendants of a department (closure operation)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let engDept = organisation.departments->select(d | d.code = 'ENG')->first()
    in engDept->closure(d | d.subDepartments)
        ->collect(d | Tuple{name = d.name, code = d.code})"

# Output: [{name: "Engineering", code: "ENG"},
#          {name: "Platform Team", code: "ENG-PLT"},
#          {name: "Mobile Team", code: "ENG-MOB"}]

# Calculate hierarchy depth for each employee
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->collect(e | let depth =
        if e.supervisor = null then 0
        else if e.supervisor.supervisor = null then 1
        else if e.supervisor.supervisor.supervisor = null then 2
        else 3 endif endif endif
    in Tuple{employee = e.name, managementLevel = depth})"

# Output: [{employee: "Sarah Mitchell", managementLevel: 0}, ...]

# Find employees with deepest supervision chain
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.supervisor <> null and e.supervisor.supervisor <> null)
    ->collect(e | Tuple{
        employee = e.name,
        supervisor = e.supervisor.name,
        grandSupervisor = e.supervisor.supervisor.name})"

# Output: [{employee: "Michael Brown", supervisor: "James Wong", grandSupervisor: "Sarah Mitchell"}]

# Build organisation tree with employee counts
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | Tuple{
        department = d.name,
        directEmployees = d.employees->size(),
        subDepartments = d.subDepartments
            ->collect(sd | Tuple{
                name = sd.name,
                employees = sd.employees->size()}),
        totalEmployees = d.employees->size() +
            d.subDepartments.employees->flatten()->size()})"

# Output: [{department: "Engineering", directEmployees: 4,
#           subDepartments: [{name: "Platform Team", employees: 3}, ...],
#           totalEmployees: 10}]

# Find leaf departments (no sub-departments)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
        ->union(organisation.departments.subDepartments->flatten())
    in allDepts->select(d | d.subDepartments->isEmpty())
        ->collect(d | Tuple{
            name = d.name,
            isSubDept = organisation.departments->excludes(d),
            employeeCount = d.employees->size()})"

# Output: [{name: "Platform Team", isSubDept: true, employeeCount: 3}, ...]

# Calculate total budget including sub-departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | Tuple{
        department = d.name,
        ownBudget = d.budget,
        subDeptBudget = d.subDepartments->collect(sd | sd.budget)->sum(),
        totalBudget = d.budget + d.subDepartments->collect(sd | sd.budget)->sum()})"

# Output: [{department: "Engineering", ownBudget: 2500000, subDeptBudget: 1400000,
#           totalBudget: 3900000}]
