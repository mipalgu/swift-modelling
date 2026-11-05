# Basic statistical analysis
# Calculate descriptive statistics on model data

# Calculate mean salary of all direct department employees
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary)
    in salaries->sum() / salaries->size()"

# Output: 127333.33333333333

# Calculate min, max, range
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary)
    in 'minimum: ' + salaries->min().toString()
        + ', maximum: ' + salaries->max().toString()
        + ', range: ' + (salaries->max() - salaries->min()).toString()"

# Output: "minimum: 85000.0, maximum: 185000.0, range: 100000.0"

# Count and distribution by role
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in let roles = employees->collect(e | e.role)->asSet()
    in roles->collect(r | let holders = employees->select(e | e.role = r)
        in r + ': ' + holders->size().toString() + ', average salary '
            + (holders->collect(e | e.salary)->sum() / holders->size()).toString())"

# Output: ["Engineering Director: 1, average salary 185000.0", "Senior Engineer: 1, average salary 145000.0", ..., "Operations Analyst: 1, average salary 85000.0"]

# Percentile approximation: percentage of salaries below each threshold
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary)->sortedBy(s | s)
    in let total = salaries->size()
    in 'below 100k: '
        + (salaries->select(s | s < 100000)->size() * 100 / total).toString()
        + '%, below 120k: '
        + (salaries->select(s | s < 120000)->size() * 100 / total).toString()
        + '%, below 150k: '
        + (salaries->select(s | s < 150000)->size() * 100 / total).toString() + '%'"

# Output: "below 100k: 20%, below 120k: 46%, below 150k: 73%"

# Population variance calculation
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary),
        mean = salaries->sum() / salaries->size()
    in let squaredDiffs = salaries
        ->collect(s | (s - mean) * (s - mean))
    in 'mean: ' + mean.toString()
        + ', variance: ' + (squaredDiffs->sum() / salaries->size()).toString()"

# Output: "mean: 127333.33333333333, variance: 829555555.5555556"

# Department budget utilisation (percentage of budget spent on salaries)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.departments
    ->collect(d | let empCost = d.employees->collect(e | e.salary)->sum()
        in d.name + ': budget ' + d.budget.toString()
            + ', salaries ' + empCost.toString()
            + ', utilisation ' + (empCost / d.budget * 100).toString() + '%')"

# Output: ["Engineering: budget 2500000.0, salaries 570000.0, utilisation 22.8%", "Product: budget 1200000.0, salaries 510000.0, utilisation 42.5%", "Design: budget 900000.0, salaries 480000.0, utilisation 53.333333333333336%", "Operations: budget 700000.0, salaries 350000.0, utilisation 50.0%"]
