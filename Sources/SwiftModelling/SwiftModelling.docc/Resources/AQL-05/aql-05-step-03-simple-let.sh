# Simple let bindings for complex queries
# Bind intermediate results to named variables for clarity

# Basic let binding: average salary of all direct department employees
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees
    in allEmployees->collect(e | e.salary)->sum() / allEmployees->size()"

# Output: 127333.33333333333

# Multiple let bindings: compare department sizes
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let eng = organisation.departments->select(d | d.code = 'ENG')->first(),
        prod = organisation.departments->select(d | d.code = 'PROD')->first()
    in 'engineering: ' + eng.employees->size().toString()
        + ', product: ' + prod.employees->size().toString()"

# Output: "engineering: 4, product: 4"

# Let with nested navigation: staff with ten or more years of service
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniorStaff = organisation.departments.employees
        ->select(e | e.yearsOfService >= 10)
    in seniorStaff->collect(e | e.name)"

# Output: ["Sarah Mitchell", "Jessica Moore", "Olivia Martinez", "William Anderson"]

# Let binding for reusable predicates
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let threshold = 130000.0,
        highEarners = organisation.departments.employees
            ->select(e | e.salary >= threshold)
    in 'count: ' + highEarners->size().toString()
        + ', total cost: ' + highEarners->collect(e | e.salary)->sum().toString()"

# Output: "count: 6, total cost: 945000.0"
