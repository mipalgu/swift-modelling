# Any and One Operations - Selecting Single Elements
# Extract individual elements from collections

# Get an available book (any returns the first match of an ordered collection)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(b | b.available).title"

# Output: "Pride and Prejudice"

# Get the book with a specific ISBN
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(b | b.isbn = '978-0553380163').title"

# Output: "A Brief History of Time"

# Check that exactly one book has this ISBN
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->one(b | b.isbn = '978-0553380163')"

# Output: true

# Get an expensive book (Notes on Programming also costs more than 40)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->any(b | b.price > 40).title"

# Output: "Radioactive Substances"

# one is false when more than one element matches
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->one(b | b.price > 40)"

# Output: false

# Get any British author
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->any(a | a.nationality = 'British').name"

# Output: "Jane Austen"

# Get the Polish author
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->any(a | a.nationality = 'Polish').name"

# Output: "Marie Curie"

# Get a subcategory of Fiction by its code
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->select(c | c.code = 'FIC')->first().subcategories->any(s | s.code = 'FAN').name"

# Output: "Fantasy"

# Get any member with no current borrowings
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->any(m | m.borrowed->isEmpty()).name"

# Output: "Emma Williams"
