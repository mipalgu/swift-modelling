# Property Access - Reading simple attribute values
# Access properties using dot notation

# Get the company name
swift-aql evaluate --model company-data.xmi \
  --expression "company.name"

# Output: "Acme Corp"

# Get the founding year
swift-aql evaluate --model company-data.xmi \
  --expression "company.founded"

# Output: 1995

# Get a department's budget
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().budget"

# Output: 500000.0

# Get an employee's salary
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().employees->first().salary"

# Output: 120000.0
