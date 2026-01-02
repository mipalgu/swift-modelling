#!/bin/bash
# Transitive closure operations
# Following references recursively to find all reachable elements

# Example 1: Basic closure - find all direct reports recursively
# Get all employees reporting to a manager (directly or indirectly)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let manager = organisation.departments.employees
        ->flatten()
        ->select(e | e.name = 'Sarah Mitchell')
        ->first()
    in manager->closure(e | e.directReports)->size()"

# Output: 6 (all employees in the management chain)

# Example 2: Closure with filtering
# Find all skilled employees in a mentor network
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniorDev = organisation.departments.employees
        ->flatten()
        ->select(e | e.name = 'David Lee')
        ->first()
    in seniorDev->closure(e | e.mentors)
        ->select(m | m.skills->includes('Leadership'))
        ->size()"

# Output: 2 (mentors with leadership skills in the network)

# Example 3: Project dependency closure
# Find all projects that a project depends on (transitively)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let project = organisation.projects
        ->select(p | p.code = 'PROJ-001')
        ->first()
    in project->closure(p | p.dependencies)->size()"

# Output: 2 (all transitive dependencies)

# Example 4: Department collaboration network
# Find all departments connected through collaboration
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let engineeringDept = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in engineeringDept->closure(d | d.collaboratesWith)
        ->collect(d | d.name)"

# Output: ["Product Management", "Marketing", "Sales"] (all collaborative partners)

# Example 5: Sub-department hierarchy closure
# Get all nested sub-departments at any depth
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let topDept = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in topDept->closure(d | d.subDepartments)->size()"

# Output: 2 (all nested sub-departments)

# Example 6: Closure with conditional navigation
# Find all high-budget dependent projects
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let mainProject = organisation.projects
        ->select(p | p.code = 'PROJ-001')
        ->first()
    in mainProject->closure(p | p.dependencies->select(dep | dep.budget >= 200000.0))
        ->collect(p | p.name)"

# Output: ["Cloud Migration"] (high-budget dependencies only)

# Example 7: Mentor network analysis
# Find all mentors in an employee's mentor chain
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employee = organisation.departments.employees
        ->flatten()
        ->select(e | e.name = 'Emily Rodriguez')
        ->first()
    in employee->closure(e | e.mentors)
        ->collect(m | Tuple{name = m.name, role = m.role})"

# Output: [{name: "David Lee", role: "Senior Developer"}, ...] (all mentors)

# Example 8: Closure for skill propagation
# Find all employees in supervision chain with specific skills
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let teamLead = organisation.departments.employees
        ->flatten()
        ->select(e | e.role = 'Team Lead')
        ->first()
    in teamLead->closure(e | e.directReports)
        ->select(emp | emp.skills->includes('Python'))
        ->collect(emp | emp.name)"

# Output: ["Michael Chen", "Jessica Moore"] (team members with Python skills)

# Example 9: Combined closure for cross-cutting analysis
# Find all projects involving employees in a management hierarchy
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let director = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
        .manager
    in let allReports = director->closure(e | e.directReports)
    in organisation.projects
        ->select(p | p.teamMembers->exists(tm | allReports->includes(tm)))
        ->collect(p | p.name)"

# Output: ["Cloud Migration", "Mobile App Redesign", ...] (projects with team members)

# Example 10: Deep closure with aggregation
# Calculate total team size across project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let project = organisation.projects
        ->select(p | p.priority >= 9)
        ->first()
    in let allRelatedProjects = project->closure(p | p.dependencies)
        ->including(project)
    in Tuple{
        projectCount = allRelatedProjects->size(),
        totalTeamSize = allRelatedProjects
            ->collect(p | p.teamMembers->size())
            ->sum(),
        uniqueEmployees = allRelatedProjects
            ->collect(p | p.teamMembers)
            ->flatten()
            ->asSet()
            ->size()
    }"

# Output: {projectCount: 3, totalTeamSize: 24, uniqueEmployees: 15}

# Example 11: Closure for reachability analysis
# Determine if two departments are connected through collaboration
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let startDept = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in let targetDept = organisation.departments
        ->select(d | d.code = 'SALES')
        ->first()
    in startDept->closure(d | d.collaboratesWith)
        ->includes(targetDept)"

# Output: true (departments are connected)

# Example 12: Closure with set operations
# Find common projects in dependency chains
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let proj1 = organisation.projects->at(1)
    in let proj2 = organisation.projects->at(2)
    in let deps1 = proj1->closure(p | p.dependencies)
    in let deps2 = proj2->closure(p | p.dependencies)
    in deps1->intersection(deps2)->size()"

# Output: 1 (shared dependencies)
