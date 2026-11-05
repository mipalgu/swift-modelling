# Summary report generation
# Create comprehensive summaries and overviews

# Executive summary of the organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation,
        allDepts = org.departments->union(org.departments.subDepartments),
        allEmps = org.departments.employees
            ->union(org.departments.subDepartments.employees)
    in Sequence{
        'organisation: ' + org.name,
        'founded: ' + org.founded.toString(),
        'headquarters: ' + org.headquarters,
        'departments: ' + allDepts->size().toString(),
        'employees: ' + allEmps->size().toString(),
        'projects: ' + org.projects->size().toString(),
        'total budget: ' + allDepts->collect(d | d.budget)->sum().toString(),
        'total salaries: ' + allEmps->collect(e | e.salary)->sum().toString()}"

# Output: ["organisation: Acme Technologies", "founded: 1995", "headquarters: Melbourne", "departments: 6", "employees: 21", "projects: 4", "total budget: 6700000.0", "total salaries: 2693000.0"]

# Department summary report (including sub-departments)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let staff = d.employees->union(d.subDepartments.employees)
        in d.name + ' (' + d.location + '): budget ' + d.budget.toString()
            + ', employees ' + staff->size().toString()
            + ', average salary '
            + (staff->collect(e | e.salary)->sum() / staff->size()).toString()
            + ', sub-departments ' + d.subDepartments->size().toString()
            + ', projects led '
            + organisation.projects
                ->select(p | p.leadDepartment = d or
                    d.subDepartments->includes(p.leadDepartment))
                ->size().toString())"

# Output: ["Engineering (Melbourne): budget 2500000.0, employees 10, average salary 135300.0, sub-departments 2, projects led 3", ..., "Operations (Brisbane): budget 700000.0, employees 3, average salary 116666.66666666667, sub-departments 0, projects led 0"]

# Project portfolio summary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projects = organisation.projects
    in Sequence{
        'projects: ' + projects->size().toString(),
        'active: ' + projects->select(p | p.status = 'Active')->size().toString(),
        'planning: ' + projects->select(p | p.status = 'Planning')->size().toString(),
        'completed: ' + projects->select(p | p.status = 'Completed')->size().toString(),
        'total budget: ' + projects->collect(p | p.budget)->sum().toString(),
        'average team size: ' + (projects->collect(p | p.teamMembers->size())->sum()
            / projects->size()).toString(),
        'priority 1: ' + projects->select(p | p.priority = 1)->size().toString(),
        'milestones: ' + projects.milestones->select(m | m.completed)->size().toString()
            + ' of ' + projects.milestones->size().toString() + ' completed'}"

# Output: ["projects: 4", "active: 3", "planning: 1", "completed: 0", "total budget: 1200000.0", "average team size: 6", "priority 1: 2", "milestones: 6 of 12 completed"]

# Workforce summary (average tenure uses integer division)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
        ->union(organisation.departments.subDepartments.employees),
        salaries = employees->collect(e | e.salary),
        tenures = employees->collect(e | e.yearsOfService)
    in Sequence{
        'headcount: ' + employees->size().toString(),
        'average salary: ' + (salaries->sum() / employees->size()).toString(),
        'average tenure: ' + (tenures->sum() / employees->size()).toString(),
        'salary range: ' + salaries->min().toString()
            + ' to ' + salaries->max().toString(),
        'tenure range: ' + tenures->min().toString()
            + ' to ' + tenures->max().toString(),
        'management ratio: ' + (employees->select(e | e.directReports->notEmpty())->size()
            * 100 / employees->size()).toString() + '%'}"

# Output: ["headcount: 21", "average salary: 128238.09523809524", "average tenure: 6", "salary range: 85000.0 to 185000.0", "tenure range: 1 to 14", "management ratio: 47%"]

# Location-based summary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
        ->union(organisation.departments.subDepartments),
        locations = allDepts->collect(d | d.location)->asSet()
    in locations->collect(loc | let group = allDepts->select(d | d.location = loc)
        in loc + ': departments ' + group->size().toString()
            + ', employees ' + group.employees->size().toString()
            + ', budget ' + group->collect(d | d.budget)->sum().toString())"

# Output: ["Melbourne: departments 3, employees 11, budget 4500000.0", "Sydney: departments 2, employees 7, budget 1500000.0", "Brisbane: departments 1, employees 3, budget 700000.0"]
