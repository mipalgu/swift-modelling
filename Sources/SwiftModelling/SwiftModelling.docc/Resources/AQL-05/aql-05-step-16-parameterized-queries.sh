# Dependency analysis patterns
# Analyse dependencies and impacts

# Direct and indirect project dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        directDeps = p.dependencies->size(),
        dependentOn = organisation.projects
            ->select(other | other.dependencies->includes(p))
            ->collect(o | o.name),
        isCritical = organisation.projects
            ->select(other | other.dependencies->includes(p))
            ->size() >= 2})"

# Output: [{project: "Customer Portal", directDeps: 0, dependentOn: ["Infrastructure...", "Analytics..."],
#           isCritical: true}]

# Skill dependency analysis (what skills are most needed)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allSkills = organisation.departments.employees
        ->flatten()
        ->collect(e | e.skills)
        ->flatten()
    in allSkills->asSet()
        ->collect(s | Tuple{
            skill = s,
            employeeCount = allSkills->select(sk | sk = s)->size()})
        ->sortedBy(t | -t.employeeCount)"

# Output: [{skill: "Swift", employeeCount: 4}, {skill: "Figma", employeeCount: 3}, ...]

# Department collaboration dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.collaboratesWith->notEmpty())
    ->collect(d | Tuple{
        department = d.name,
        collaborators = d.collaboratesWith->collect(c | c.name),
        sharedProjects = organisation.projects
            ->select(p | p.teamMembers
                ->exists(e | e.eContainer() = d or
                    d.subDepartments.employees->flatten()->includes(e)) and
                p.teamMembers->exists(e | d.collaboratesWith
                    ->exists(c | e.eContainer() = c or
                        c.subDepartments.employees->flatten()->includes(e))))
            ->collect(p | p.name)})"

# Output: [{department: "Engineering", collaborators: ["Product", "Design"],
#           sharedProjects: ["Customer Portal", "Mobile App Redesign"]}]

# Employee dependency (who depends on whom via projects)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let criticalProject = organisation.projects->first()
    in criticalProject.teamMembers
        ->select(e | e.role.endsWith('Director') or e.role.endsWith('Lead'))
        ->collect(e | Tuple{
            keyPerson = e.name,
            role = e.role,
            directReports = e.directReports->collect(r | r.name),
            projectTeamSize = criticalProject.teamMembers->size(),
            impactIfLeaves = e.directReports
                ->intersection(criticalProject.teamMembers)->size()})"

# Output: [{keyPerson: "Sarah Mitchell", role: "Engineering Director", ...}]

# Find bottleneck projects (many dependencies, few completed milestones)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->select(p | p.dependencies->notEmpty() or
        organisation.projects->exists(other | other.dependencies->includes(p)))
    ->collect(p | Tuple{
        project = p.name,
        blockedBy = p.dependencies
            ->select(d | d.milestones->reject(m | m.completed)->notEmpty())
            ->collect(d | d.name),
        blocking = organisation.projects
            ->select(other | other.dependencies->includes(p))
            ->collect(o | o.name),
        riskLevel = if p.dependencies
            ->exists(d | d.milestones->reject(m | m.completed)->notEmpty())
            then 'HIGH' else 'LOW' endif})"

# Output: [{project: "Analytics Dashboard", blockedBy: ["Customer Portal", "Infrastructure..."],
#           blocking: [], riskLevel: "HIGH"}]

# Resource allocation dependencies
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->select(e | e.assignedProjects->size() >= 2)
    ->collect(e | Tuple{
        employee = e.name,
        projectCount = e.assignedProjects->size(),
        projects = e.assignedProjects->collect(p | p.name),
        overallocationRisk = e.assignedProjects
            ->select(p | p.priority = 1)->size() >= 2})"

# Output: [{employee: "Sarah Mitchell", projectCount: 2, projects: [...],
#           overallocationRisk: true}]
