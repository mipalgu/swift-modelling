# Sorting Operations - Ordering Collections
# Sort collections by various criteria

# Sort books by title alphabetically
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->sortedBy(b | b.title)->collect(b | b.title)"

# Output: ['1984', 'A Brief History of Time', 'Animal Farm', 'Clean Code', ...]

# Sort books by price (ascending)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->sortedBy(b | b.price)->collect(b | b.title + ': $' + b.price.toString())"

# Output: ['Animal Farm: $8.99', '1984: $9.99', 'Sense and Sensibility: $11.99', ...]

# Sort books by page count (descending) using negative value
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->sortedBy(b | -b.pages)->collect(b | b.title + ' (' + b.pages.toString() + ' pages)')"

# Output: ['The Lord of the Rings (1178 pages)', 'On the Origin of Species (703 pages)', ...]

# Sort authors by birth year (oldest first)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->sortedBy(a | a.birthYear)->collect(a | a.name + ' (b. ' + a.birthYear.toString() + ')')"

# Output: ['Jane Austen (b. 1775)', 'Charles Darwin (b. 1809)', 'Ada Lovelace (b. 1815)', ...]

# Sort books by publication year (newest first)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->sortedBy(b | -b.publicationYear)->collect(b | b.title + ' (' + b.publicationYear.toString() + ')')"

# Output: ['Clean Code (2008)', 'A Brief History of Time (1988)', ...]

# Sort members by number of borrowed books
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->sortedBy(m | -m.borrowed->size())->collect(m |
    m.name + ': ' + m.borrowed->size().toString() + ' books borrowed')"

# Output: ['David Patterson: 3 books borrowed', 'Alice Thompson: 2 books borrowed', ...]

# Sort with filtered collection first
swift-aql evaluate --model library-data.xmi \
  --expression "library.books
    ->select(b | b.available)
    ->sortedBy(b | b.price)
    ->collect(b | b.title)"

# Output: Available books sorted by price
