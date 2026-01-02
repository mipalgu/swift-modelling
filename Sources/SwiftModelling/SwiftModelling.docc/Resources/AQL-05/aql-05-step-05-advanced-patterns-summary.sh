#!/bin/bash
# Advanced AQL patterns summary
# Combining techniques for real-world query scenarios

# Example 1: Comprehensive organisational analysis
# Combines recursive navigation, closure, and optimisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepartments = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Department))
        ->collect(d | d.oclAsType(Department))
    in let allEmployees = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Employee))
        ->collect(e | e.oclAsType(Employee))
    in let avgSalary = allEmployees->collect(e | e.salary)->sum() / allEmployees->size()
    in Tuple{
        organisationName = organisation.name,
        totalDepartments = allDepartments->size(),
        totalEmployees = allEmployees->size(),
        averageSalary = avgSalary,
        highEarners = allEmployees->select(e | e.salary > avgSalary * 1.2)->size(),
        totalBudget = allDepartments->collect(d | d.budget)->sum()
    }"

# Output: {organisationName: "TechCorp International", totalDepartments: 9, totalEmployees: 20, ...}

# Example 2: Cross-departmental collaboration analysis
# Uses closure and set operations
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let engineeringDept = organisation.departments
        ->select(d | d.code = 'ENG')
        ->first()
    in let collaboratingDepts = engineeringDept->closure(d | d.collaboratesWith)
    in let engProjects = organisation.projects
        ->select(p | p.leadDepartment = engineeringDept)
    in let collabProjects = organisation.projects
        ->select(p | collaboratingDepts->includes(p.leadDepartment))
    in Tuple{
        engineeringProjects = engProjects->size(),
        collaboratingProjects = collabProjects->size(),
        sharedEmployees = engProjects
            ->collect(p | p.teamMembers)
            ->flatten()
            ->asSet()
            ->intersection(collabProjects->collect(p | p.teamMembers)->flatten()->asSet())
            ->size()
    }"

# Output: {engineeringProjects: 2, collaboratingProjects: 3, sharedEmployees: 8}

# Example 3: Project dependency impact analysis
# Transitive closure with performance optimisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let criticalProjects = organisation.projects
        ->select(p | p.priority >= 9)
    in let impactAnalysis = criticalProjects
        ->collect(p |
            let dependencies = p->closure(proj | proj.dependencies)
            in Tuple{
                project = p.name,
                dependencyCount = dependencies->size(),
                affectedTeamSize = dependencies
                    ->collect(dep | dep.teamMembers)
                    ->flatten()
                    ->asSet()
                    ->size(),
                totalBudgetImpact = dependencies
                    ->collect(dep | dep.budget)
                    ->sum() + p.budget
            })
    in impactAnalysis->sortedBy(t | t.totalBudgetImpact)->reverse()"

# Output: [{project: "Cloud Migration", dependencyCount: 0, affectedTeamSize: 10, totalBudgetImpact: 500000}, ...]

# Example 4: Talent pool and skill matrix
# Recursive navigation with aggregation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Employee))
        ->collect(e | e.oclAsType(Employee))
    in let skillInventory = allEmployees
        ->collect(e | e.skills)
        ->flatten()
        ->asSet()
        ->collect(skill |
            let skilledEmployees = allEmployees->select(e | e.skills->includes(skill))
            in Tuple{
                skill = skill,
                employeeCount = skilledEmployees->size(),
                avgSalary = skilledEmployees->collect(e | e.salary)->sum() / skilledEmployees->size(),
                avgExperience = skilledEmployees->collect(e | e.yearsOfService)->sum() / skilledEmployees->size()
            })
    in skillInventory->sortedBy(t | t.employeeCount)->reverse()"

# Output: [{skill: "Java", employeeCount: 8, avgSalary: 135000, avgExperience: 7.5}, ...]

# Example 5: Management hierarchy analysis
# Closure for reporting chains with metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let topManagers = organisation.departments.employees
        ->flatten()
        ->select(e | e.role = 'Director' or e.role = 'VP')
    in topManagers->collect(manager |
        let allReports = manager->closure(e | e.directReports)
        in let managedProjects = organisation.projects
            ->select(p | p.teamMembers->exists(tm | allReports->includes(tm) or tm = manager))
        in Tuple{
            manager = manager.name,
            role = manager.role,
            directReports = manager.directReports->size(),
            totalReports = allReports->size(),
            projectsLed = managedProjects->size(),
            teamBudget = allReports->collect(e | e.salary)->sum() + manager.salary
        })"

