# Iteration Pipelines - Chaining Operations
# Combining multiple operations in sequence

# Filter then transform - available book titles
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.available)
    ->collect(b | b.title)"

# Output: ['Pride and Prejudice', 'Sense and Sensibility', 'Foundation', ...]

# Filter, transform, then sort by length
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.pages > 200)
    ->collect(b | b.title)
    ->sortedBy(t | t.size())"

# Output: Titles sorted by length of title string

# Multi-stage pipeline - expensive fiction books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.category.code = 'FIC' or b.category.parent.code = 'FIC')
    ->select(b | b.price > 15)
    ->collect(b | b.title + ': $' + b.price.toString())"

# Output: ['Foundation: $15.99', 'A Brief History of Time: $18.99', 'The Lord of the Rings: $35.99']

# Pipeline with navigation - British authors' available books
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors
    ->select(a | a.nationality = 'British')
    ->collect(a | a.books)
    ->flatten()
    ->select(b | b.available)
    ->collect(b | b.title)"

# Output: Available books written by British authors

# Pipeline with aggregation at the end
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.publicationYear >= 1900)
    ->select(b | b.available)
    ->collect(b | b.price)
    ->sum()"

# Output: Total price of available 20th/21st century books

# Complex pipeline - member activity summary
swift-aql evaluate --model library-data.xmi \
  --expression "library.members
    ->select(m | m.borrowed->notEmpty())
    ->collect(m | m.name)
    ->sortedBy(n | n)"

# Output: Sorted list of members with active borrowings
