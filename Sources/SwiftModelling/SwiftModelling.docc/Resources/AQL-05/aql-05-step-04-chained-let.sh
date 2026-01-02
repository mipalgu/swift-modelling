# Nested let bindings for layered calculations
# Build complex queries step by step

# Nested let for multi-stage calculation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let depts = organisation.departments in
    let employees = depts.employees->flatten() in
    let avgSalary = employees->collect(e | e.salary)->sum() / employees->size() in
    let aboveAvg = employees->select(e | e.salary > avgSalary)
    in Tuple{average = avgSalary,
             aboveAverageCount = aboveAvg->size(),
             aboveAverageNames = aboveAvg->collect(e | e.name)}"

# Output: {average: 128571.43, aboveAverageCount: 8, aboveAverageNames: [...]}

# Nested let for department analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let dept = organisation.departments->select(d | d.code = 'ENG')->first() in
    let directEmployees = dept.employees in
    let subDeptEmployees = dept.subDepartments.employees->flatten() in
    let allEmployees = directEmployees->union(subDeptEmployees)
    in Tuple{direct = directEmployees->size(),
             subDept = subDeptEmployees->size(),
             total = allEmployees->size()}"

# Output: {direct: 4, subDept: 6, total: 10}

# Nested let for project metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeProjects = organisation.projects->select(p | p.status = 'Active') in
    let totalBudget = activeProjects->collect(p | p.budget)->sum() in
    let avgTeamSize = activeProjects->collect(p | p.teamMembers->size())->sum()
                      / activeProjects->size()
    in Tuple{activeCount = activeProjects->size(),
             totalBudget = totalBudget,
             averageTeamSize = avgTeamSize}"

# Output: {activeCount: 3, totalBudget: 1050000.0, averageTeamSize: 8}

# Deeply nested let for complex reporting
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let org = organisation in
    let depts = org.departments in
    let engDept = depts->select(d | d.code = 'ENG')->first() in
    let engBudget = engDept.budget in
    let subBudgets = engDept.subDepartments->collect(d | d.budget)->sum()
    in Tuple{departmentBudget = engBudget,
             subDepartmentBudgets = subBudgets,
             totalEngineeringBudget = engBudget + subBudgets}"

# Output: {departmentBudget: 2500000.0, subDepartmentBudgets: 1400000.0, totalEngineeringBudget: 3900000.0}
