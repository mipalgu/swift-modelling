# Show the first entries of the translation table
swift-henshin translate --table | head -n 10

# Output:
# 42    42    integer literal
# 2.5    2.5    real literal
# "text"    'text'    string literal in either quote style
# true    true    Boolean literal
# null    null    null literal
# a    a    parameter reference
# a + b    (a + b)    addition, or concatenation if either is a string
# a - b    (a - b)    subtraction
# a * b    (a * b)    multiplication
# a / b    ((a * 1.0) / b)    always real division, as in JavaScript
