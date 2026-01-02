# Nested iteration patterns
# Iterate over multiple collections simultaneously

# Nested select for complex filtering
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.employees->exists(e | e.yearsOfService >= 10))
    ->collect(d | Tuple{department = d.name,
                        seniors = d.employees
                            ->select(e | e.yearsOfService >= 10)
                            ->collect(e | e.name)})"

# Output: [{department: "Engineering", seniors: ["Sarah Mitchell"]},
#          {department: "Product", seniors: ["Jessica Moore"]}, ...]

# Nested iteration with forAll
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.employees->forAll(e | e.salary >= 100000))
    ->collect(d | d.name)"

# Output: ["Engineering", "Product", "Design"] (all have employees earning >= 100k)

# Double iteration for relationship analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.supervisor <> null)
    ->collect(e | Tuple{employee = e.name,
                        supervisor = e.supervisor.name,
                        sameDepartment = e.eContainer() = e.supervisor.eContainer()})"

# Output: [{employee: "James Wong", supervisor: "Sarah Mitchell", sameDepartment: true}, ...]

# Nested iteration over projects and employees
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{project = p.name,
                        departments = p.teamMembers
                            ->collect(e | e.eContainer().name)
                            ->asSet()})"

# Output: [{project: "Customer Portal", departments: ["Engineering", "Product", "Design", ...]}, ...]

# Nested exists with multiple levels
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.subDepartments->exists(sd |
        sd.employees->exists(e | e.yearsOfService >= 8)))
    ->collect(d | d.name)"

# Output: ["Engineering"] (has sub-departments with experienced employees)
