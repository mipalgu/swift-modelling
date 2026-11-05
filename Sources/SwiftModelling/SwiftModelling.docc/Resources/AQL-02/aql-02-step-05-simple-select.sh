# Simple select with comparison
# Select students with grade >= 85
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | s.grade >= 85)"

# Output: [Student(Alex Johnson), Student(Chris Davis), Student(Diana Ross), Student(Hannah Moore), Student(Julia Adams)]

# Select courses with 4 credits
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.credits = 4)"

# Output: [Course(Data Structures), Course(Algorithms), Course(Operating Systems), Course(Calculus I), Course(Quantum Mechanics)]
