# Chaining multiple filter operations
# First select high performers, then reject those in year 1
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.grade >= 85)
    ->reject(s | s.year = 1)"

# Output: [Student(Alex, year 3), Student(Chris, year 4),
#          Student(Hannah, year 4), Student(Julia, year 3)]

# Select CS majors, then filter to those with 80+ grades
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.major.name = 'Computer Science')
    ->select(s | s.grade >= 80)"

# Output: [Student(Alex, 92.5), Student(Chris, 88.5), Student(Fiona, 82.0)]
