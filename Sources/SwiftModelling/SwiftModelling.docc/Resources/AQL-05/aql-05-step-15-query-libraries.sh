# Transitive closure operations
# Compute reachable elements through relationships

# Transitive closure of project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p->closure(proj | proj.dependencies)
        ->excluding(p)
        ->collect(d | p.name + ' depends on ' + d.name
            + if p.dependencies->includes(d) then '' else ' (indirectly)' endif))"

# Output: ["Infrastructure Modernisation depends on Customer Portal", "Analytics Dashboard depends on Customer Portal", "Analytics Dashboard depends on Infrastructure Modernisation"]

# Transitive closure of supervision (all managers in the chain)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.supervisor <> null)
    ->collect(e | e->closure(emp | emp.supervisor)
        ->excluding(e)
        ->collect(s | e.name + ' reports up to ' + s.name))"

# Output: ["James Wong reports up to Sarah Mitchell", "Emily Chen reports up to James Wong", "Emily Chen reports up to Sarah Mitchell", ..., "Jack Robinson reports up to William Anderson"]

# Transitive closure of department containment
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | d->closure(dept | dept.subDepartments)
        ->excluding(d)
        ->collect(sd | d.name + ' contains ' + sd.name))"

# Output: ["Engineering contains Platform Team", "Engineering contains Mobile Team"]

# Find all projects that rely on the projects a department leads
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let startDept = organisation.departments->select(d | d.code = 'ENG')->first()
    in let directProjects = organisation.projects
        ->select(p | p.leadDepartment = startDept
            or startDept.subDepartments->includes(p.leadDepartment))
    in directProjects
        ->collect(p | p->closure(proj | organisation.projects
                ->select(other | other.dependencies->includes(proj)))
            ->collect(other | p.name + ' is needed by ' + other.name))"

# Output: ["Customer Portal is needed by Infrastructure Modernisation", "Customer Portal is needed by Analytics Dashboard", "Infrastructure Modernisation is needed by Analytics Dashboard"]

# Transitive mentorship relationships
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.mentors->notEmpty())
    ->collect(e | e->closure(emp | emp.mentors)
        ->excluding(e)
        ->collect(m | e.name + ' learns from ' + m.name
            + if e.mentors->includes(m) then '' else ' (indirectly)' endif))"

# Output: ["James Wong learns from Sarah Mitchell", "Michael Brown learns from James Wong", "Michael Brown learns from Emily Chen", "Michael Brown learns from Sarah Mitchell (indirectly)", ..., "Jack Robinson learns from Emma Wilson"]

# Closure with depth tracking: count each department's ancestors
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents(enterprise::Department)
    ->collect(d | 'level '
        + d->closure(dept | dept.parentDepartment)->size().toString()
        + ': ' + d.name)"

# Output: ["level 0: Engineering", "level 1: Platform Team", "level 1: Mobile Team", "level 0: Product", "level 0: Design", "level 0: Operations"]
