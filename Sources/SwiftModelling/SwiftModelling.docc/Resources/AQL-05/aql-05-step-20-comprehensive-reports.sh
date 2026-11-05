# Comprehensive reports combining multiple analyses
# Full organisational intelligence reports

# Complete organisational health report (as at 1 June 2024)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation,
        allEmps = org.departments.employees
            ->union(org.departments.subDepartments.employees),
        allDepts = org.departments->union(org.departments.subDepartments),
        totalBudget = allDepts->collect(d | d.budget)->sum(),
        totalSalaries = allEmps->collect(e | e.salary)->sum()
    in Sequence{
        'overview: ' + org.name + ', age ' + (2024 - org.founded).toString()
            + ', headquarters ' + org.headquarters,
        'workforce: ' + allEmps->size().toString() + ' employees, average tenure '
            + (allEmps->collect(e | e.yearsOfService)->sum() / allEmps->size()).toString()
            + ', average salary ' + (totalSalaries / allEmps->size()).toString()
            + ', managers ' + allEmps->select(e | e.directReports->notEmpty())->size().toString()
            + ' of ' + allEmps->size().toString(),
        'finance: budget ' + totalBudget.toString()
            + ', salaries ' + totalSalaries.toString()
            + ', utilisation ' + (totalSalaries * 100 / totalBudget).toString() + '%',
        'projects: active ' + org.projects->select(p | p.status = 'Active')->size().toString()
            + ', budget ' + org.projects->collect(p | p.budget)->sum().toString()
            + ', on track ' + org.projects->select(p | p.milestones
                ->forAll(m | m.completed or m.dueDate >= '2024-06-01'))->size().toString()}"

# Output: ["overview: Acme Technologies, age 29, headquarters Melbourne", "workforce: 21 employees, average tenure 6, average salary 128238.09523809524, managers 10 of 21", "finance: budget 6700000.0, salaries 2693000.0, utilisation 40.19402985074627%", "projects: active 3, budget 1200000.0, on track 4"]

# Risk assessment report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees
        ->union(organisation.departments.subDepartments.employees)
    in allEmps
        ->select(e | e.directReports->size() >= 2 or e.assignedProjects->size() >= 2)
        ->collect(e | 'key person: ' + e.name + ' (' + e.role + '), reports '
            + e.directReports->size().toString()
            + ', projects ' + e.assignedProjects->size().toString())
    ->concat(allEmps.skills->asSet()
        ->select(skill | allEmps->select(e | e.skills->includes(skill))->size() = 1)
        ->collect(skill | 'single holder: ' + skill + ' ('
            + allEmps->select(e | e.skills->includes(skill))->first().name + ')'))
    ->concat(organisation.projects
        ->select(p | p.dependencies->size() >= 2)
        ->collect(p | 'dependency risk: ' + p.name + ', dependencies '
            + p.dependencies->size().toString() + ', incomplete milestones '
            + p.milestones->reject(m | m.completed)->size().toString()))"

# Output: ["key person: Sarah Mitchell (Engineering Director), reports 1, projects 2", ..., "key person: Rachel Adams (Mobile Lead), reports 2, projects 2", "single holder: Python (Emily Chen)", ..., "single holder: Compose (Linda Park)", "dependency risk: Analytics Dashboard, dependencies 2, incomplete milestones 2"]

# Cross-departmental collaboration report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let depts = p.teamMembers
            ->collect(e | e.eContainer())
            ->asSet()
        in p.name + ' (lead ' + p.leadDepartment.name + '): departments '
            + depts->size().toString()
            + ', cross-departmental ' + (depts->size() > 1).toString()
            + ', collaboration score '
            + (depts->size() * p.teamMembers->size()).toString())"

# Output: ["Customer Portal (lead Engineering): departments 4, cross-departmental true, collaboration score 36", ..., "Analytics Dashboard (lead Product): departments 1, cross-departmental false, collaboration score 3"]

# Career progression and mentorship report
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmps = organisation.departments.employees
        ->union(organisation.departments.subDepartments.employees)
    in allEmps
        ->select(e | e.mentors->notEmpty())
        ->collect(e | e.mentors->collect(m | 'mentorship: ' + m.name + ' -> ' + e.name))
    ->concat(allEmps
        ->select(e | e.yearsOfService >= 5 and
            e.directReports->isEmpty() and
            e.assignedProjects->size() >= 2)
        ->collect(e | 'potential leader: ' + e.name + ', tenure '
            + e.yearsOfService.toString() + ', projects '
            + e.assignedProjects->size().toString()))
    ->concat(allEmps
        ->select(e | e.directReports->notEmpty())
        ->collect(e | e.directReports
            ->select(r | r.yearsOfService >= 3)
            ->collect(r | 'successor: ' + r.name + ' for ' + e.name)))"

# Output: ["mentorship: Sarah Mitchell -> James Wong", ..., "mentorship: Rachel Adams -> Linda Park", "potential leader: Emily Chen, tenure 5, projects 2", "successor: James Wong for Sarah Mitchell", ..., "successor: Linda Park for Rachel Adams"]

# Complete project status dashboard (as at 1 June 2024)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | p.name + ' [' + p.status + ', priority ' + p.priority.toString() + ']'
        + ' budget ' + p.budget.toString()
        + ', monthly team cost '
        + (p.teamMembers->collect(e | e.salary)->sum() / 12).toString()
        + ', ' + p.startDate + ' to ' + p.endDate
        + ', milestones ' + p.milestones->select(m | m.completed)->size().toString()
        + '/' + p.milestones->size().toString()
        + ', team ' + p.teamMembers->size().toString()
        + ' from ' + p.teamMembers->collect(e | e.eContainer().name)->asSet()->size().toString()
        + ' departments, average experience '
        + (p.teamMembers->collect(e | e.yearsOfService)->sum()
            / p.teamMembers->size()).toString()
        + ', blocked ' + p.dependencies
            ->exists(d | d.milestones->reject(m | m.completed)->notEmpty()).toString()
        + ', understaffed ' + (p.teamMembers->size() < 3).toString()
        + ', overdue ' + p.milestones
            ->exists(m | not m.completed and m.dueDate < '2024-06-01').toString())"

# Output: ["Customer Portal [Active, priority 1] budget 450000.0, monthly team cost 109583.33333333333, 2024-01-15 to 2024-09-30, milestones 2/4, team 9 from 4 departments, average experience 8, blocked false, understaffed false, overdue false", ..., "Analytics Dashboard [Planning, priority 3] budget 150000.0, monthly team cost 31250.0, 2024-06-01 to 2024-11-30, milestones 0/2, team 3 from 1 departments, average experience 5, blocked true, understaffed false, overdue false"]
