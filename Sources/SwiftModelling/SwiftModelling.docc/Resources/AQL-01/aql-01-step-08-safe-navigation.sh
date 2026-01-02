# Safe Navigation - Handling null values gracefully
# Avoid null pointer errors when navigating

# Check for undefined before accessing
swift-aql evaluate --model company-data.xmi \
  --expression "let emp = company.departments->first().employees->first()
    in if emp.supervisor.oclIsUndefined() then 'No supervisor' else emp.supervisor.name endif"

# Output: "No supervisor"

# Use oclIsUndefined() to test for null
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees
    ->select(e | not e.supervisor.oclIsUndefined())
    ->collect(e | e.name)"

# Output: ["Bob Chen", "Carol Williams", "David Lee"] (employees with supervisors)

# Safe navigation with default value
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees
    ->collect(e | if e.supervisor.oclIsUndefined() then 'Self-managed' else e.supervisor.name endif)"

# Output: Mix of supervisor names and "Self-managed"

# Handle empty collections
swift-aql evaluate --model company-data.xmi \
  --expression "let emptyDept = company.departments->select(d | d.employees->isEmpty())
    in if emptyDept->isEmpty() then 'All departments have employees' else 'Found empty departments' endif"

# Output: "All departments have employees"

# Safe first/last access
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->select(d | d.budget > 1000000)->first()"

# Output: null (no department has budget > 1000000)
