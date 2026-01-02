# Counting Operations - Tallying Elements
# Various ways to count elements in collections

# Count total number of books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->size()"

# Output: 15

# Count available books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.available)->size()"

# Output: 13

# Count unavailable books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->reject(b | b.available)->size()"

# Output: 2

# Count books with more than 300 pages
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.pages > 300)->size()"

# Output: 5

# Count British authors
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->select(a | a.nationality = 'British')->size()"

# Output: 7

# Count books per category using collect
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    c.name + ': ' + library.books->select(b | b.category = c)->size().toString())"

# Output: ['Fiction: 4', 'Non-Fiction: 0', 'Technical: 0']

# Count members with active borrowings
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->select(m | m.borrowed->notEmpty())->size()"

# Output: 5

# Count total borrowed books (across all members)
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.borrowed)->flatten()->size()"

# Output: 9
