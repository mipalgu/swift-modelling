# Simple select with comparison
# Select students with grade >= 85
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | s.grade >= 85)"

# Output: [Student(Alex, 92.5), Student(Chris, 88.5), Student(Diana, 95.0),
#          Student(Hannah, 89.0), Student(Julia, 96.5)]

# Select courses with 4 credits
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.credits = 4)"

# Output: [Course(Data Structures), Course(Algorithms),
#          Course(Operating Systems), Course(Calculus I), Course(Quantum Mechanics)]
