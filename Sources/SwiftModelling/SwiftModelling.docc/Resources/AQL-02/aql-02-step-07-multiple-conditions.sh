# Combining conditions with and/or
# Select students with high grades AND in year 3 or above
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | s.grade >= 85 and s.year >= 3)"

# Output: [Student(Alex Johnson), Student(Chris Davis), Student(Hannah Moore), Student(Julia Adams)]

# Select courses that are either 4 credits OR level 400
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.credits = 4 or c.level = 400)"

# Output: [Course(Data Structures), Course(Algorithms), Course(Deep Learning), ..., Course(Astrophysics)]

# Complex condition with parentheses: Diana qualifies by her grade alone
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | (s.grade >= 80 and s.year <= 2) or s.grade >= 95)"

# Output: [Student(Diana Ross), Student(Julia Adams)]
