# Translate the condition of transfer into AQL
swift-henshin translate "amount > 0 && x >= amount" --variables amount,x

# Translate an expression with a string operation, and show what it uses
swift-henshin translate "name + ' ' + suffix.toUpperCase()" --variables name,suffix --verbose

# Division is always real division, as in JavaScript
swift-henshin translate "balance / 2" --variables balance

# Output:
# ((amount > 0) and (x >= amount))
# ((name + ' ') + suffix.toUpper())
# variables: name, suffix
# form: query
# ((balance * 1.0) / 2)
