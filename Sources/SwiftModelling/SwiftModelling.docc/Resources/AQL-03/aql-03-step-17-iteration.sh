# Any and One Operations - Selecting Single Elements
# Extract individual elements from collections

# Get any book from the collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(true).title"

# Output: A title of any book (non-deterministic)

# Get any available book
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(b | b.available).title"

# Output: Title of any available book

# Get one specific book matching criteria
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->one(b | b.isbn = '978-0553380163').title"

# Output: 'A Brief History of Time'

# Get any expensive book
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(b | b.price > 40).title"

# Output: Either 'Radioactive Substances' or 'Notes on Programming'

# Get any British author
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->any(a | a.nationality = 'British').name"

# Output: Name of any British author

# Get the one Polish author (unique match)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->one(a | a.nationality = 'Polish').name"

# Output: 'Marie Curie'

# Get any subcategory of Fiction
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->select(c | c.code = 'FIC')->first().subcategories->any(true).name"

# Output: Any of 'Science Fiction', 'Fantasy', or 'Mystery'

# Get any member with no current borrowings
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->any(m | m.borrowed->isEmpty()).name"

# Output: 'Emma Williams'
