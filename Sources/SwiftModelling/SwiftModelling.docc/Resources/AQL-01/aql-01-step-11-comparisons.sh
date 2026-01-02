# Comparison Operations - Testing relationships between values
# Use comparisons for filtering and conditions

# Equality
swift-aql evaluate --model company-data.xmi \
  --expression "company.name = 'Acme Corp'"

# Output: true

# Inequality
swift-aql evaluate --model company-data.xmi \
  --expression "company.founded <> 2000"

# Output: true

# Less than / Greater than
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees->select(e | e.salary > 100000)->collect(e | e.name)"

# Output: ["Alice Smith", "Emma Davis", "Henry Brown"]

swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees->select(e | e.age < 30)->collect(e | e.name)"

# Output: ["Bob Chen", "David Lee", "Grace Kim"]

# Less than or equal / Greater than or equal
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->select(d | d.budget >= 300000)->collect(d | d.name)"

# Output: ["Engineering", "Marketing"]

# Boolean operators: and, or, not
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees
    ->select(e | e.salary > 80000 and e.age < 35)
    ->collect(e | e.name)"

# Output: ["Bob Chen", "Ivy Chen"]

swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees
    ->select(e | e.salary > 110000 or e.age > 40)
    ->collect(e | e.name)"

# Output: ["Alice Smith", "Henry Brown", "Emma Davis"]
