# Transitive closure operations
# Compute reachable elements through relationships

# Transitive closure of project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        directDependencies = p.dependencies->collect(d | d.name),
        allDependencies = p->closure(proj | proj.dependencies)
            ->excluding(p)
            ->collect(d | d.name)})"

# Output: [{project: "Analytics Dashboard",
#           directDependencies: ["Customer Portal", "Infrastructure Modernisation"],
#           allDependencies: ["Customer Portal", "Infrastructure Modernisation"]}]

# Transitive closure of supervision (all managers in chain)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.supervisor <> null)
    ->collect(e | Tuple{
        employee = e.name,
        allSupervisors = e->closure(emp |
            if emp.supervisor <> null
            then Sequence{emp.supervisor}
            else Sequence{} endif)
            ->excluding(e)
            ->collect(s | s.name)})"

# Output: [{employee: "Michael Brown", allSupervisors: ["James Wong", "Sarah Mitchell"]}, ...]

# Transitive closure of department containment
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | Tuple{
        department = d.name,
        allSubDepartments = d->closure(dept | dept.subDepartments)
            ->excluding(d)
            ->collect(sd | sd.name)})"

# Output: [{department: "Engineering", allSubDepartments: ["Platform Team", "Mobile Team"]}, ...]

# Find all reachable projects from a department
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let startDept = organisation.departments->select(d | d.code = 'ENG')->first()
    in let directProjects = organisation.projects
        ->select(p | p.leadDepartment = startDept
            or startDept.subDepartments->includes(p.leadDepartment))
    in let dependentProjects = directProjects
        ->collect(p | p->closure(proj |
            organisation.projects->select(other | other.dependencies->includes(proj))))
        ->flatten()
        ->asSet()
    in Tuple{
        directProjects = directProjects->collect(p | p.name),
        allRelatedProjects = dependentProjects->collect(p | p.name)}"

# Output: {directProjects: ["Customer Portal", "Infrastructure Modernisation", "Mobile App Redesign"],
#          allRelatedProjects: [...]}

# Transitive mentorship relationships
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.mentors->notEmpty())
    ->collect(e | Tuple{
        mentee = e.name,
        directMentors = e.mentors->collect(m | m.name),
        allMentors = e->closure(emp | emp.mentors)
            ->excluding(e)
            ->asSet()
            ->collect(m | m.name)})"

# Output: [{mentee: "Tom Nguyen", directMentors: ["Anna Kowalski"],
#           allMentors: ["Anna Kowalski"]}]

# Closure with depth tracking (simulated)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let root = organisation.departments->select(d | d.code = 'ENG')->first()
    in Sequence{
        Tuple{level = 0, departments = Sequence{root.name}},
        Tuple{level = 1, departments = root.subDepartments->collect(d | d.name)},
        Tuple{level = 2, departments = root.subDepartments.subDepartments
            ->flatten()->collect(d | d.name)}}"

# Output: [{level: 0, departments: ["Engineering"]},
#          {level: 1, departments: ["Platform Team", "Mobile Team"]},
#          {level: 2, departments: []}]
