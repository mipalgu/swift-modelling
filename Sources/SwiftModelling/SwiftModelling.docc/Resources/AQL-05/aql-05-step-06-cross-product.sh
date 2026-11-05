# Cross-product operations
# Combine elements from multiple collections

# All pairs of departments that collaborate
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.collaboratesWith->notEmpty())
    ->collect(d | d.collaboratesWith
        ->collect(c | d.name + ' -> ' + c.name))"

# Output: ["Engineering -> Product", "Engineering -> Design", "Product -> Engineering", "Product -> Design", "Design -> Engineering", "Design -> Product"]

# Cross-product: possible mentoring pairs across different departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniors = organisation.departments.employees
        ->select(e | e.yearsOfService >= 8),
        juniors = organisation.departments.employees
        ->select(e | e.yearsOfService <= 3)
    in seniors->collect(s |
        juniors->select(j | j.eContainer() <> s.eContainer())
            ->collect(j | s.name + ' could mentor ' + j.name))"

# Output: ["Sarah Mitchell could mentor Ryan Hughes", "Sarah Mitchell could mentor Mia Thompson", ..., "Emma Wilson could mentor Alex Rivera"]

# Cartesian product of projects and departments, keeping involved pairs
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | organisation.departments
        ->select(d | p.teamMembers
            ->exists(e | e.eContainer() = d or
                d.subDepartments.employees->includes(e)))
        ->collect(d | p.name + ' involves ' + d.name))"

# Output: ["Customer Portal involves Engineering", "Customer Portal involves Product", "Customer Portal involves Design", "Infrastructure Modernisation involves Engineering", ..., "Analytics Dashboard involves Product"]

# The first ten skill pairs in the organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allSkills = organisation.departments.employees
        ->collect(e | e.skills)
        ->asSet()
    in allSkills->collect(s1 |
        allSkills->select(s2 | s1 < s2)
            ->collect(s2 | s1 + ' + ' + s2))
    ->asSequence()
    ->subSequence(1, 10)"

# Output: ["Leadership + Strategy", "Leadership + Swift", "Leadership + Python", ..., "Leadership + Sketch"]
