# Comprehensive reports combining multiple analyses
# Full organisational intelligence reports

# Complete organisational health report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation,
        allEmps = org.departments.employees->flatten()
            ->union(org.departments.subDepartments.employees->flatten()),
        allDepts = org.departments->union(org.departments.subDepartments->flatten())
    in Tuple{
        overview = Tuple{
            name = org.name,
            age = 2024 - org.founded,
            headquarters = org.headquarters},
        workforce = Tuple{
            total = allEmps->size(),
            avgTenure = allEmps->collect(e | e.yearsOfService)->sum() / allEmps->size(),
            avgSalary = allEmps->collect(e | e.salary)->sum() / allEmps->size(),
            managersToEmployees = allEmps->select(e | e.directReports->notEmpty())->size()
                + ':' + allEmps->size()},
        finance = Tuple{
            totalBudget = allDepts->collect(d | d.budget)->sum(),
            totalSalaries = allEmps->collect(e | e.salary)->sum(),
            budgetUtilisation = allEmps->collect(e | e.salary)->sum() * 100
                / allDepts->collect(d | d.budget)->sum()},
        projects = Tuple{
            active = org.projects->select(p | p.status = 'Active')->size(),
            totalBudget = org.projects->collect(p | p.budget)->sum(),
            onTrack = org.projects->select(p | p.milestones
                ->forAll(m | m.completed or m.dueDate >= '2024-06-01'))->size()}}"

# Output: {overview: {...}, workforce: {...}, finance: {...}, projects: {...}}

# Risk assessment report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees->flatten()
        ->union(organisation.departments.subDepartments.employees->flatten())
    in Tuple{
        keyPersonRisk = allEmps
            ->select(e | e.directReports->size() >= 2 or
                e.assignedProjects->size() >= 2)
            ->collect(e | Tuple{
                name = e.name,
                role = e.role,
                reportsCount = e.directReports->size(),
                projectsCount = e.assignedProjects->size()}),
        singlePointOfFailure = allEmps
            ->collect(e | e.skills)->flatten()->asSet()
            ->select(skill | allEmps
                ->select(e | e.skills->includes(skill))->size() = 1)
            ->collect(skill | Tuple{
                skill = skill,
                holder = allEmps->select(e | e.skills->includes(skill))
                    ->first().name}),
        projectDependencyRisks = organisation.projects
            ->select(p | p.dependencies->size() >= 2)
            ->collect(p | Tuple{
                project = p.name,
                dependencyCount = p.dependencies->size(),
                blockedMilestones = p.milestones
                    ->reject(m | m.completed)->size()})}"

# Output: {keyPersonRisk: [...], singlePointOfFailure: [...], projectDependencyRisks: [...]}

# Cross-departmental collaboration report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let depts = p.teamMembers
            ->collect(e | e.eContainer())
            ->asSet()
        in Tuple{
            project = p.name,
            leadDepartment = p.leadDepartment.name,
            participatingDepartments = depts->collect(d | d.name),
            crossDepartmental = depts->size() > 1,
            collaborationScore = depts->size() * p.teamMembers->size()})"

# Output: [{project: "Customer Portal", leadDepartment: "Engineering",
#           participatingDepartments: [...], crossDepartmental: true, collaborationScore: 36}]

# Career progression and mentorship report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees->flatten()
        ->union(organisation.departments.subDepartments.employees->flatten())
    in Tuple{
        mentorshipPairs = allEmps
            ->select(e | e.mentors->notEmpty())
            ->collect(e | Tuple{
                mentee = e.name,
                mentors = e.mentors->collect(m | m.name)}),
        potentialLeaders = allEmps
            ->select(e | e.yearsOfService >= 5 and
                e.directReports->isEmpty() and
                e.assignedProjects->size() >= 2)
            ->collect(e | Tuple{
                name = e.name,
                tenure = e.yearsOfService,
                projects = e.assignedProjects->size()}),
        successionPaths = allEmps
            ->select(e | e.directReports->notEmpty())
            ->collect(e | Tuple{
                manager = e.name,
                potentialSuccessors = e.directReports
                    ->select(r | r.yearsOfService >= 3)
                    ->collect(r | r.name)})}"

# Output: {mentorshipPairs: [...], potentialLeaders: [...], successionPaths: [...]}

# Complete project status dashboard
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        status = p.status,
        priority = p.priority,
        budget = Tuple{
            allocated = p.budget,
            team = p.teamMembers->collect(e | e.salary)->sum() / 12},
        timeline = Tuple{
            start = p.startDate,
            end = p.endDate,
            milestonesTotal = p.milestones->size(),
            milestonesComplete = p.milestones->select(m | m.completed)->size()},
        team = Tuple{
            size = p.teamMembers->size(),
            departments = p.teamMembers
                ->collect(e | e.eContainer().name)->asSet()->size(),
            avgExperience = p.teamMembers
                ->collect(e | e.yearsOfService)->sum() / p.teamMembers->size()},
        risks = Tuple{
            blockedByDependencies = p.dependencies
                ->exists(d | d.milestones->reject(m | m.completed)->notEmpty()),
            understaffed = p.teamMembers->size() < 3,
            overdue = p.milestones
                ->exists(m | not m.completed and m.dueDate < '2024-06-01')}})"

# Output: [{project: "Customer Portal", status: "Active", priority: 1,
#           budget: {...}, timeline: {...}, team: {...}, risks: {...}}]
