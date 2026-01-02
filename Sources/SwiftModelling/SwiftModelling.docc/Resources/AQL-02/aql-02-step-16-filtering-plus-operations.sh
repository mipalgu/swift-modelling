# Combining filtering with other operations
# Count students with each grade range
swift-aql evaluate --model university-data.xmi \
  --expression "let excellent = university.students->select(s | s.grade >= 90)->size(),
        good = university.students->select(s | s.grade >= 80 and s.grade < 90)->size(),
        pass = university.students->select(s | s.grade >= 60 and s.grade < 80)->size(),
        fail = university.students->select(s | s.grade < 60)->size()
    in 'Excellent: ' + excellent + ', Good: ' + good + ', Pass: ' + pass + ', Fail: ' + fail"

# Output: "Excellent: 4, Good: 2, Pass: 3, Fail: 1"

# Average grade of CS majors
swift-aql evaluate --model university-data.xmi \
  --expression "let csStudents = university.students->select(s | s.major.code = 'CS')
    in csStudents->collect(s | s.grade)->sum() / csStudents->size()"

# Output: Average grade for Computer Science students

# Total credits of courses taught by experienced professors
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->select(p | p.yearsExperience >= 15)
    .teaches
    ->flatten()
    ->asSet()
    ->collect(c | c.credits)
    ->sum()"

# Output: Total credit hours
