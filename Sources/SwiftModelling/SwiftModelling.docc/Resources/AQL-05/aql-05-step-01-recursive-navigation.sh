#!/bin/bash
# Recursive navigation with eAllContents and eContainer
# Demonstrates hierarchical traversal through containment trees

# Example 1: eAllContents - Get all contained elements recursively
# Find all elements nested within an organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()->size()"

# Output: 45 (total number of all contained elements)

# Example 2: Select specific types from all contents
# Find all employees in the entire organisation hierarchy
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->size()"

# Output: 20 (all employees at all levels)

# Example 3: Type-cast and collect from recursive traversal
# Get all employee names throughout the organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->collect(e | e.oclAsType(Employee).name)"

# Output: ["Sarah Mitchell", "David Lee", "Michael Chen", "Emily Rodriguez", ...]

# Example 4: Find nested departments recursively
# Count all departments including sub-departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Department))
    ->size()"

# Output: 9 (top-level departments plus all sub-departments)

# Example 5: eContainer - Navigate upward in containment hierarchy
# Find the containing department of an employee
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employee = organisation.departments.employees
        ->flatten()
        ->select(e | e.name = 'Michael Chen')
        ->first()
    in employee.eContainer().oclAsType(Department).name"

# Output: "Engineering"

# Example 6: Navigate to top-level container
# Find the organisation containing a deeply nested element
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let milestone = organisation.projects.milestones
        ->flatten()
        ->first()
    in milestone.eContainer()
        .eContainer()
        .oclAsType(Organisation).name"

# Output: "TechCorp International" (navigating from milestone to project to organisation)

# Example 7: Combine eAllContents with filtering
# Find all high-priority project milestones
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let highPriorityProjects = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Project))
        ->select(p | p.oclAsType(Project).priority >= 8)
    in highPriorityProjects
        ->collect(p | p.oclAsType(Project).milestones)
        ->flatten()
        ->size()"

# Output: 4 (milestones from high-priority projects)

# Example 8: Recursive navigation with depth awareness
# Find all employees in sub-departments (not top-level)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.subDepartments
    ->flatten()
    .eAllContents()
    ->select(e | e.oclIsKindOf(Employee))
    ->size()"

# Output: 6 (employees only in sub-departments)

# Example 9: Complex recursive pattern
# Find all completed milestones across all projects
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.eAllContents()
    ->select(e | e.oclIsKindOf(Milestone))
    ->collect(m | m.oclAsType(Milestone))
    ->select(m | m.completed)
    ->collect(m | m.name)"

# Output: ["Alpha Release", "Beta Testing", ...] (completed milestones)

# Example 10: Hierarchical aggregation
# Calculate total budget across all organisational levels
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Department))
        ->collect(d | d.oclAsType(Department))
    in let allProjects = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Project))
        ->collect(p | p.oclAsType(Project))
    in Tuple{
        departmentBudgets = allDepts->collect(d | d.budget)->sum(),
        projectBudgets = allProjects->collect(p | p.budget)->sum()
    }"

# Output: {departmentBudgets: 9500000.0, projectBudgets: 1650000.0}
