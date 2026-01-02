# Summary report generation
# Create comprehensive summaries and overviews

# Executive summary of the organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation,
        allDepts = org.departments->union(org.departments.subDepartments->flatten()),
        allEmps = org.departments.employees->flatten()
            ->union(org.departments.subDepartments.employees->flatten())
    in Tuple{
        organisation = org.name,
        founded = org.founded,
        headquarters = org.headquarters,
        totalDepartments = allDepts->size(),
        totalEmployees = allEmps->size(),
        totalProjects = org.projects->size(),
        totalBudget = allDepts->collect(d | d.budget)->sum(),
        totalSalaries = allEmps->collect(e | e.salary)->sum()}"

# Output: {organisation: "Acme Technologies", founded: 1995, headquarters: "Melbourne",
#          totalDepartments: 6, totalEmployees: 21, totalProjects: 4,
#          totalBudget: 5300000, totalSalaries: 2670000}

# Department summary report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | Tuple{
        name = d.name,
        location = d.location,
        budget = d.budget,
        employeeCount = d.employees->size() +
            d.subDepartments.employees->flatten()->size(),
        avgSalary = (d.employees->collect(e | e.salary)
            ->union(d.subDepartments.employees->flatten()
                ->collect(e | e.salary)))->sum()
            / (d.employees->size() + d.subDepartments.employees->flatten()->size()),
        subDepartmentCount = d.subDepartments->size(),
        projectInvolvement = organisation.projects
            ->select(p | p.leadDepartment = d or
                d.subDepartments->includes(p.leadDepartment))
            ->size()})"

# Output: [{name: "Engineering", location: "Melbourne", budget: 2500000,
#           employeeCount: 10, avgSalary: 133400, subDepartmentCount: 2,
#           projectInvolvement: 3}]

# Project portfolio summary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projects = organisation.projects
    in Tuple{
        totalProjects = projects->size(),
        byStatus = Tuple{
            active = projects->select(p | p.status = 'Active')->size(),
            planning = projects->select(p | p.status = 'Planning')->size(),
            completed = projects->select(p | p.status = 'Completed')->size()},
        totalBudget = projects->collect(p | p.budget)->sum(),
        avgTeamSize = projects->collect(p | p.teamMembers->size())->sum()
            / projects->size(),
        highPriority = projects->select(p | p.priority = 1)
            ->collect(p | p.name),
        milestoneProgress = Tuple{
            total = projects.milestones->flatten()->size(),
            completed = projects.milestones->flatten()
                ->select(m | m.completed)->size()}}"

# Output: {totalProjects: 4, byStatus: {active: 3, planning: 1, completed: 0},
#          totalBudget: 1200000, avgTeamSize: 6, highPriority: [...],
#          milestoneProgress: {total: 12, completed: 5}}

# Workforce summary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
        ->flatten()
        ->union(organisation.departments.subDepartments.employees->flatten())
    in Tuple{
        totalHeadcount = employees->size(),
        avgSalary = employees->collect(e | e.salary)->sum() / employees->size(),
        avgTenure = employees->collect(e | e.yearsOfService)->sum() / employees->size(),
        salaryRange = Tuple{
            min = employees->collect(e | e.salary)->min(),
            max = employees->collect(e | e.salary)->max()},
        tenureRange = Tuple{
            min = employees->collect(e | e.yearsOfService)->min(),
            max = employees->collect(e | e.yearsOfService)->max()},
        managementRatio = employees->select(e | e.directReports->notEmpty())->size()
            * 100 / employees->size()}"

# Output: {totalHeadcount: 21, avgSalary: 127142.86, avgTenure: 6.19,
#          salaryRange: {min: 85000, max: 185000},
#          tenureRange: {min: 1, max: 14}, managementRatio: 38}

# Location-based summary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
        ->union(organisation.departments.subDepartments->flatten()),
        locations = allDepts->collect(d | d.location)->asSet()
    in locations->collect(loc | Tuple{
        location = loc,
        departmentCount = allDepts->select(d | d.location = loc)->size(),
        employeeCount = allDepts->select(d | d.location = loc)
            .employees->flatten()->size(),
        totalBudget = allDepts->select(d | d.location = loc)
            ->collect(d | d.budget)->sum()})"

# Output: [{location: "Melbourne", departmentCount: 3, employeeCount: 11, totalBudget: 4500000},
#          {location: "Sydney", departmentCount: 2, employeeCount: 7, totalBudget: 1500000}, ...]
