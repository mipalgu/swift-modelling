# Access collections through navigation
# Get all students from the university
swift-aql evaluate --model university-data.xmi \
  --expression "university.students"

# Output: [Student(Alex), Student(Beth), Student(Chris), ...]

# Access nested collections - all professors in all departments
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments.professors"

# Output: [Professor(Dr Alice Chen), Professor(Dr Bob Wilson), ...]
