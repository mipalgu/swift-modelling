# Nested let bindings for layered calculations
# Build complex queries step by step

# Nested let for multi-stage calculation: who earns above the average?
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let depts = organisation.departments in
    let employees = depts.employees in
    let avgSalary = employees->collect(e | e.salary)->sum() / employees->size() in
    let aboveAvg = employees->select(e | e.salary > avgSalary)
    in aboveAvg->collect(e | e.name + ' earns ' + e.salary.toString()
        + ' (average ' + avgSalary.toString() + ')')"

# Output: ["Sarah Mitchell earns 185000.0 (average 127333.33333333333)", ..., "William Anderson earns 150000.0 (average 127333.33333333333)"]

# Nested let for department analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let dept = organisation.departments->select(d | d.code = 'ENG')->first() in
    let directEmployees = dept.employees in
    let subDeptEmployees = dept.subDepartments.employees in
    let allEmployees = directEmployees->union(subDeptEmployees)
    in 'direct: ' + directEmployees->size().toString()
        + ', sub-departments: ' + subDeptEmployees->size().toString()
        + ', total: ' + allEmployees->size().toString()"

# Output: "direct: 4, sub-departments: 6, total: 10"

# Nested let for project metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeProjects = organisation.projects->select(p | p.status = 'Active') in
    let totalBudget = activeProjects->collect(p | p.budget)->sum() in
    let avgTeamSize = activeProjects->collect(p | p.teamMembers->size())->sum()
                      / activeProjects->size()
    in 'active: ' + activeProjects->size().toString()
        + ', total budget: ' + totalBudget.toString()
        + ', average team size: ' + avgTeamSize.toString()"

# Output: "active: 3, total budget: 1050000.0, average team size: 7"

# Deeply nested let for complex reporting
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation in
    let depts = org.departments in
    let engDept = depts->select(d | d.code = 'ENG')->first() in
    let engBudget = engDept.budget in
    let subBudgets = engDept.subDepartments->collect(d | d.budget)->sum()
    in 'department: ' + engBudget.toString()
        + ', sub-departments: ' + subBudgets.toString()
        + ', engineering total: ' + (engBudget + subBudgets).toString()"

# Output: "department: 2500000.0, sub-departments: 1400000.0, engineering total: 3900000.0"
