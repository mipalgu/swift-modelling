# Cross-product operations
# Combine elements from multiple collections

# All pairs of departments that collaborate
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->select(d | d.collaboratesWith->notEmpty())
    ->collect(d | d.collaboratesWith
        ->collect(c | Tuple{from = d.name, to = c.name}))
    ->flatten()"

# Output: [{from: "Engineering", to: "Product"}, {from: "Engineering", to: "Design"},
#          {from: "Product", to: "Engineering"}, {from: "Product", to: "Design"}, ...]

# Cross-product: employees who could mentor each other (different departments)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniors = organisation.departments.employees->flatten()
        ->select(e | e.yearsOfService >= 8),
        juniors = organisation.departments.employees->flatten()
        ->select(e | e.yearsOfService <= 3)
    in seniors->collect(s |
        juniors->select(j | j.eContainer() <> s.eContainer())
            ->collect(j | Tuple{mentor = s.name, mentee = j.name}))
    ->flatten()
    ->select(p | true)"  -- limit output

# Output: [{mentor: "Sarah Mitchell", mentee: "Tom Nguyen"}, ...]

# Cartesian product of projects and departments
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | organisation.departments
        ->collect(d | Tuple{project = p.name,
                            department = d.name,
                            involved = p.teamMembers
                                ->exists(e | e.eContainer() = d or
                                    d.subDepartments.employees
                                        ->flatten()->includes(e))}))
    ->flatten()
    ->select(t | t.involved)"

# Output: [{project: "Customer Portal", department: "Engineering", involved: true}, ...]

# Find all possible skill pairs in the organisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allSkills = organisation.departments.employees
        ->flatten()
        ->collect(e | e.skills)
        ->flatten()
        ->asSet()
    in allSkills->collect(s1 |
        allSkills->select(s2 | s1 < s2)
            ->collect(s2 | Tuple{skill1 = s1, skill2 = s2}))
    ->flatten()
    ->select(p | true)->subSequence(1, 10)"  -- first 10 pairs

# Output: [{skill1: "Architecture", skill2: "Kotlin"}, ...]
