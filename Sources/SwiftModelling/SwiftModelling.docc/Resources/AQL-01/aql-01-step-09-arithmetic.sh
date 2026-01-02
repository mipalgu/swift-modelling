# Arithmetic Operations - Mathematical calculations
# Perform calculations on numeric values

# Basic arithmetic
swift-aql evaluate --model company-data.xmi \
  --expression "10 + 5"

# Output: 15

swift-aql evaluate --model company-data.xmi \
  --expression "100 - 35"

# Output: 65

swift-aql evaluate --model company-data.xmi \
  --expression "12 * 8"

# Output: 96

swift-aql evaluate --model company-data.xmi \
  --expression "100 / 4"

# Output: 25

# Modulo (remainder)
swift-aql evaluate --model company-data.xmi \
  --expression "17.mod(5)"

# Output: 2

# Calculations with model values
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().budget / 12"

# Output: 41666.67 (monthly budget)

# Calculate average salary
swift-aql evaluate --model company-data.xmi \
  --expression "let salaries = company.departments.employees.salary
    in salaries->sum() / salaries->size()"

# Output: 92777.78 (approximate average)

# Percentage calculation
swift-aql evaluate --model company-data.xmi \
  --expression "let eng = company.departments->first()
    in eng.employees.salary->sum() / eng.budget * 100"

# Output: 75.0 (salary as percentage of budget)
