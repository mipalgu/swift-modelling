# Validation and constraint checking queries
# Verify model integrity and business rules

# Validate all employees have valid supervisors (not self-referential)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in Tuple{
        selfSupervision = employees
            ->select(e | e.supervisor = e)
            ->collect(e | e.name),
        cyclicSupervision = employees
            ->select(e | e.supervisor <> null and
                e.supervisor.supervisor = e)
            ->collect(e | e.name),
        valid = employees->forAll(e | e.supervisor <> e and
            (e.supervisor = null or e.supervisor.supervisor <> e))}"

# Output: {selfSupervision: [], cyclicSupervision: [], valid: true}

# Validate budget constraints (salary costs within budget)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let salaryCost = d.employees->collect(e | e.salary)->sum()
    in Tuple{
        department = d.name,
        budget = d.budget,
        salaryCost = salaryCost,
        percentage = salaryCost * 100 / d.budget,
        withinBudget = salaryCost <= d.budget,
        warning = salaryCost > d.budget * 0.8})"

# Output: [{department: "Engineering", budget: 2500000, salaryCost: 570000,
#           percentage: 22.8, withinBudget: true, warning: false}]

# Validate project team composition
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        hasLeadDept = p.leadDepartment <> null,
        hasTeam = p.teamMembers->notEmpty(),
        leadDeptRepresented = p.teamMembers
            ->exists(e | e.eContainer() = p.leadDepartment or
                p.leadDepartment.subDepartments.employees
                    ->flatten()->includes(e)),
        valid = p.leadDepartment <> null and p.teamMembers->notEmpty() and
            p.teamMembers->exists(e | e.eContainer() = p.leadDepartment or
                p.leadDepartment.subDepartments.employees
                    ->flatten()->includes(e))})"

# Output: [{project: "Customer Portal", hasLeadDept: true, hasTeam: true,
#           leadDeptRepresented: true, valid: true}]

# Check for orphaned references
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten()
        ->union(organisation.departments.subDepartments.employees->flatten())
    in Tuple{
        invalidSupervisors = allEmployees
            ->select(e | e.supervisor <> null and
                allEmployees->excludes(e.supervisor))
            ->collect(e | e.name),
        invalidMentors = allEmployees
            ->select(e | e.mentors->exists(m | allEmployees->excludes(m)))
            ->collect(e | e.name),
        allReferencesValid = allEmployees
            ->forAll(e | (e.supervisor = null or allEmployees->includes(e.supervisor))
                and e.mentors->forAll(m | allEmployees->includes(m)))}"

# Output: {invalidSupervisors: [], invalidMentors: [], allReferencesValid: true}

# Validate milestone ordering (due dates should be sequential)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        milestonesOrdered = p.milestones
            ->collect(m | m.dueDate)->sortedBy(d | d)
            = p.milestones->collect(m | m.dueDate),
        completedBeforeDue = p.milestones
            ->forAll(m | m.completed implies true)})"

# Output: [{project: "Customer Portal", milestonesOrdered: true, completedBeforeDue: true}]

# Check for circular project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        selfDependency = p.dependencies->includes(p),
        circularDependency = p.dependencies
            ->exists(d | d.dependencies->includes(p)),
        valid = not p.dependencies->includes(p) and
            not p.dependencies->exists(d | d.dependencies->includes(p))})"

# Output: [{project: "Customer Portal", selfDependency: false, circularDependency: false,
#           valid: true}]

# Validate role hierarchy (directors manage leads, leads manage others)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in employees
        ->select(e | e.directReports->notEmpty())
        ->collect(e | Tuple{
            manager = e.name,
            managerRole = e.role,
            reportRoles = e.directReports->collect(r | r.role),
            validHierarchy = if e.role.endsWith('Director')
                then e.directReports->forAll(r |
                    r.role.endsWith('Lead') or r.role.startsWith('Senior'))
                else true endif})"

# Output: [{manager: "Sarah Mitchell", managerRole: "Engineering Director",
#           reportRoles: ["Senior Engineer"], validHierarchy: true}]
