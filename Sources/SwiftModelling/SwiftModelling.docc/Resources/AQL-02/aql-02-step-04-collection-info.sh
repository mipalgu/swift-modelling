# Collection size and emptiness checks
# Count all students
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->size()"

# Output: 10

# Check if there are any students
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->notEmpty()"

# Output: true

# Count the courses without prerequisites (CS101 and MATH101)
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.prerequisites->isEmpty())->size()"

# Output: 2
