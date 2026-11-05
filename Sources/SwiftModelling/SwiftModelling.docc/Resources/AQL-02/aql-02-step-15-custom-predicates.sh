# Building reusable filtering predicates
# Define meaningful conditions for readability

# "High achiever" = grade >= 90 and year >= 3
# Name the thresholds with let, so the condition reads like its definition
swift-aql evaluate --model university-data.xmi \
  --expression "let minimumGrade = 90, minimumYear = 3
    in university.students->select(s | s.grade >= minimumGrade and s.year >= minimumYear)"

# Output: [Student(Alex Johnson), Student(Julia Adams)]

# "Experienced professor" = yearsExperience >= 15
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->select(p | p.yearsExperience >= 15)"

# Output: [Professor(Dr Alice Chen), Professor(Dr David Lee), Professor(Dr Frank Taylor)]

# "Advanced course" = level >= 300 and has prerequisites
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses
    ->select(c | c.level >= 300 and c.prerequisites->notEmpty())"

# Output: [Course(Machine Learning), Course(Deep Learning), Course(Operating Systems), ..., Course(Astrophysics)]