# Output: [{manager: "Sarah Mitchell", role: "Director", directReports: 3, totalReports: 6, ...}, ...]

# Example 6: Resource allocation optimisation
# Let bindings with complex filtering
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let activeProjects = organisation.projects
        ->select(p | p.status = 'Active')
    in let availableEmployees = organisation.departments.employees
        ->flatten()
        ->select(e | e.assignedProjects->size() < 2)
    in let recommendations = availableEmployees
        ->collect(emp |
            let suitableProjects = activeProjects
                ->select(p |
                    p.teamMembers->size() < 12 and
                    p.leadDepartment.employees->includes(emp))
            in Tuple{
                employee = emp.name,
                role = emp.role,
                currentProjects = emp.assignedProjects->size(),
                recommendedProjects = suitableProjects->collect(p | p.name)
            })
        ->select(r | r.recommendedProjects->size() > 0)
    in recommendations"

# Output: [{employee: "Michael Chen", role: "Developer", currentProjects: 1, recommendedProjects: [...]}, ...]

# Example 7: Performance benchmarking across departments
# Nested let bindings with statistical analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let topLevelDepts = organisation.departments
    in topLevelDepts->collect(dept |
        let allSubDepts = dept->closure(d | d.subDepartments)->including(dept)
        in let allEmployees = allSubDepts->collect(d | d.employees)->flatten()
        in let allProjects = organisation.projects
            ->select(p | p.leadDepartment = dept or allSubDepts->includes(p.leadDepartment))
        in Tuple{
            department = dept.name,
            totalBudget = allSubDepts->collect(d | d.budget)->sum(),
            employeeCount = allEmployees->size(),
            projectCount = allProjects->size(),
            avgSalary = allEmployees->collect(e | e.salary)->sum() / allEmployees->size(),
            budgetPerEmployee = allSubDepts->collect(d | d.budget)->sum() / allEmployees->size(),
            activeProjectRatio = allProjects->select(p | p.status = 'Active')->size() / allProjects->size()
        })
    ->sortedBy(t | t.budgetPerEmployee)->reverse()"

# Output: [{department: "Engineering", totalBudget: 3900000, employeeCount: 10, ...}, ...]

# Example 8: Risk assessment across project portfolio
# Combines multiple advanced patterns
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allProjects = organisation.projects
    in allProjects->collect(project |
        let dependencies = project->closure(p | p.dependencies)
        in let criticalPath = dependencies->select(d | d.priority >= 8)
        in let teamExperience = project.teamMembers
            ->collect(tm | tm.yearsOfService)
            ->sum() / project.teamMembers->size()
        in let seniorCount = project.teamMembers
            ->select(tm | tm.role->matches('Senior.*') or tm.role = 'Director')
            ->size()
        in Tuple{
            project = project.name,
            priority = project.priority,
            status = project.status,
            dependencyRisk = dependencies->size(),
            criticalDependencies = criticalPath->size(),
            teamExperience = teamExperience,
            seniorStaffRatio = seniorCount / project.teamMembers->size(),
            riskScore = (dependencies->size() * 10) +
                       (criticalPath->size() * 20) -
                       (teamExperience * 5) -
                       (seniorCount * 15)
        })
    ->sortedBy(t | t.riskScore)->reverse()"

# Output: [{project: "Mobile App Redesign", priority: 8, status: "Active", riskScore: 45, ...}, ...]

# Example 9: Knowledge transfer network analysis
# Closure with mentor relationships
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten()
    in let mentorshipNetwork = allEmployees
        ->select(e | e.mentors->size() > 0)
        ->collect(emp |
            let mentorChain = emp->closure(e | e.mentors)
            in Tuple{
                employee = emp.name,
                role = emp.role,
                directMentors = emp.mentors->size(),
                totalMentors = mentorChain->size(),
                seniorMentors = mentorChain
                    ->select(m | m.yearsOfService >= 10)
                    ->size(),
                skillsAccessible = mentorChain
                    ->collect(m | m.skills)
                    ->flatten()
                    ->asSet()
                    ->size()
            })
    in mentorshipNetwork->sortedBy(t | t.skillsAccessible)->reverse()"

# Output: [{employee: "Emily Rodriguez", role: "Developer", directMentors: 1, totalMentors: 2, ...}, ...]

