# Complex Pipelines - Advanced Collection Processing
# Combining multiple operations for sophisticated queries

# Find most popular category by total copies available
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->sortedBy(c |
    -library.books->select(b | b.category = c or b.category.parent = c)
      ->collect(b | b.copies)->sum())->first().name"

# Output: "Fiction"

# Get British authors sorted by their average book length
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors
    ->select(a | a.nationality = 'British')
    ->sortedBy(a | -a.books->collect(b | b.pages)->sum() / a.books->size())
    ->collect(a | a.name + ': avg ' + (a.books->collect(b | b.pages)->sum() / a.books->size()).toString() + ' pages')"

# Output: ["J.R.R. Tolkien: avg 739 pages", "Charles Darwin: avg 703 pages", "Jane Austen: avg 420 pages", ..., "Ada Lovelace: avg 89 pages"]

# Pipeline with multiple aggregations - library statistics
swift-aql evaluate --model library-data.xmi \
  --expression "let totalBooks = library.books->size(),
      totalCopies = library.books->collect(b | b.copies)->sum(),
      avgPrice = library.books->collect(b | b.price)->sum() / totalBooks,
      totalValue = library.books->collect(b | b.price * b.copies)->sum()
    in 'Books: ' + totalBooks.toString() + ', Copies: ' + totalCopies.toString() +
       ', Avg Price: $' + avgPrice.toString() + ', Total Value: $' + totalValue.toString()"

# Output: "Books: 15, Copies: 70, Avg Price: $21.924666666666667, Total Value: $1262.33"

# Find members who have borrowed books by multiple authors
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->select(m |
    m.borrowed->collect(b | b.authors)->flatten()->asSet()->size() > 1
  )->collect(m | m.name)"

# Output: ["Alice Thompson", "Bob Richardson", "David Patterson", "Frank Anderson"]

# Top 3 most expensive available books with details
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.available)
    ->sortedBy(b | -b.price)
    ->subSequence(1, 3)
    ->collect(b | b.title + ' by ' + b.authors->first().name + ': $' + b.price.toString())"

# Output: ["Notes on Programming by Ada Lovelace: $55.0", "Radioactive Substances by Marie Curie: $45.0", "Clean Code by Robert Martin: $39.99"]

# Members and their total borrowed page count
swift-aql evaluate --model library-data.xmi \
  --expression "library.members
    ->select(m | m.borrowed->notEmpty())
    ->sortedBy(m | -m.borrowed->collect(b | b.pages)->sum())
    ->collect(m | m.name + ': ' + m.borrowed->collect(b | b.pages)->sum().toString() + ' pages borrowed')"

# Output: ["David Patterson: 1942 pages borrowed", "Frank Anderson: 815 pages borrowed", ..., "Carol Mitchell: 256 pages borrowed"]
