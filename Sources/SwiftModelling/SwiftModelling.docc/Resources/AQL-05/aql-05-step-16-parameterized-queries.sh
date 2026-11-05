# Dependency analysis patterns
# Analyse dependencies and impacts

# Direct dependencies and dependants of each project
# (a project needed by two or more others is critical)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let dependants = organisation.projects
            ->select(other | other.dependencies->includes(p))
        in p.name + ': depends on ' + p.dependencies->size().toString()
            + ', needed by ' + dependants->size().toString()
            + ', critical: ' + (dependants->size() >= 2).toString())"

# Output: ["Customer Portal: depends on 0, needed by 2, critical: true", "Infrastructure Modernisation: depends on 1, needed by 1, critical: false", "Mobile App Redesign: depends on 0, needed by 0, critical: false", "Analytics Dashboard: depends on 2, needed by 0, critical: false"]

# Skill dependency analysis (which skills are most common)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allSkills = organisation.departments.employees
        ->collect(e | e.skills)
    in allSkills->asSet()
        ->sortedBy(s | -allSkills->select(sk | sk = s)->size())
        ->collect(s | s + ': ' + allSkills->select(sk | sk = s)->size().toString())"

# Output: ["Swift: 3", "Figma: 3", "Leadership: 2", "Strategy: 2", "Architecture: 2", "Analytics: 2", "UserResearch: 2", "Kotlin: 1", ..., "Reporting: 1"]

# Department collaboration dependencies: shared projects
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.collaboratesWith->notEmpty())
    ->collect(d | organisation.projects
        ->select(p | p.teamMembers
            ->exists(e | e.eContainer() = d or
                d.subDepartments.employees->includes(e)) and
            p.teamMembers->exists(e | d.collaboratesWith
                ->exists(c | e.eContainer() = c or
                    c.subDepartments.employees->includes(e))))
        ->collect(p | d.name + ' shares ' + p.name))"

# Output: ["Engineering shares Customer Portal", "Engineering shares Mobile App Redesign", "Product shares Customer Portal", "Product shares Mobile App Redesign", "Design shares Customer Portal", "Design shares Mobile App Redesign"]

# Employee dependency: key people on the first project
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let criticalProject = organisation.projects->first()
    in criticalProject.teamMembers
        ->select(e | e.role.endsWith('Director') or e.role.endsWith('Lead'))
        ->collect(e | e.name + ' (' + e.role + '): direct reports '
            + e.directReports->size().toString() + ', on this project '
            + e.directReports->intersection(criticalProject.teamMembers)->size().toString()
            + ' of ' + criticalProject.teamMembers->size().toString())"

# Output: ["Sarah Mitchell (Engineering Director): direct reports 1, on this project 1 of 9", "Rachel Adams (Mobile Lead): direct reports 2, on this project 1 of 9", ..., "Olivia Martinez (Design Director): direct reports 2, on this project 1 of 9"]

# Find bottleneck projects (dependencies with incomplete milestones)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->select(p | p.dependencies->notEmpty() or
        organisation.projects->exists(other | other.dependencies->includes(p)))
    ->collect(p | let blockedBy = p.dependencies
            ->select(d | d.milestones->reject(m | m.completed)->notEmpty())
        in p.name + ': blocked by ' + blockedBy->size().toString()
            + ', blocking '
            + organisation.projects
                ->select(other | other.dependencies->includes(p))
                ->size().toString()
            + ', risk ' + if blockedBy->notEmpty() then 'HIGH' else 'LOW' endif)"

# Output: ["Customer Portal: blocked by 0, blocking 2, risk LOW", "Infrastructure Modernisation: blocked by 1, blocking 1, risk HIGH", "Analytics Dashboard: blocked by 2, blocking 0, risk HIGH"]

# Resource allocation dependencies (two or more priority 1 projects)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees
    ->select(e | e.assignedProjects->size() >= 2)
    ->collect(e | e.name + ': projects ' + e.assignedProjects->size().toString()
        + ', over-allocation risk: '
        + (e.assignedProjects->select(p | p.priority = 1)->size() >= 2).toString())"

# Output: ["Sarah Mitchell: projects 2, over-allocation risk: false", "Emily Chen: projects 2, over-allocation risk: true", "Jessica Moore: projects 3, over-allocation risk: true", "Sophie Garcia: projects 2, over-allocation risk: false", "Olivia Martinez: projects 2, over-allocation risk: true"]
