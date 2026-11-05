# String Operations - Manipulating text values
# Common string manipulation functions

# String concatenation
swift-aql evaluate --model company-data.xmi \
  --expression "'Hello' + ' ' + 'World'"

# Output: "Hello World"

# Concatenate with model values
swift-aql evaluate --model company-data.xmi \
  --expression "company.name + ' (founded ' + company.founded.toString() + ')'"

# Output: "Acme Corp (founded 1995)"

# String length
swift-aql evaluate --model company-data.xmi \
  --expression "company.name.size()"

# Output: 9

# Substring (positions start at 1 and include both ends)
swift-aql evaluate --model company-data.xmi \
  --expression "'Engineering'.substring(1, 3)"

# Output: "Eng"

# Case conversion
swift-aql evaluate --model company-data.xmi \
  --expression "company.name.toUpper()"

# Output: "ACME CORP"

swift-aql evaluate --model company-data.xmi \
  --expression "company.name.toLower()"

# Output: "acme corp"

# String contains
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments->first().name.contains('Engineer')"

# Output: true

# String starts/ends with
swift-aql evaluate --model company-data.xmi \
  --expression "company.departments.name->select(n | n.endsWith('ing'))"

# Output: ["Engineering", "Marketing"]
