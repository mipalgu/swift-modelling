# Pattern matching in queries
# Identify specific patterns and structures in models

# Find employees matching a supervision pattern (manager with two or more reports)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.directReports->size() >= 2)
    ->collect(e | e.name + ' (' + e.role + '): '
        + e.directReports->size().toString() + ' direct reports')"

# Output: ["James Wong (Senior Engineer): 2 direct reports", "Jessica Moore (Product Director): 2 direct reports", "Olivia Martinez (Design Director): 2 direct reports"]

# Match mentorship chains (mentor -> mentee -> mentee)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.mentors->notEmpty())
    ->collect(e | e.mentors
        ->collect(m | m.mentors
            ->collect(g | g.name + ' mentors ' + m.name
                + ', who mentors ' + e.name)))"

# Output: ["Sarah Mitchell mentors James Wong, who mentors Michael Brown", "Daniel Kim mentors Sophie Garcia, who mentors Ryan Hughes", "Nathan Scott mentors Mia Thompson, who mentors Alex Rivera"]

# Pattern: find mutual collaboration (A collaborates with B, B with A)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | d.collaboratesWith
        ->select(c | c.collaboratesWith->includes(d))
        ->collect(c | d.name + ' <-> ' + c.name))"

# Output: ["Engineering <-> Product", "Engineering <-> Design", "Product <-> Engineering", "Product <-> Design", "Design <-> Engineering", "Design <-> Product"]

# Pattern: project dependency chains of length two
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.dependencies
        ->collect(d | d.dependencies
            ->collect(dd | p.name + ' -> ' + d.name + ' -> ' + dd.name)))"

# Output: ["Analytics Dashboard -> Infrastructure Modernisation -> Customer Portal"]

# Pattern: employees working on projects led by another department
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->collect(e | e.assignedProjects
        ->select(p | p.leadDepartment <> e.eContainer())
        ->collect(p | e.name + ' (' + e.eContainer().name + '): ' + p.name))"

# Output: ["Sarah Mitchell (Engineering): Infrastructure Modernisation", "Emily Chen (Engineering): Mobile App Redesign", ..., "Alex Rivera (Design): Mobile App Redesign"]

# Pattern: find managers who also mentor
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in employees
        ->select(e | e.directReports->notEmpty() and
            employees->exists(emp | emp.mentors->includes(e)))
        ->collect(e | e.name + ': manages '
            + e.directReports->size().toString() + ', mentors '
            + employees->select(emp | emp.mentors->includes(e))->size().toString())"

# Output: ["Sarah Mitchell: manages 1, mentors 1", "James Wong: manages 2, mentors 1", "Daniel Kim: manages 1, mentors 2", "Nathan Scott: manages 1, mentors 2", "Emma Wilson: manages 1, mentors 1"]
