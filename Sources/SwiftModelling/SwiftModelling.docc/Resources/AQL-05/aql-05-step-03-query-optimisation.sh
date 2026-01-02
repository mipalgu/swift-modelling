#!/bin/bash
# Query optimisation techniques
# Using let bindings and strategic evaluation to improve performance

# Example 1: Avoid redundant collection traversal
# BAD: Multiple traversals of the same collection
# swift-aql evaluate --model enterprise-data.xmi \
#   --expression "Tuple{
#     highSalary = organisation.departments.employees->flatten()->select(e | e.salary >= 150000)->size(),
#     mediumSalary = organisation.departments.employees->flatten()->select(e | e.salary >= 100000 and e.salary < 150000)->size(),
#     lowSalary = organisation.departments.employees->flatten()->select(e | e.salary < 100000)->size()
#   }"

# GOOD: Single traversal with let binding
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in Tuple{
        highSalary = employees->select(e | e.salary >= 150000)->size(),
        mediumSalary = employees->select(e | e.salary >= 100000 and e.salary < 150000)->size(),
        lowSalary = employees->select(e | e.salary < 100000)->size()
    }"

# Output: {highSalary: 5, mediumSalary: 8, lowSalary: 7}

# Example 2: Reuse filtered collections
# BAD: Filtering same collection multiple times
# GOOD: Filter once, reuse multiple times
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeProjects = organisation.projects
        ->select(p | p.status = 'Active')
    in Tuple{
        count = activeProjects->size(),
        totalBudget = activeProjects->collect(p | p.budget)->sum(),
        avgTeamSize = activeProjects
            ->collect(p | p.teamMembers->size())
            ->sum() / activeProjects->size()
    }"

# Output: {count: 3, totalBudget: 1050000.0, avgTeamSize: 8}

# Example 3: Avoid nested loops with exists
# BAD: Nested iteration for membership check
# GOOD: Use exists for early termination
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniorEmployees = organisation.departments.employees
        ->flatten()
        ->select(e | e.yearsOfService >= 10)
    in organisation.projects
        ->select(p | p.teamMembers->exists(tm | seniorEmployees->includes(tm)))
        ->collect(p | p.name)"

# Output: ["Cloud Migration", "Mobile App Redesign", ...] (projects with senior staff)

# Example 4: Lazy evaluation with let bindings
# Compute expensive operations once
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten()
    in let avgSalary = allEmployees->collect(e | e.salary)->sum() / allEmployees->size()
    in let aboveAverage = allEmployees->select(e | e.salary > avgSalary)
    in Tuple{
        average = avgSalary,
        aboveCount = aboveAverage->size(),
        abovePercent = (aboveAverage->size() * 100.0) / allEmployees->size()
    }"

# Output: {average: 128571.43, aboveCount: 8, abovePercent: 40.0}

# Example 5: Optimise with asSet for deduplication
# Remove duplicates early in the pipeline
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let uniqueSkills = organisation.departments.employees
        ->flatten()
        ->collect(e | e.skills)
        ->flatten()
        ->asSet()
    in Tuple{
        totalSkills = uniqueSkills->size(),
        skills = uniqueSkills->sortedBy(s | s)
    }"

# Output: {totalSkills: 12, skills: ["Agile", "Cloud", "Java", ...]}

# Example 6: Cache expensive lookups
# Store department lookup results for reuse
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let engDept = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in let prodDept = organisation.departments
        ->select(d | d.code = 'PROD')
        ->first()
    in let engBudget = engDept.budget +
        engDept.subDepartments->collect(d | d.budget)->sum()
    in let prodBudget = prodDept.budget +
        prodDept.subDepartments->collect(d | d.budget)->sum()
    in Tuple{
        engineering = engBudget,
        product = prodBudget,
        ratio = engBudget / prodBudget
    }"

# Output: {engineering: 3900000.0, product: 2200000.0, ratio: 1.77}

# Example 7: Optimise collection operations order
# Filter before expensive operations
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let highPriorityProjects = organisation.projects
        ->select(p | p.priority >= 8)
    in let projectTeams = highPriorityProjects
        ->collect(p | Tuple{
            project = p.name,
            teamSize = p.teamMembers->size(),
            totalSalary = p.teamMembers->collect(tm | tm.salary)->sum()
        })
    in projectTeams->sortedBy(t | t.totalSalary)->reverse()"

# Output: [{project: "Cloud Migration", teamSize: 10, totalSalary: 1450000}, ...]

# Example 8: Use forAll for universal quantification
# Short-circuit when first false is found
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeProjects = organisation.projects
        ->select(p | p.status = 'Active')
    in Tuple{
        allHaveTeams = activeProjects->forAll(p | p.teamMembers->size() > 0),
        allHighBudget = activeProjects->forAll(p | p.budget >= 300000),
        anyHighPriority = activeProjects->exists(p | p.priority >= 9)
    }"

# Output: {allHaveTeams: true, allHighBudget: true, anyHighPriority: true}

# Example 9: Shared sub-expression elimination
# Extract common sub-queries
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let qualifyingEmployees = organisation.departments.employees
        ->flatten()
        ->select(e | e.yearsOfService >= 5 and e.salary >= 120000)
    in let qualifyingProjects = organisation.projects
        ->select(p | p.teamMembers->exists(tm | qualifyingEmployees->includes(tm)))
    in Tuple{
        employeeCount = qualifyingEmployees->size(),
        projectCount = qualifyingProjects->size(),
        avgProjectBudget = qualifyingProjects
            ->collect(p | p.budget)
            ->sum() / qualifyingProjects->size()
    }"

# Output: {employeeCount: 12, projectCount: 4, avgProjectBudget: 387500.0}

# Example 10: Index-friendly patterns (conceptual)
# Structure queries to enable future index usage
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let targetDepartment = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in let targetEmployees = targetDepartment.employees
        ->union(targetDepartment.subDepartments.employees->flatten())
    in targetEmployees
        ->select(e | e.role = 'Senior Developer')
        ->collect(e | Tuple{name = e.name, salary = e.salary})"

# Output: [{name: "David Lee", salary: 160000}, ...]

# Example 11: Avoid redundant type checks
# Use let to store typed results
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allElements = organisation.eAllContents()
    in let allDepartments = allElements
        ->select(e | e.oclIsKindOf(Department))
        ->collect(d | d.oclAsType(Department))
    in let allEmployees = allElements
        ->select(e | e.oclIsKindOf(Employee))
        ->collect(e | e.oclAsType(Employee))
    in Tuple{
        deptCount = allDepartments->size(),
        empCount = allEmployees->size(),
        avgEmployeesPerDept = allEmployees->size() / allDepartments->size()
    }"

# Output: {deptCount: 9, empCount: 20, avgEmployeesPerDept: 2}

# Example 12: Batch operations together
# Combine multiple aggregations in one pass
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projects = organisation.projects
    in let budgets = projects->collect(p | p.budget)
    in Tuple{
        count = projects->size(),
        total = budgets->sum(),
        average = budgets->sum() / budgets->size(),
        min = budgets->min(),
        max = budgets->max()
    }"

# Output: {count: 5, total: 1650000, average: 330000, min: 150000, max: 500000}
