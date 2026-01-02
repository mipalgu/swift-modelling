# Pattern matching in queries
# Identify specific patterns and structures in models

# Find employees matching supervision pattern (manager -> reports)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.directReports->size() >= 2)
    ->collect(e | Tuple{
        manager = e.name,
        role = e.role,
        reportCount = e.directReports->size(),
        reports = e.directReports->collect(r | r.name)})"

# Output: [{manager: "James Wong", role: "Senior Engineer", reportCount: 2, reports: [...]}]

# Match mentorship chains (mentor -> mentee -> mentee)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.mentors->notEmpty())
    ->collect(e | Tuple{
        mentee = e.name,
        directMentors = e.mentors->collect(m | m.name),
        grandMentors = e.mentors.mentors->flatten()->asSet()->collect(m | m.name)})"

# Output: [{mentee: "Michael Brown", directMentors: ["James Wong", "Emily Chen"],
#           grandMentors: ["Sarah Mitchell"]}]

# Pattern: find circular collaboration (A collaborates with B, B with A)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.collaboratesWith->exists(c | c.collaboratesWith->includes(d)))
    ->collect(d | Tuple{
        department = d.name,
        bidirectionalPartners = d.collaboratesWith
            ->select(c | c.collaboratesWith->includes(d))
            ->collect(c | c.name)})"

# Output: [{department: "Engineering", bidirectionalPartners: ["Product", "Design"]}]

# Pattern: project dependency chains
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->select(p | p.dependencies->notEmpty())
    ->collect(p | Tuple{
        project = p.name,
        directDeps = p.dependencies->collect(d | d.name),
        transitiveDeps = p.dependencies.dependencies
            ->flatten()->asSet()->collect(d | d.name)})"

# Output: [{project: "Analytics Dashboard", directDeps: ["Customer Portal", "Infrastructure..."],
#           transitiveDeps: ["Customer Portal"]}]

# Pattern: employees with cross-departmental project involvement
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.assignedProjects
        ->collect(p | p.leadDepartment)
        ->asSet()
        ->select(d | d <> e.eContainer())
        ->notEmpty())
    ->collect(e | Tuple{
        employee = e.name,
        homeDept = e.eContainer().name,
        crossDeptProjects = e.assignedProjects
            ->select(p | p.leadDepartment <> e.eContainer())
            ->collect(p | p.name)})"

# Output: [{employee: "Emily Chen", homeDept: "Engineering",
#           crossDeptProjects: ["Mobile App Redesign"]}]

# Pattern: find managers who also mentor
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.directReports->notEmpty() and
        organisation.departments.employees->flatten()
            ->exists(emp | emp.mentors->includes(e)))
    ->collect(e | Tuple{
        managerMentor = e.name,
        directReports = e.directReports->collect(r | r.name),
        mentees = organisation.departments.employees
            ->flatten()
            ->select(emp | emp.mentors->includes(e))
            ->collect(emp | emp.name)})"

# Output: [{managerMentor: "James Wong", directReports: [...], mentees: ["Michael Brown"]}]
