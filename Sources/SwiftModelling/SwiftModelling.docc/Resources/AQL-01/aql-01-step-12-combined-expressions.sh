# Combined Expressions - Putting it all together
# Build complex queries using multiple operations

# Generate employee report string
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.employees
    ->collect(e | e.name + ' (' + e.title + '): $' + e.salary.toString())"

# Output: ["Alice Smith (Engineering Director): $120000.0", ...]

# Calculate department statistics
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->collect(d |
    d.name + ': ' + d.employees->size().toString() + ' employees, ' +
    'avg salary $' + (d.employees.salary->sum() / d.employees->size()).toString())"

# Output: ["Engineering: 4 employees, avg salary $93750.0", ...]

# Find highest paid employee per department
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->collect(d |
    let maxSalary = d.employees.salary->max() in
    d.name + ': ' + d.employees->select(e | e.salary = maxSalary)->first().name)"

# Output: ["Engineering: Alice Smith", "Marketing: Emma Davis", "Finance: Henry Brown"]

# Complex filtering with aggregation
swift-aql evaluate --model company-data.xmi \
  --expression "let seniorEmployees = company.departments.employees
      ->select(e | e.age >= 30 and e.salary >= 80000)
    in 'Senior employees: ' + seniorEmployees->size().toString() +
       ', Total salary: $' + seniorEmployees.salary->sum().toString()"

# Output: "Senior employees: 6, Total salary: $595000.0"

# Conditional report generation
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->collect(d |
    d.name + ' is ' +
    if d.budget >= 400000 then 'high budget'
    else if d.budget >= 250000 then 'medium budget'
    else 'low budget' endif endif)"

# Output: ["Engineering is high budget", "Marketing is medium budget", "Finance is low budget"]
