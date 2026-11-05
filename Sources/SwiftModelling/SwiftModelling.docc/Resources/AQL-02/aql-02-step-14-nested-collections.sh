# Filtering nested collections
# Get the courses taught in all departments, then filter to 4-credit courses
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors.teaches
    ->select(c | c.credits = 4)"

# Output: [Course(Data Structures), Course(Algorithms), Course(Operating Systems), Course(Calculus I), Course(Quantum Mechanics)]

# Working with courses students are enrolled in
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.grade >= 90)
    .enrolledIn
    ->flatten()
    ->asSet()"

# Output: [Course(Data Structures), Course(Machine Learning), Course(Calculus I), Course(Differential Equations), Course(Deep Learning), Course(Astrophysics)]

# Filter professors' courses to advanced level only
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->collect(p | p.teaches->select(c | c.level >= 300))
    ->flatten()"

# Output: [Course(Machine Learning), Course(Deep Learning), Course(Operating Systems), Course(Differential Equations), Course(Quantum Mechanics), Course(Astrophysics)]
