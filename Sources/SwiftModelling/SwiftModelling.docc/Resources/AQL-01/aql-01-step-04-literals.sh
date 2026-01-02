# Literals - Using constant values in expressions
# AQL supports various literal types

# String literals
swift-aql evaluate --model company-data.xmi \
  --expression "'Hello, World!'"

# Output: "Hello, World!"

# Integer literals
swift-aql evaluate --model company-data.xmi \
  --expression "42"

# Output: 42

# Real (floating point) literals
swift-aql evaluate --model company-data.xmi \
  --expression "3.14159"

# Output: 3.14159

# Boolean literals
swift-aql evaluate --model company-data.xmi \
  --expression "true"

# Output: true

# Null literal
swift-aql evaluate --model company-data.xmi \
  --expression "null"

# Output: null

# Comparing with literals
swift-aql evaluate --model company-data.xmi \
  --expression "company.founded = 1995"

# Output: true