# Example 10: Budget allocation efficiency analysis
# Comprehensive financial analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allDepts = organisation.eAllContents()
        ->select(e | e.oclIsKindOf(Department))
        ->collect(d | d.oclAsType(Department))
    in let allProjects = organisation.projects
    in let totalDeptBudget = allDepts->collect(d | d.budget)->sum()
    in let totalProjectBudget = allProjects->collect(p | p.budget)->sum()
    in let totalSalaryCommitment = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)
        ->sum()
    in Tuple{
        organisational = Tuple{
            departmentBudgets = totalDeptBudget,
            projectBudgets = totalProjectBudget,
            salaryCommitments = totalSalaryCommitment,
            totalCommitted = totalDeptBudget + totalProjectBudget
        },
        efficiency = Tuple{
            salaryToProjectRatio = totalSalaryCommitment / totalProjectBudget,
            budgetUtilisation = totalProjectBudget / totalDeptBudget,
            avgProjectBudget = totalProjectBudget / allProjects->size(),
            avgDeptBudget = totalDeptBudget / allDepts->size()
        },
        activeMetrics = Tuple{
            activeProjects = allProjects->select(p | p.status = 'Active')->size(),
            activeBudget = allProjects
                ->select(p | p.status = 'Active')
                ->collect(p | p.budget)
                ->sum(),
            activeEmployees = allProjects
                ->select(p | p.status = 'Active')
                ->collect(p | p.teamMembers)
                ->flatten()
                ->asSet()
                ->size()
        }
    }"

# Output: {organisational: {...}, efficiency: {...}, activeMetrics: {...}}

# Example 11: Real-world scenario - quarterly review preparation
# Combined pattern for executive reporting
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let quarterlyReport =
        let allDepts = organisation.departments
        in let allEmployees = allDepts.employees->flatten()
        in let allProjects = organisation.projects
        in let activeProjects = allProjects->select(p | p.status = 'Active')
        in Tuple{
            summary = Tuple{
                organisation = organisation.name,
                departments = allDepts->size(),
                employees = allEmployees->size(),
                projects = allProjects->size(),
                activeProjects = activeProjects->size()
            },
            workforce = Tuple{
                averageSalary = allEmployees->collect(e | e.salary)->sum() / allEmployees->size(),
                averageTenure = allEmployees->collect(e | e.yearsOfService)->sum() / allEmployees->size(),
                seniorStaff = allEmployees->select(e | e.yearsOfService >= 10)->size(),
                rolesCount = allEmployees->collect(e | e.role)->asSet()->size()
            },
            projects = Tuple{
                totalBudget = allProjects->collect(p | p.budget)->sum(),
                activeBudget = activeProjects->collect(p | p.budget)->sum(),
                avgTeamSize = activeProjects->collect(p | p.teamMembers->size())->sum() / activeProjects->size(),
                highPriority = allProjects->select(p | p.priority >= 9)->size()
            },
            skills = Tuple{
                uniqueSkills = allEmployees->collect(e | e.skills)->flatten()->asSet()->size(),
                topSkills = allEmployees
                    ->collect(e | e.skills)
                    ->flatten()
                    ->asSet()
                    ->sortedBy(s | s)
                    ->subSequence(1, 5)
            }
        }
    in quarterlyReport"

# Output: {summary: {...}, workforce: {...}, projects: {...}, skills: {...}}

# Example 12: Best practices recap
# Demonstrates all key optimisation techniques in one query
swift-aql evaluate --model enterprise-data.xmi \
  --expression "
    -- Use let bindings to cache results
    let allEmployees = organisation.departments.employees->flatten()

    -- Filter early to reduce data
    in let qualifiedEmployees = allEmployees->select(e | e.yearsOfService >= 5)

    -- Use asSet to deduplicate
    in let uniqueSkills = qualifiedEmployees->collect(e | e.skills)->flatten()->asSet()

    -- Use exists for short-circuit evaluation
    in let hasLeadership = uniqueSkills->exists(s | s = 'Leadership')

    -- Batch related operations
    in let salaries = qualifiedEmployees->collect(e | e.salary)

    -- Combine aggregations in single pass
    in Tuple{
        employeeCount = qualifiedEmployees->size(),
        skillCount = uniqueSkills->size(),
        hasLeadershipSkill = hasLeadership,
        avgSalary = salaries->sum() / salaries->size(),
        maxSalary = salaries->max(),
        minSalary = salaries->min()
    }"

# Output: {employeeCount: 15, skillCount: 12, hasLeadershipSkill: true, avgSalary: 142000, ...}
