# Testing existence with exists
# Check if any student has a perfect score (100)
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->exists(s | s.grade = 100)"

# Output: false

# Check if there are any failing students (Ian has 58.0)
swift-aql evaluate --model university-data.xmi \
  --expression "university.students->exists(s | s.grade < 60)"

# Output: true

# Check if any department has professors with 20+ years experience
# (Dr David Lee has 20 years)
swift-aql evaluate --model university-data.xmi \
  --expression "university.departments->exists(d |
    d.professors->exists(p | p.yearsExperience >= 20))"

# Output: true
