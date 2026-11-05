# Validation and constraint checking queries
# Verify model integrity and business rules

# Validate all employees have valid supervisors (no self or two-step cycles)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in 'self-supervision: '
        + employees->select(e | e.supervisor = e)->size().toString()
        + ', cyclic supervision: '
        + employees->select(e | e.supervisor <> null and
            e.supervisor.supervisor = e)->size().toString()
        + ', valid: '
        + employees->forAll(e | e.supervisor <> e and
            (e.supervisor = null or e.supervisor.supervisor <> e)).toString()"

# Output: "self-supervision: 0, cyclic supervision: 0, valid: true"

# Validate budget constraints (salary costs within budget, warn above 80%)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let salaryCost = d.employees->collect(e | e.salary)->sum()
    in d.name + ': ' + (salaryCost * 100 / d.budget).toString() + '% of budget'
        + ', within budget: ' + (salaryCost <= d.budget).toString()
        + ', warning: ' + (salaryCost > d.budget * 0.8).toString())"

# Output: ["Engineering: 22.8% of budget, within budget: true, warning: false", "Product: 42.5% of budget, within budget: true, warning: false", "Design: 53.333333333333336% of budget, within budget: true, warning: false", "Operations: 50.0% of budget, within budget: true, warning: false"]

# Validate project team composition
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let hasLeadDept = p.leadDepartment <> null,
        hasTeam = p.teamMembers->notEmpty(),
        leadDeptRepresented = p.teamMembers
            ->exists(e | e.eContainer() = p.leadDepartment or
                p.leadDepartment.subDepartments.employees->includes(e))
    in p.name + ': lead department ' + hasLeadDept.toString()
        + ', team ' + hasTeam.toString()
        + ', lead department represented ' + leadDeptRepresented.toString()
        + ', valid ' + (hasLeadDept and hasTeam and leadDeptRepresented).toString())"

# Output: ["Customer Portal: lead department true, team true, lead department represented true, valid true", ..., "Analytics Dashboard: lead department true, team true, lead department represented true, valid true"]

# Check for orphaned references
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees
        ->union(organisation.departments.subDepartments.employees)
    in 'invalid supervisors: '
        + allEmployees->select(e | e.supervisor <> null and
            allEmployees->excludes(e.supervisor))->size().toString()
        + ', invalid mentors: '
        + allEmployees->select(e | e.mentors
            ->exists(m | allEmployees->excludes(m)))->size().toString()
        + ', all references valid: '
        + allEmployees->forAll(e |
            (e.supervisor = null or allEmployees->includes(e.supervisor))
            and e.mentors->forAll(m | allEmployees->includes(m))).toString()"

# Output: "invalid supervisors: 0, invalid mentors: 0, all references valid: true"

# Validate milestone ordering and that milestones fall within the project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.name + ': ordered '
        + (p.milestones->collect(m | m.dueDate)->sortedBy(d | d)
            = p.milestones->collect(m | m.dueDate)).toString()
        + ', within project dates '
        + p.milestones->forAll(m | m.dueDate >= p.startDate
            and m.dueDate <= p.endDate).toString())"

# Output: ["Customer Portal: ordered true, within project dates true", "Infrastructure Modernisation: ordered true, within project dates true", "Mobile App Redesign: ordered true, within project dates true", "Analytics Dashboard: ordered true, within project dates true"]

# Check for circular project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.name + ': self dependency '
        + p.dependencies->includes(p).toString()
        + ', circular dependency '
        + p.dependencies->exists(d | d.dependencies->includes(p)).toString()
        + ', valid '
        + (not p.dependencies->includes(p) and
            not p.dependencies->exists(d | d.dependencies->includes(p))).toString())"

# Output: ["Customer Portal: self dependency false, circular dependency false, valid true", ..., "Analytics Dashboard: self dependency false, circular dependency false, valid true"]

# Validate role hierarchy (directors manage leads or senior staff)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in employees
        ->select(e | e.directReports->notEmpty())
        ->collect(e | e.name + ' (' + e.role + '): valid hierarchy '
            + (if e.role.endsWith('Director')
               then e.directReports->forAll(r |
                   r.role.endsWith('Lead') or r.role.startsWith('Senior'))
               else true endif).toString())"

# Output: ["Sarah Mitchell (Engineering Director): valid hierarchy true", "James Wong (Senior Engineer): valid hierarchy true", "Jessica Moore (Product Director): valid hierarchy false", ..., "William Anderson (Operations Director): valid hierarchy false", "Emma Wilson (Operations Manager): valid hierarchy true"]
