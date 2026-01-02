# Impact analysis queries
# Assess the impact of changes or events

# Impact of employee departure
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments.employees->flatten()
    ->collect(e | Tuple{
        employee = e.name,
        role = e.role,
        projectsAffected = e.assignedProjects->size(),
        directReportsAffected = e.directReports->size(),
        menteesAffected = organisation.departments.employees
            ->flatten()
            ->select(emp | emp.mentors->includes(e))->size(),
        impactScore = e.assignedProjects->size() * 10
            + e.directReports->size() * 20
            + organisation.departments.employees->flatten()
                ->select(emp | emp.mentors->includes(e))->size() * 5})
    ->sortedBy(t | -t.impactScore)"

# Output: [{employee: "Sarah Mitchell", role: "Engineering Director",
#           projectsAffected: 2, directReportsAffected: 1, menteesAffected: 1,
#           impactScore: 45}]

# Budget cut impact analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let cutPercentage = 20
    in organisation.departments
        ->collect(d | let newBudget = d.budget * (100 - cutPercentage) / 100,
            currentSalaryCost = d.employees->collect(e | e.salary)->sum()
        in Tuple{
            department = d.name,
            currentBudget = d.budget,
            proposedBudget = newBudget,
            salaryCost = currentSalaryCost,
            surplusAfterCut = newBudget - currentSalaryCost,
            viable = newBudget >= currentSalaryCost})"

# Output: [{department: "Engineering", currentBudget: 2500000, proposedBudget: 2000000,
#           salaryCost: 570000, surplusAfterCut: 1430000, viable: true}]

# Project delay impact
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | Tuple{
        project = p.name,
        wouldDelay = organisation.projects
            ->select(other | other.dependencies->includes(p))
            ->collect(o | o.name),
        cascadeDepth = organisation.projects
            ->select(other | other.dependencies->includes(p))
            ->collect(delayed | organisation.projects
                ->select(further | further.dependencies->includes(delayed)))
            ->flatten()
            ->asSet()
            ->collect(f | f.name)})"

# Output: [{project: "Customer Portal", wouldDelay: ["Infrastructure...", "Analytics..."],
#           cascadeDepth: ["Analytics Dashboard"]}]

# Skill gap impact if employees leave
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten(),
        uniqueSkills = allEmployees
            ->collect(e | e.skills)->flatten()->asSet()
    in uniqueSkills
        ->collect(skill | Tuple{
            skill = skill,
            holders = allEmployees->select(e | e.skills->includes(skill))
                ->collect(e | e.name),
            singlePointOfFailure = allEmployees
                ->select(e | e.skills->includes(skill))->size() = 1})
        ->select(t | t.singlePointOfFailure)"

# Output: [{skill: "SupplyChain", holders: ["William Anderson"], singlePointOfFailure: true}]

# Department reorganisation impact
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let deptToMerge = organisation.departments
        ->select(d | d.code = 'DES')->first()
    in Tuple{
        departmentToMerge = deptToMerge.name,
        employeesAffected = deptToMerge.employees->size(),
        projectsAffected = organisation.projects
            ->select(p | p.teamMembers
                ->exists(e | e.eContainer() = deptToMerge))
            ->collect(p | p.name),
        collaborationsAffected = organisation.departments
            ->select(d | d.collaboratesWith->includes(deptToMerge))
            ->collect(d | d.name)}"

# Output: {departmentToMerge: "Design", employeesAffected: 4,
#          projectsAffected: ["Customer Portal", "Mobile App Redesign"],
#          collaborationsAffected: ["Engineering", "Product"]}

# Priority change impact
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects->select(p | p.priority = 1)
    ->collect(p | Tuple{
        project = p.name,
        currentTeam = p.teamMembers->collect(e | e.name),
        conflictsWith = organisation.projects
            ->select(other | other.priority = 1 and other <> p)
            ->select(other | other.teamMembers
                ->intersection(p.teamMembers)->notEmpty())
            ->collect(other | Tuple{
                project = other.name,
                sharedResources = other.teamMembers
                    ->intersection(p.teamMembers)
                    ->collect(e | e.name)})})"

# Output: [{project: "Customer Portal", currentTeam: [...],
#           conflictsWith: [{project: "Mobile App Redesign", sharedResources: [...]}]}]
