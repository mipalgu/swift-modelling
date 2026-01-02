# Combined Navigation - Mixing single and multi-valued references
# Chain different navigation types together

# From company to all employee salaries
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees.salary"

# Output: [120000.0, 95000.0, 85000.0, 75000.0, 110000.0, 80000.0, 65000.0, 115000.0, 90000.0]

# From department to manager's title
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->collect(d | d.manager.title)"

# Output: ["Engineering Director", "Marketing Director", "Finance Director"]

# Complex path: all supervisors' names
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees->select(e | e.supervisor <> null).supervisor.name"

# Output: Names of all supervisors (with duplicates)

# Navigate and aggregate
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.budget->sum()"

# Output: 1000000.0 (total of all department budgets)

# Navigate to specific element
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->at(2).employees->first().name"

# Output: "Henry Brown"
