# Multi-valued Navigation - Traversing collection references
# Navigate from one object to multiple related objects

# Get all departments (multi-valued containment)
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments"

# Output: [Department(Engineering), Department(Marketing), Department(Finance)]

# Get all employees in first department
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees"

# Output: [Employee(Alice Smith), Employee(Bob Chen), Employee(Carol Williams), Employee(David Lee)]

# Get department names
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.name"

# Output: ["Engineering", "Marketing", "Finance"]

# Get all employee names across all departments
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees.name"

# Output: ["Alice Smith", "Bob Chen", "Carol Williams", ..., "Ivy Chen"]

# Count elements in collection
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->size()"

# Output: 3
