# Combining conditions with and/or
# Select students with high grades AND in year 3 or above
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | s.grade >= 85 and s.year >= 3)"

# Output: [Student(Alex, 92.5, year 3), Student(Chris, 88.5, year 4),
#          Student(Hannah, 89.0, year 4), Student(Julia, 96.5, year 3)]

# Select courses that are either 4 credits OR level 400
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->select(c | c.credits = 4 or c.level = 400)"

# Output: [Course(Data Structures, 4 credits), Course(Algorithms, 4 credits),
#          Course(Deep Learning, level 400), Course(Astrophysics, level 400), ...]

# Complex condition with parentheses
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->select(s | (s.grade >= 80 and s.year <= 2) or s.grade >= 95)"

# Output: Students matching either condition
