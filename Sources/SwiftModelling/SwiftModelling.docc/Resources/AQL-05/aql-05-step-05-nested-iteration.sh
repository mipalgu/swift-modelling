# Nested iteration patterns
# Iterate over multiple collections simultaneously

# Nested select for complex filtering: senior staff per department
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.employees->exists(e | e.yearsOfService >= 10))
    ->collect(d | d.employees
        ->select(e | e.yearsOfService >= 10)
        ->collect(e | d.name + ': ' + e.name))"

# Output: ["Engineering: Sarah Mitchell", "Product: Jessica Moore", "Design: Olivia Martinez", "Operations: William Anderson"]

# Nested iteration with forAll: departments where everyone earns at least 100k
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.employees->forAll(e | e.salary >= 100000))
    ->collect(d | d.name)"

# Output: ["Engineering"]

# Double iteration for relationship analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.supervisor <> null)
    ->collect(e | e.name + ' reports to ' + e.supervisor.name
        + ', same department: '
        + (e.eContainer() = e.supervisor.eContainer()).toString())"

# Output: ["James Wong reports to Sarah Mitchell, same department: true", ..., "Jack Robinson reports to Emma Wilson, same department: true"]

# Nested iteration over projects and the departments of their team members
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.teamMembers
        ->collect(e | e.eContainer().name)
        ->asSet()
        ->collect(d | p.name + ': ' + d))"

# Output: ["Customer Portal: Engineering", "Customer Portal: Mobile Team", "Customer Portal: Product", "Customer Portal: Design", ..., "Analytics Dashboard: Product"]

# Nested exists with multiple levels
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.subDepartments->exists(sd |
        sd.employees->exists(e | e.yearsOfService >= 8)))
    ->collect(d | d.name)"

# Output: ["Engineering"]
