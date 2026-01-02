# Cross-model navigation patterns
# Navigate relationships across different model elements

# From project to all related departments (via team members)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        leadDept = p.leadDepartment.name,
        involvedDepts = p.teamMembers
            ->collect(e | e.eContainer())
            ->asSet()
            ->collect(d | d.name)})"

# Output: [{project: "Customer Portal", leadDept: "Engineering",
#           involvedDepts: ["Engineering", "Platform Team", "Mobile Team", "Product", "Design"]}]

# From employee to all projects in their department
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments->select(d | d.code = 'PROD')->first()
    .employees
    ->collect(e | Tuple{
        employee = e.name,
        ownProjects = e.assignedProjects->collect(p | p.name),
        deptProjects = organisation.projects
            ->select(p | p.leadDepartment = e.eContainer())
            ->collect(p | p.name)})"

# Output: [{employee: "Jessica Moore", ownProjects: [...], deptProjects: ["Analytics Dashboard"]}]

# Navigate from milestone to responsible employees
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects.milestones
    ->flatten()
    ->select(m | not m.completed)
    ->collect(m | Tuple{
        milestone = m.name,
        project = m.eContainer().name,
        responsibleTeam = m.eContainer().teamMembers
            ->collect(e | e.name)})"

# Output: [{milestone: "Beta Release", project: "Customer Portal", responsibleTeam: [...]}, ...]

# Cross-reference: find collaborating department employees on same project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let project = organisation.projects->first() in
    project.leadDepartment.collaboratesWith
        ->collect(collabDept | Tuple{
            department = collabDept.name,
            teamMembersFromDept = project.teamMembers
                ->select(e | e.eContainer() = collabDept
                    or collabDept.subDepartments->includes(e.eContainer()))
                ->collect(e | e.name)})"

# Output: [{department: "Product", teamMembersFromDept: ["Jessica Moore", "Daniel Kim"]},
#          {department: "Design", teamMembersFromDept: ["Olivia Martinez", "Nathan Scott"]}]

# Navigate bidirectional relationships
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.directReports->notEmpty())
    ->collect(e | Tuple{
        manager = e.name,
        directReports = e.directReports->collect(r | r.name),
        theirProjects = e.directReports.assignedProjects
            ->flatten()
            ->asSet()
            ->collect(p | p.name)})"

# Output: [{manager: "Sarah Mitchell", directReports: ["James Wong"], theirProjects: [...]}]
