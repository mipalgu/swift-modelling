# Chaining multiple filter operations
# First select high performers, then reject those in year 1
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.grade >= 85)
    ->reject(s | s.year = 1)"

# Output: [Student(Alex Johnson), Student(Chris Davis), Student(Hannah Moore), Student(Julia Adams)]

# Select CS majors, then filter to those with 80+ grades
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.major.name = 'Computer Science')
    ->select(s | s.grade >= 80)"

# Output: [Student(Alex Johnson), Student(Chris Davis), Student(Fiona Green), Student(Julia Adams)]
