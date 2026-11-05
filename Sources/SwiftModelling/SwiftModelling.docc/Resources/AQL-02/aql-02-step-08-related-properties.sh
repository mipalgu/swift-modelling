# Filter based on related object properties
# Select students majoring in Computer Science
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | s.major.name = 'Computer Science')"

# Output: [Student(Alex Johnson), Student(Beth Smith), Student(Chris Davis), Student(Fiona Green), Student(Ian Clark), Student(Julia Adams)]

# Select professors with more than 10 years experience
# who teach courses at level 300 or above
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors->select(p |
    p.yearsExperience > 10 and p.teaches->exists(c | c.level >= 300))"

# Output: [Professor(Dr Carol Martinez), Professor(Dr Frank Taylor)]
