# Query composition patterns
# Build complex queries from simpler components, filtering early

# Compose filtering and transformation: filter first, then compute
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeHighPriority = organisation.projects
        ->select(p | p.status = 'Active')
        ->select(p | p.priority <= 2)
    in activeHighPriority
        ->collect(p | p.name
            + ': budget ' + p.budget.toString()
            + ', team ' + p.teamMembers->size().toString()
            + ', cost per member ' + (p.budget / p.teamMembers->size()).toString())"

# Output: ["Customer Portal: budget 450000.0, team 9, cost per member 50000.0", "Infrastructure Modernisation: budget 320000.0, team 4, cost per member 80000.0", "Mobile App Redesign: budget 280000.0, team 9, cost per member 31111.11111111111"]

# Compose aggregation queries: average the department averages
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let depts = organisation.departments,
        deptAverages = depts->collect(d |
            d.employees->collect(e | e.salary)->sum() / d.employees->size())
    in 'total employees: ' + depts.employees->size().toString()
        + ', mean of department averages: '
        + (deptAverages->sum() / deptAverages->size()).toString()"

# Output: "total employees: 15, mean of department averages: 126666.66666666667"

# Compose navigation with filtering: experienced engineers on each project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
            ->union(organisation.departments.subDepartments),
        experiencedEngineers = allDepts
            ->select(d | d.code = 'ENG' or d.code.startsWith('ENG-'))
            .employees
            ->select(e | e.yearsOfService >= 5),
        projectsWithExperts = organisation.projects
            ->select(p | p.teamMembers
                ->intersection(experiencedEngineers)->notEmpty())
    in projectsWithExperts->collect(p | p.name + ': '
        + p.teamMembers->intersection(experiencedEngineers)->size().toString()
        + ' experienced engineers')"

# Output: ["Customer Portal: 4 experienced engineers", "Infrastructure Modernisation: 3 experienced engineers", "Mobile App Redesign: 2 experienced engineers"]

# Multi-stage composition: experienced mentors of junior staff
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees
    in let experienced = allEmps->select(e | e.yearsOfService >= 5)
    in let juniors = allEmps->select(e | e.yearsOfService <= 3)
    in let mentorPairs = experienced
        ->collect(s | juniors
            ->select(j | j.mentors->includes(s))
            ->collect(j | s.name + ' mentors ' + j.name))
    in mentorPairs"

# Output: ["James Wong mentors Michael Brown", "Emily Chen mentors Michael Brown", "Daniel Kim mentors Ryan Hughes", "Nathan Scott mentors Mia Thompson", "Nathan Scott mentors Alex Rivera", "Emma Wilson mentors Jack Robinson"]

# Compose conditional logic
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p |
        let status = if p.milestones->forAll(m | m.completed)
                     then 'Complete'
                     else if p.milestones->exists(m | m.completed)
                     then 'In Progress'
                     else 'Not Started' endif endif
        in p.name + ': ' + status + ' ('
            + p.milestones->select(m | m.completed)->size().toString()
            + ' of ' + p.milestones->size().toString() + ' milestones)')"

# Output: ["Customer Portal: In Progress (2 of 4 milestones)", "Infrastructure Modernisation: In Progress (2 of 3 milestones)", "Mobile App Redesign: In Progress (2 of 3 milestones)", "Analytics Dashboard: Not Started (0 of 2 milestones)"]
