# Universal quantification with forAll
# Check if all students have passing grades
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->forAll(s | s.grade >= 60)"

# Output: false (Ian has 58.0)

# Check if all courses have at least 3 credits
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->forAll(c | c.credits >= 3)"

# Output: true

# Check if all professors teach at least one course
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors->forAll(p | p.teaches->notEmpty())"

# Output: true
