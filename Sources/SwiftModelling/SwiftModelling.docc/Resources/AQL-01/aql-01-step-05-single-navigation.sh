# Single Navigation - Traversing single-valued references
# Navigate from one object to a related object

# Navigate to manager (single reference)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().manager.name"

# Output: "Alice Smith"

# Navigate to supervisor (positions in AQL start at 1, so at(3) is the third employee)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees->at(3).supervisor.name"

# Output: "Bob Chen"

# Navigate through multiple single references
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees->at(4).supervisor.supervisor.name"

# Output: "Alice Smith"

# Check if reference is null (the director has no supervisor)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().manager.supervisor.oclIsUndefined()"

# Output: true
