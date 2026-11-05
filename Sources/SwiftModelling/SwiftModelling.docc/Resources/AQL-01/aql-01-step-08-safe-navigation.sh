# Safe Navigation - Handling null values gracefully
# Avoid null pointer errors when navigating

# Check for undefined before accessing
swift-aql evaluate --model company-data.xmi \
  --expression "let emp = company.departments->first().employees->first()
    in if emp.supervisor.oclIsUndefined() then 'No supervisor' else emp.supervisor.name endif"

# Output: "No supervisor"

# Use oclIsUndefined() to test for null (employees with supervisors)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees
    ->select(e | not e.supervisor.oclIsUndefined())
    ->collect(e | e.name)"

# Output: ["Bob Chen", "Carol Williams", "David Lee"]

# Safe navigation with default value
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees
    ->collect(e | if e.supervisor.oclIsUndefined() then 'Self-managed' else e.supervisor.name endif)"

# Output: ["Self-managed", "Alice Smith", "Bob Chen", "Bob Chen", "Self-managed", "Emma Davis", "Frank Miller", "Self-managed", "Henry Brown"]

# Handle empty collections
swift-aql evaluate --model company-data.xmi \
  --expression "let emptyDept = company.departments->select(d | d.employees->isEmpty())
    in if emptyDept->isEmpty() then 'All departments have employees' else 'Found empty departments' endif"

# Output: "All departments have employees"

# Safe first/last access (no department has a budget over 1000000)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->select(d | d.budget > 1000000)->first()"

# Output: null
