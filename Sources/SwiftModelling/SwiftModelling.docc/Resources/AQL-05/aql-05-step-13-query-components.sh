# Grouping and categorisation analysis
# Group elements and analyse by category

# Group employees by years of service bands
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in Tuple{
        junior = employees->select(e | e.yearsOfService <= 3)
            ->collect(e | Tuple{name = e.name, years = e.yearsOfService}),
        midLevel = employees->select(e | e.yearsOfService > 3 and e.yearsOfService <= 8)
            ->collect(e | Tuple{name = e.name, years = e.yearsOfService}),
        senior = employees->select(e | e.yearsOfService > 8)
            ->collect(e | Tuple{name = e.name, years = e.yearsOfService})}"

# Output: {junior: [{name: "Michael Brown", years: 3}, ...], midLevel: [...], senior: [...]}

# Group projects by status with metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projects = organisation.projects,
        statuses = projects->collect(p | p.status)->asSet()
    in statuses->collect(s | Tuple{
        status = s,
        count = projects->select(p | p.status = s)->size(),
        totalBudget = projects->select(p | p.status = s)
            ->collect(p | p.budget)->sum(),
        avgTeamSize = projects->select(p | p.status = s)
            ->collect(p | p.teamMembers->size())->sum()
            / projects->select(p | p.status = s)->size()})"

# Output: [{status: "Active", count: 3, totalBudget: 1050000, avgTeamSize: 8},
#          {status: "Planning", count: 1, totalBudget: 150000, avgTeamSize: 3}]

# Group by location
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
        ->union(organisation.departments.subDepartments->flatten()),
        locations = allDepts->collect(d | d.location)->asSet()
    in locations->collect(loc | Tuple{
        location = loc,
        departments = allDepts->select(d | d.location = loc)->collect(d | d.name),
        totalEmployees = allDepts->select(d | d.location = loc)
            .employees->flatten()->size(),
        totalBudget = allDepts->select(d | d.location = loc)
            ->collect(d | d.budget)->sum()})"

# Output: [{location: "Melbourne", departments: [...], totalEmployees: 11, totalBudget: 4500000}, ...]

# Group employees by salary bands
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in Sequence{
        Tuple{band = 'Under 100k',
              count = employees->select(e | e.salary < 100000)->size(),
              avgExperience = employees->select(e | e.salary < 100000)
                  ->collect(e | e.yearsOfService)->sum()
                  / employees->select(e | e.salary < 100000)->size().max(1)},
        Tuple{band = '100k-130k',
              count = employees->select(e | e.salary >= 100000 and e.salary < 130000)->size(),
              avgExperience = employees->select(e | e.salary >= 100000 and e.salary < 130000)
                  ->collect(e | e.yearsOfService)->sum()
                  / employees->select(e | e.salary >= 100000 and e.salary < 130000)->size().max(1)},
        Tuple{band = '130k-160k',
              count = employees->select(e | e.salary >= 130000 and e.salary < 160000)->size(),
              avgExperience = employees->select(e | e.salary >= 130000 and e.salary < 160000)
                  ->collect(e | e.yearsOfService)->sum()
                  / employees->select(e | e.salary >= 130000 and e.salary < 160000)->size().max(1)},
        Tuple{band = 'Over 160k',
              count = employees->select(e | e.salary >= 160000)->size(),
              avgExperience = employees->select(e | e.salary >= 160000)
                  ->collect(e | e.yearsOfService)->sum()
                  / employees->select(e | e.salary >= 160000)->size().max(1)}}"

# Output: [{band: "Under 100k", count: 4, avgExperience: 1.5}, ...]

# Group milestones by completion status per project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        completed = p.milestones->select(m | m.completed)->collect(m | m.name),
        pending = p.milestones->reject(m | m.completed)->collect(m | m.name),
        completionPercentage = if p.milestones->notEmpty()
            then p.milestones->select(m | m.completed)->size() * 100
                 / p.milestones->size()
            else 100 endif})"

# Output: [{project: "Customer Portal", completed: ["Requirements Complete", "Design Finalised"],
#           pending: ["Beta Release", "Production Launch"], completionPercentage: 50}]
