#!/bin/bash
# Performance best practices
# Efficient patterns for fast query execution

# Example 1: Use exists for early termination
# Stop searching as soon as first match is found
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->exists(d | d.budget > 2000000)"

# Output: true (stops at first department meeting criteria)

# Example 2: Use forAll with short-circuit evaluation
# Terminate on first failure
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->forAll(p | p.teamMembers->size() > 0)"

# Output: true (validates all projects have teams, stops on first empty team)

# Example 3: Avoid N+1 query pattern
# BAD: Iterating and looking up for each item
# GOOD: Collect all needed data first, then process
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projectTeamData = organisation.projects
        ->collect(p | Tuple{
            project = p.name,
            members = p.teamMembers->collect(tm | tm.name)
        })
    in projectTeamData"

# Output: [{project: "Cloud Migration", members: [...]}, ...]

# Example 4: Use asSet for deduplication early
# Remove duplicates before further processing
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let uniqueRoles = organisation.departments.employees
        ->flatten()
        ->collect(e | e.role)
        ->asSet()
    in uniqueRoles->size()"

# Output: 8 (unique roles across organisation)

# Example 5: Batch data collection
# Collect related data in one query instead of multiple
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let deptStats = organisation.departments
        ->collect(d | Tuple{
            name = d.name,
            code = d.code,
            employeeCount = d.employees->size(),
            totalSalary = d.employees->collect(e | e.salary)->sum(),
            subDeptCount = d.subDepartments->size()
        })
    in deptStats"

# Output: [{name: "Engineering", code: "ENG", employeeCount: 4, ...}, ...]

# Example 6: Use let for result caching
# Cache intermediate results to avoid recomputation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten()
    in let salaries = allEmployees->collect(e | e.salary)
    in let avg = salaries->sum() / salaries->size()
    in Tuple{
        belowAverage = allEmployees->select(e | e.salary < avg)->size(),
        atOrAbove = allEmployees->select(e | e.salary >= avg)->size()
    }"

# Output: {belowAverage: 12, atOrAbove: 8}

# Example 7: Minimise collection transformations
# Chain operations efficiently
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->flatten()
    ->select(e | e.yearsOfService >= 10)
    ->select(e | e.salary >= 120000)
    ->collect(e | e.name)
    ->sortedBy(n | n)"

# Output: ["David Lee", "Jessica Moore", "Olivia Martinez", "Sarah Mitchell", "William Anderson"]

# Example 8: Prefer isEmpty over size comparison
# Use isEmpty() instead of size() = 0 for better performance
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.employees->isEmpty())
    ->collect(d | d.name)"

# Output: [] (all departments have employees)

# Example 9: Use includes for membership tests
# More efficient than select with size check
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniorStaff = organisation.departments.employees
        ->flatten()
        ->select(e | e.yearsOfService >= 10)
    in organisation.projects
        ->select(p | p.teamMembers->exists(tm | seniorStaff->includes(tm)))
        ->size()"

# Output: 4 (projects with senior team members)

# Example 10: Flatten collections early
# Avoid nested iteration where possible
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allMilestones = organisation.projects
        ->collect(p | p.milestones)
        ->flatten()
    in allMilestones->select(m | m.completed)->size()"

# Output: 7 (completed milestones across all projects)

# Example 11: Use closure efficiently
# Limit closure depth with filtering
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let manager = organisation.departments.employees
        ->flatten()
        ->select(e | e.role = 'Director')
        ->first()
    in manager
        ->closure(e | e.directReports->select(r | r.yearsOfService >= 3))
        ->size()"

# Output: 8 (experienced staff in reporting chain)

# Example 12: Aggregate in single pass
# Calculate multiple statistics in one traversal
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in let salaries = employees->collect(e | e.salary)
    in Tuple{
        count = employees->size(),
        total = salaries->sum(),
        average = salaries->sum() / salaries->size(),
        minimum = salaries->min(),
        maximum = salaries->max()
    }"

# Output: {count: 20, total: 2571428.6, average: 128571.43, minimum: 85000, maximum: 180000}

# Example 13: Avoid redundant sorting
# Sort only when necessary and only once
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let topProjects = organisation.projects
        ->sortedBy(p | p.budget)
        ->reverse()
        ->select(p | p.status = 'Active')
        ->subSequence(1, 3)
    in topProjects->collect(p | Tuple{name = p.name, budget = p.budget})"

# Output: [{name: "Cloud Migration", budget: 500000}, ...]

# Example 14: Use selectByKind for type filtering
# More efficient than oclIsKindOf with select
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->collect(e | e.oclAsType(Employee))
    ->select(emp | emp.salary > 150000)
    ->size()"

# Output: 5 (high-earning employees)

# Example 15: Batch reference navigation
# Navigate references in batch rather than one-by-one
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let projectData = organisation.projects
        ->collect(p | Tuple{
            name = p.name,
            leadDept = p.leadDepartment.name,
            dependencyCount = p.dependencies->size()
        })
    in projectData"

# Output: [{name: "Cloud Migration", leadDept: "Engineering", dependencyCount: 0}, ...]

# Example 16: Minimise type casting
# Cast once and reuse
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let departments = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Department))
        ->collect(d | d.oclAsType(Department))
    in departments
        ->collect(d | Tuple{
            name = d.name,
            budget = d.budget,
            employeeCount = d.employees->size()
        })
        ->sortedBy(t | t.budget)
        ->reverse()"

# Output: [{name: "Engineering", budget: 2500000, employeeCount: 4}, ...]

# Example 17: Use first() instead of at(1)
# More semantic and potentially optimised
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.code = 'ENG')
    ->first()
    .name"

# Output: "Engineering"

# Example 18: Prefer any over exists with complex predicates
# Use simpler predicates with exists
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->exists(p | p.priority >= 9 and p.status = 'Active')"

# Output: true

# Example 19: Limit collection size early
# Filter before collect to reduce memory usage
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->flatten()
    ->select(e | e.salary >= 130000)
    ->collect(e | Tuple{
        name = e.name,
        salary = e.salary,
        role = e.role
    })
    ->sortedBy(t | t.salary)
    ->reverse()"

# Output: [{name: "Sarah Mitchell", salary: 180000, role: "Director"}, ...]

# Example 20: Combine filters for better optimisation
# Single complex predicate better than multiple selects (when possible)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->flatten()
    ->select(e | e.yearsOfService >= 10 and e.salary >= 120000 and e.skills->includes('Leadership'))
    ->collect(e | e.name)"

# Output: ["Sarah Mitchell", "David Lee", "Jessica Moore"]
