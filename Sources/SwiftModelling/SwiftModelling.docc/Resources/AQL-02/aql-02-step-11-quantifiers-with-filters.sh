# Combining quantifiers with filtering
# Find departments where ALL professors have 10+ years experience
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments->select(d |
    d.professors->forAll(p | p.yearsExperience >= 10))"

# Output: [Department(Physics)]

# Find students enrolled in courses that have prerequisites
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s |
    s.enrolledIn->exists(c | c.prerequisites->notEmpty()))"

# Output: Students enrolled in at least one course with prerequisites

# Find courses where all prerequisites are level 100 or 200
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c |
    c.prerequisites->notEmpty() and
    c.prerequisites->forAll(p | p.level <= 200))"

# Output: Courses with only introductory prerequisites
