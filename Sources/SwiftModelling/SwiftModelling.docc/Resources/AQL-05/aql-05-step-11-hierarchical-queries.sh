# Basic statistical analysis
# Calculate descriptive statistics on model data

# Calculate mean salary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)
    in salaries->sum() / salaries->size()"

# Output: 127142.86 (mean salary)

# Calculate min, max, range
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)
    in Tuple{
        minimum = salaries->min(),
        maximum = salaries->max(),
        range = salaries->max() - salaries->min()}"

# Output: {minimum: 85000.0, maximum: 185000.0, range: 100000.0}

# Count and distribution by role
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in let roles = employees->collect(e | e.role)->asSet()
    in roles->collect(r | Tuple{
        role = r,
        count = employees->select(e | e.role = r)->size(),
        avgSalary = employees->select(e | e.role = r)
            ->collect(e | e.salary)->sum()
            / employees->select(e | e.role = r)->size()})"

# Output: [{role: "Engineering Director", count: 1, avgSalary: 185000.0}, ...]

# Percentile approximation (count below threshold)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)->sortedBy(s | s)
    in let total = salaries->size()
    in Tuple{
        below100k = salaries->select(s | s < 100000)->size() * 100 / total,
        below120k = salaries->select(s | s < 120000)->size() * 100 / total,
        below150k = salaries->select(s | s < 150000)->size() * 100 / total}"

# Output: {below100k: 19, below120k: 47, below150k: 76} (percentiles)

# Variance calculation (simplified)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()->collect(e | e.salary),
        mean = salaries->sum() / salaries->size()
    in let squaredDiffs = salaries
        ->collect(s | (s - mean) * (s - mean))
    in Tuple{
        mean = mean,
        variance = squaredDiffs->sum() / salaries->size()}"

# Output: {mean: 127142.86, variance: 612244897.96} (population variance)

# Department budget utilisation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let empCost = d.employees->collect(e | e.salary)->sum()
        in Tuple{
            department = d.name,
            budget = d.budget,
            employeeCost = empCost,
            utilisation = (empCost / d.budget) * 100})"

# Output: [{department: "Engineering", budget: 2500000.0, employeeCost: 570000.0, utilisation: 22.8}]
