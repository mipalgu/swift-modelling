# Nested quantifier operations
# Find departments where at least one professor teaches
# a course that has prerequisites
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments->select(d |
    d.professors->exists(p |
      p.teaches->exists(c | c.prerequisites->notEmpty())))"

# Output: Departments with professors teaching advanced courses

# Check if all departments have at least one experienced professor
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments->forAll(d |
    d.professors->exists(p | p.yearsExperience >= 10))"

# Output: true

# Find students whose all courses have 4 credits
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s |
    s.enrolledIn->notEmpty() and
    s.enrolledIn->forAll(c | c.credits = 4))"

# Output: Students enrolled only in 4-credit courses
