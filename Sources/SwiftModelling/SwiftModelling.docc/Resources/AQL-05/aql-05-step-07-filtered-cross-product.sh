# Navigating relationships between model elements
# Follow references from one kind of element to related elements

# From project to its lead department and all involved departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.name + ': led by ' + p.leadDepartment.name
        + ', departments involved: ' + p.teamMembers
            ->collect(e | e.eContainer())
            ->asSet()
            ->size().toString())"

# Output: ["Customer Portal: led by Engineering, departments involved: 4", "Infrastructure Modernisation: led by Platform Team, departments involved: 2", "Mobile App Redesign: led by Mobile Team, departments involved: 4", "Analytics Dashboard: led by Product, departments involved: 1"]

# From employee to their projects, flagging those led by their own department
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments->select(d | d.code = 'PROD')->first()
    .employees
    ->collect(e | e.assignedProjects
        ->collect(p | e.name + ' works on ' + p.name
            + if p.leadDepartment = e.eContainer()
              then ' (own department)' else '' endif))"

# Output: ["Jessica Moore works on Customer Portal", "Jessica Moore works on Mobile App Redesign", "Jessica Moore works on Analytics Dashboard (own department)", ..., "Ryan Hughes works on Analytics Dashboard (own department)"]

# Navigate from incomplete milestones to their project teams
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects.milestones
    ->select(m | not m.completed)
    ->collect(m | m.name + ' (' + m.eContainer().name + '): '
        + m.eContainer().teamMembers->size().toString() + ' team members')"

# Output: ["Beta Release (Customer Portal): 9 team members", "Production Launch (Customer Portal): 9 team members", "Cloud Migration (Infrastructure Modernisation): 4 team members", ..., "Prototype (Analytics Dashboard): 3 team members"]

# Filtered cross-reference: collaborating department members on the first project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let project = organisation.projects->first() in
    project.leadDepartment.collaboratesWith
        ->collect(collabDept | project.teamMembers
            ->select(e | e.eContainer() = collabDept
                or collabDept.subDepartments->includes(e.eContainer()))
            ->collect(e | collabDept.name + ': ' + e.name))"

# Output: ["Product: Jessica Moore", "Product: Daniel Kim", "Design: Olivia Martinez", "Design: Nathan Scott"]

# Navigate bidirectional relationships (supervisor and directReports)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.directReports->notEmpty())
    ->collect(e | e.directReports
        ->collect(r | e.name + ' manages ' + r.name
            + ' (projects: ' + r.assignedProjects->size().toString() + ')'))"

# Output: ["Sarah Mitchell manages James Wong (projects: 1)", "James Wong manages Emily Chen (projects: 2)", ..., "Emma Wilson manages Jack Robinson (projects: 0)"]
