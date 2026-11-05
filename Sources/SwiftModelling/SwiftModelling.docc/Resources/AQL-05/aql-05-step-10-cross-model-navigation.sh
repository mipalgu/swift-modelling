# Type-based pattern matching
# Query based on element types and class hierarchy

# Find all elements of a specific type using oclIsKindOf
# (all employees in departments and sub-departments)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(enterprise::Employee))
    ->size()"

# Output: 21

# Group elements by type
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let contents = organisation.eAllContents()
    in 'departments: '
        + contents->select(e | e.oclIsKindOf(enterprise::Department))->size().toString()
        + ', employees: '
        + contents->select(e | e.oclIsKindOf(enterprise::Employee))->size().toString()
        + ', projects: '
        + contents->select(e | e.oclIsKindOf(enterprise::Project))->size().toString()
        + ', milestones: '
        + contents->select(e | e.oclIsKindOf(enterprise::Milestone))->size().toString()"

# Output: "departments: 6, employees: 21, projects: 4, milestones: 12"

# Type-safe navigation using oclAsType
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments->first()
    .eAllContents()
    ->select(e | e.oclIsKindOf(enterprise::Employee))
    ->collect(e | e.oclAsType(enterprise::Employee).name)"

# Output: ["Sarah Mitchell", "James Wong", "Emily Chen", "Michael Brown", "David Lee", "Anna Kowalski", "Tom Nguyen", "Rachel Adams", "Chris Taylor", "Linda Park"]

# Find elements by metaclass name
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.eClass().name = 'Milestone')
    ->collect(e | e.oclAsType(enterprise::Milestone).name + ': completed '
        + e.oclAsType(enterprise::Milestone).completed.toString())"

# Output: ["Requirements Complete: completed true", "Design Finalised: completed true", "Beta Release: completed false", ..., "Prototype: completed false"]

# Pattern: find all containers of a specific type
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(enterprise::Employee))
    ->collect(e | e.eContainer())
    ->asSet()
    ->collect(c | c.eClass().name + ': '
        + if c.oclIsKindOf(enterprise::Department)
          then c.oclAsType(enterprise::Department).name
          else 'Unknown' endif)"

# Output: ["Department: Engineering", "Department: Platform Team", "Department: Mobile Team", "Department: Product", "Department: Design", "Department: Operations"]

# Validate type constraints (true when all are satisfied)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects->forAll(p |
    p.teamMembers->forAll(m | m.oclIsKindOf(enterprise::Employee)) and
    p.leadDepartment.oclIsKindOf(enterprise::Department))"

# Output: true

# Find mismatched references (true when every supervisor is an Employee)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.supervisor <> null)
    ->forAll(e | e.supervisor.oclIsKindOf(enterprise::Employee))"

# Output: true
