# Type-based pattern matching
# Query based on element types and class hierarchy

# Find all elements of a specific type using oclIsKindOf
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->size()"

# Output: 21 (total employees across all departments and sub-departments)

# Group elements by type
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let contents = organisation.eAllContents()
    in Tuple{
        departments = contents->select(e | e.oclIsKindOf(Department))->size(),
        employees = contents->select(e | e.oclIsKindOf(Employee))->size(),
        projects = contents->select(e | e.oclIsKindOf(Project))->size(),
        milestones = contents->select(e | e.oclIsKindOf(Milestone))->size()}"

# Output: {departments: 6, employees: 21, projects: 4, milestones: 12}

# Type-safe navigation using oclAsType
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments->first()
    .eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->collect(e | e.oclAsType(Employee).name)"

# Output: ["Sarah Mitchell", "James Wong", "Emily Chen", "Michael Brown", ...]

# Find elements by metaclass name
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.eClass().name = 'Milestone')
    ->collect(e | Tuple{
        milestone = e.oclAsType(Milestone).name,
        completed = e.oclAsType(Milestone).completed})"

# Output: [{milestone: "Requirements Complete", completed: true}, ...]

# Pattern: find all containers of a specific type
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->collect(e | e.eContainer())
    ->asSet()
    ->collect(c | Tuple{
        containerType = c.eClass().name,
        name = if c.oclIsKindOf(Department)
               then c.oclAsType(Department).name
               else 'Unknown' endif})"

# Output: [{containerType: "Department", name: "Engineering"}, ...]

# Validate type constraints
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects->forAll(p |
    p.teamMembers->forAll(m | m.oclIsKindOf(Employee)) and
    p.leadDepartment.oclIsKindOf(Department))"

# Output: true (all type constraints satisfied)

# Find mismatched references (type checking)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.supervisor <> null)
    ->forAll(e | e.supervisor.oclIsKindOf(Employee))"

# Output: true (all supervisors are valid Employee types)
