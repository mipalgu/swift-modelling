# Simple let bindings for complex queries
# Bind intermediate results to named variables for clarity

# Basic let binding - calculate average salary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees->flatten()
    in allEmployees->collect(e | e.salary)->sum() / allEmployees->size()"

# Output: 128571.43 (average salary across all direct department employees)

# Multiple let bindings - compare department sizes
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let eng = organisation.departments->select(d | d.code = 'ENG')->first(),
        prod = organisation.departments->select(d | d.code = 'PROD')->first()
    in Tuple{engineering = eng.employees->size(), product = prod.employees->size()}"

# Output: {engineering: 4, product: 4}

# Let with nested navigation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let seniorStaff = organisation.departments.employees
        ->flatten()
        ->select(e | e.yearsOfService >= 10)
    in seniorStaff->collect(e | e.name)"

# Output: ["Sarah Mitchell", "David Lee", "Jessica Moore", "Olivia Martinez", "William Anderson"]

# Let binding for reusable predicates
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let threshold = 130000.0,
        highEarners = organisation.departments.employees
            ->flatten()
            ->select(e | e.salary >= threshold)
    in Tuple{count = highEarners->size(),
             totalCost = highEarners->collect(e | e.salary)->sum()}"

# Output: {count: 7, totalCost: 1100000.0}
