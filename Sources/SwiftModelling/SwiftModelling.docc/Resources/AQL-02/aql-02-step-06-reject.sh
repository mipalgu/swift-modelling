# Reject operation - opposite of select
# Reject students with passing grades (keep failing students)
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->reject(s | s.grade >= 60)"

# Output: [Student(Ian, 58.0)]

# Reject introductory courses (keep advanced courses)
swift-aql evaluate --model university-data.xmi \
  --expression "university.courses->reject(c | c.level = 100)"

# Output: [Course(Algorithms, 200), Course(Machine Learning, 300),
#          Course(Deep Learning, 400), Course(Operating Systems, 300), ...]
