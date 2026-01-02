# Filtering nested collections
# Get all courses from departments, then filter to 4-credit courses
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.offeredCourses
    ->select(c | c.credits = 4)"

# Working with courses students are enrolled in
swift-aql evaluate --model university-data.xmi \
  --expression "university.students
    ->select(s | s.grade >= 90)
    .enrolledIn
    ->flatten()
    ->asSet()"

# Output: Unique set of courses taken by high-achieving students

# Filter professors' courses to advanced level only
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors
    ->collect(p | p.teaches->select(c | c.level >= 300))
    ->flatten()"

# Output: All 300+ level courses taught by any professor
