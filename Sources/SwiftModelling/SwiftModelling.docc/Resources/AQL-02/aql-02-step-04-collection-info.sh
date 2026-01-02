# Collection size and emptiness checks
# Count all students
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->size()"

# Output: 10

# Check if there are any students
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->notEmpty()"

# Output: true

# Check for empty prerequisites on introductory courses
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.prerequisites->isEmpty())->size()"

# Output: 3 (CS101, MATH101, and one other have no prerequisites)
