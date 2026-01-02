# Building reusable filtering predicates
# Define meaningful conditions for readability

# "High achiever" = grade >= 90 and year >= 3
swift-aql evaluate --model university-data.xmi \
  --expression "let highAchiever = (s : Student) | s.grade >= 90 and s.year >= 3
    in university.students->select(highAchiever)"

# Output: [Student(Alex, 92.5, year 3), Student(Julia, 96.5, year 3)]

# "Experienced professor" = yearsExperience >= 15
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->select(p | p.yearsExperience >= 15)"

# Output: [Professor(Dr Alice Chen, 15), Professor(Dr David Lee, 20),
#          Professor(Dr Frank Taylor, 18)]

# "Advanced course" = level >= 300 and has prerequisites
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses
    ->select(c | c.level >= 300 and c.prerequisites->notEmpty())"

# Output: Advanced courses with prerequisites
