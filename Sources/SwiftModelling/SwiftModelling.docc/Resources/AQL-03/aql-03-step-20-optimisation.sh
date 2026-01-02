# Optimisation Techniques - Efficient Collection Operations
# Best practices for performant AQL queries

# AVOID: Repeated collection traversal
# Inefficient - traverses books multiple times
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.available)->size() + ' available, ' +
    library.books->select(b | not b.available)->size() + ' unavailable'"

# PREFER: Single traversal with let bindings
swift-aql evaluate --model library-data.xmi \
  --expression "let allBooks = library.books,
      available = allBooks->select(b | b.available),
      unavailable = allBooks->reject(b | b.available)
    in available->size() + ' available, ' + unavailable->size() + ' unavailable'"

# Output: "13 available, 2 unavailable"

# AVOID: Nested iteration with full scans
# Inefficient - O(n*m) complexity
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | library.authors->exists(a | a.books->includes(b)))->size()"

# PREFER: Direct navigation
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.authors->notEmpty())->size()"

# Output: 15

# OPTIMISE: Use early filtering to reduce collection size
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.available)
    ->select(b | b.price < 20)
    ->collect(b | b.title)"

# Better than filtering all conditions in transform step

# OPTIMISE: Reuse computed collections with let
swift-aql evaluate --model library-data.xmi \
  --expression "let expensiveBooks = library.books->select(b | b.price > 30)
    in 'Expensive books: ' + expensiveBooks->size() +
       ', Total value: $' + expensiveBooks->collect(b | b.price)->sum().toString() +
       ', Avg pages: ' + (expensiveBooks->collect(b | b.pages)->sum() / expensiveBooks->size()).toString()"

# Output: Computed once, used three times

# OPTIMISE: Use asSet() to remove duplicates early
swift-aql evaluate --model library-data.xmi \
  --expression "library.members
    ->collect(m | m.favourites)
    ->flatten()
    ->asSet()
    ->select(b | b.available)
    ->size()"

# Output: Count of unique available favourite books

# OPTIMISE: Avoid unnecessary transformations
# Instead of: ->collect(b | b)->select(b | b.available)
# Use: ->select(b | b.available)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.available)->collect(b | b.title)"

# Output: Direct and efficient

# OPTIMISE: Combine conditions in single select
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.available and b.price < 15 and b.pages > 200)->collect(b | b.title)"

# Better than chaining multiple select operations
# Output: Books matching all criteria efficiently
