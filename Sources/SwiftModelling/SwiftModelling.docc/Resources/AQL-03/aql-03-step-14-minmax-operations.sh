# Iteration Pipelines - Chaining Operations
# Combining multiple operations in sequence

# Filter then transform - available book titles
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.available)
    ->collect(b | b.title)"

# Output: ["Pride and Prejudice", "Sense and Sensibility", "Foundation", ...]

# Filter, transform, then sort by length
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.pages > 200)
    ->collect(b | b.title)
    ->sortedBy(t | t.size())"

# Output: ["1984", "I, Robot", "Foundation", "The Hobbit", "Clean Code", ..., "Murder on the Orient Express"]

# Multi-stage pipeline - expensive fiction books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.category.code = 'FIC' or b.category.parent.code = 'FIC')
    ->select(b | b.price > 15)
    ->collect(b | b.title + ': $' + b.price.toString())"

# Output: ["Foundation: $15.99", "The Lord of the Rings: $35.99"]

# Pipeline with navigation - British authors' available books
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors
    ->select(a | a.nationality = 'British')
    ->collect(a | a.books)
    ->flatten()
    ->select(b | b.available)
    ->collect(b | b.title)"

# Output: ["Pride and Prejudice", "Sense and Sensibility", "Murder on the Orient Express", ..., "On the Origin of Species"]

# Pipeline with aggregation at the end
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.publicationYear >= 1900)
    ->select(b | b.available)
    ->collect(b | b.price)
    ->sum()"

# Output: 180.92

# Complex pipeline - member activity summary
swift-aql evaluate --model library-data.xmi \
  --expression "library.members
    ->select(m | m.borrowed->notEmpty())
    ->collect(m | m.name)
    ->sortedBy(n | n)"

# Output: ["Alice Thompson", "Bob Richardson", "Carol Mitchell", "David Patterson", "Frank Anderson"]
