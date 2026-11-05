# Combining filtering with other operations
# Count students with each grade range
swift-aql evaluate --model university-data.xmi \
  --expression "let excellent = university.students->select(s | s.grade >= 90)->size(),
        good = university.students->select(s | s.grade >= 80 and s.grade < 90)->size(),
        pass = university.students->select(s | s.grade >= 60 and s.grade < 80)->size(),
        fail = university.students->select(s | s.grade < 60)->size()
    in 'Excellent: ' + excellent.toString() + ', Good: ' + good.toString() +
       ', Pass: ' + pass.toString() + ', Fail: ' + fail.toString()"

# Output: "Excellent: 3, Good: 3, Pass: 3, Fail: 1"

# Average grade of CS majors
swift-aql evaluate --model university-data.xmi \
  --expression "let csStudents = university.students->select(s | s.major.code = 'CS')
    in csStudents->collect(s | s.grade)->sum() / csStudents->size()"

# Output: 82.58333333333333

# Total credits of courses taught by experienced professors
# asSet() removes repeated courses; asSequence() keeps equal credit values
# apart, as collecting over a set would merge them
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->select(p | p.yearsExperience >= 15)
    .teaches
    ->flatten()
    ->asSet()
    ->asSequence()
    ->collect(c | c.credits)
    ->sum()"

# Output: 19
