# Query composition patterns
# Build complex queries from simpler components

# Compose filtering and transformation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeHighPriority = organisation.projects
        ->select(p | p.status = 'Active')
        ->select(p | p.priority <= 2)
    in activeHighPriority
        ->collect(p | Tuple{
            name = p.name,
            budget = p.budget,
            teamSize = p.teamMembers->size(),
            costPerMember = p.budget / p.teamMembers->size()})"

# Output: [{name: "Customer Portal", budget: 450000, teamSize: 9, costPerMember: 50000}, ...]

# Compose aggregation queries
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let deptStats = organisation.departments
        ->collect(d | Tuple{
            name = d.name,
            employeeCount = d.employees->size(),
            avgSalary = d.employees->collect(e | e.salary)->sum()
                        / d.employees->size(),
            totalBudget = d.budget})
    in Tuple{
        departments = deptStats,
        totalEmployees = deptStats->collect(s | s.employeeCount)->sum(),
        overallAvgSalary = deptStats->collect(s | s.avgSalary)->sum()
                          / deptStats->size()}"

# Output: {departments: [...], totalEmployees: 16, overallAvgSalary: 127500}

# Compose navigation with filtering
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let experiencedEngineers = organisation.departments
        ->select(d | d.code = 'ENG' or d.code.startsWith('ENG-'))
        .employees
        ->flatten()
        ->select(e | e.yearsOfService >= 5),
    projectsWithExperts = organisation.projects
        ->select(p | p.teamMembers
            ->intersection(experiencedEngineers)->notEmpty())
    in projectsWithExperts->collect(p | Tuple{
        project = p.name,
        expertCount = p.teamMembers
            ->intersection(experiencedEngineers)->size()})"

# Output: [{project: "Customer Portal", expertCount: 4}, ...]

# Multi-stage composition for complex analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees->flatten()
    in let seniorEmps = allEmps->select(e | e.yearsOfService >= 10)
    in let juniorEmps = allEmps->select(e | e.yearsOfService <= 2)
    in let mentorPairs = seniorEmps
        ->collect(s | juniorEmps
            ->select(j | j.mentors->includes(s))
            ->collect(j | Tuple{mentor = s.name, mentee = j.name}))
        ->flatten()
    in Tuple{totalMentorships = mentorPairs->size(),
             pairs = mentorPairs}"

# Output: {totalMentorships: 2, pairs: [{mentor: "...", mentee: "..."}, ...]}

# Compose conditional logic
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p |
        let status = if p.milestones->forAll(m | m.completed)
                     then 'Complete'
                     else if p.milestones->exists(m | m.completed)
                     then 'In Progress'
                     else 'Not Started' endif endif
        in Tuple{project = p.name,
                 derivedStatus = status,
                 completedMilestones = p.milestones
                     ->select(m | m.completed)->size(),
                 totalMilestones = p.milestones->size()})"

# Output: [{project: "Customer Portal", derivedStatus: "In Progress", ...}, ...]
