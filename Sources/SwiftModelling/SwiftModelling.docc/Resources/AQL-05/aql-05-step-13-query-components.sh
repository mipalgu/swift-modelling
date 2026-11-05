# Grouping and categorisation analysis
# Group elements and analyse by category

# Categorise employees into years-of-service bands
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->sortedBy(e | e.yearsOfService)
    ->collect(e | (if e.yearsOfService <= 3 then 'junior'
                   else if e.yearsOfService <= 8 then 'mid-level'
                   else 'senior' endif endif)
        + ': ' + e.name + ' (years: ' + e.yearsOfService.toString() + ')')"

# Output: ["junior: Alex Rivera (years: 1)", ..., "junior: Mia Thompson (years: 3)", "mid-level: Sophie Garcia (years: 4)", ..., "senior: William Anderson (years: 14)"]

# Group projects by status with metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projects = organisation.projects,
        statuses = projects->collect(p | p.status)->asSet()
    in statuses->collect(s | let group = projects->select(p | p.status = s)
        in s + ': projects ' + group->size().toString() + ', budget '
            + group->collect(p | p.budget)->sum().toString()
            + ', average team size '
            + (group->collect(p | p.teamMembers->size())->sum()
                / group->size()).toString())"

# Output: ["Active: projects 3, budget 1050000.0, average team size 7", "Planning: projects 1, budget 150000.0, average team size 3"]

# Group departments and sub-departments by location
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.departments
            ->union(organisation.departments.subDepartments),
        locations = allDepts->collect(d | d.location)->asSet()
    in locations->collect(loc | let group = allDepts->select(d | d.location = loc)
        in loc + ': departments ' + group->size().toString()
            + ', employees ' + group.employees->size().toString() + ', budget '
            + group->collect(d | d.budget)->sum().toString())"

# Output: ["Melbourne: departments 3, employees 11, budget 4500000.0", "Sydney: departments 2, employees 7, budget 1500000.0", "Brisbane: departments 1, employees 3, budget 700000.0"]

# Group employees by salary bands (average experience uses integer division)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees,
        under100k = employees->select(e | e.salary < 100000),
        from100k = employees->select(e | e.salary >= 100000 and e.salary < 130000),
        from130k = employees->select(e | e.salary >= 130000 and e.salary < 160000),
        over160k = employees->select(e | e.salary >= 160000)
    in Sequence{
        'under 100k: ' + under100k->size().toString() + ', average experience '
            + (under100k->collect(e | e.yearsOfService)->sum()
                / under100k->size().max(1)).toString(),
        '100k-130k: ' + from100k->size().toString() + ', average experience '
            + (from100k->collect(e | e.yearsOfService)->sum()
                / from100k->size().max(1)).toString(),
        '130k-160k: ' + from130k->size().toString() + ', average experience '
            + (from130k->collect(e | e.yearsOfService)->sum()
                / from130k->size().max(1)).toString(),
        '160k and over: ' + over160k->size().toString() + ', average experience '
            + (over160k->collect(e | e.yearsOfService)->sum()
                / over160k->size().max(1)).toString()}"

# Output: ["under 100k: 3, average experience 1", "100k-130k: 6, average experience 4", "130k-160k: 3, average experience 9", "160k and over: 3, average experience 11"]

# Group milestones by completion status per project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.name + ': '
        + p.milestones->select(m | m.completed)->size().toString() + ' completed, '
        + p.milestones->reject(m | m.completed)->size().toString() + ' pending, '
        + (if p.milestones->notEmpty()
           then p.milestones->select(m | m.completed)->size() * 100
                / p.milestones->size()
           else 100 endif).toString() + '% complete')"

# Output: ["Customer Portal: 2 completed, 2 pending, 50% complete", "Infrastructure Modernisation: 2 completed, 1 pending, 66% complete", "Mobile App Redesign: 2 completed, 1 pending, 66% complete", "Analytics Dashboard: 0 completed, 2 pending, 0% complete"]
