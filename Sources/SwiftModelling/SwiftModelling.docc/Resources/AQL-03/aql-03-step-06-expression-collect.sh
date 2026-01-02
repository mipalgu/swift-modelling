# Flatten Operation - Combining Nested Collections
# Flatten reduces nested collections into a single flat collection

# Get all books from all authors (without flatten - nested)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.books)"

# Output: [[Book(Pride...), Book(Sense...)], [Book(Foundation), Book(I, Robot)], ...]

# Flatten to get all books in a single collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.books)->flatten()"

# Output: [Book(Pride...), Book(Sense...), Book(Foundation), Book(I, Robot), ...]

# Get all subcategory names flattened
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c | c.subcategories)->flatten()->collect(s | s.name)"

# Output: ['Science Fiction', 'Fantasy', 'Mystery', 'Biography', 'Science', 'History', 'Programming', 'Engineering']

# Flatten member favourites to see all favourite books
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.favourites)->flatten()->collect(b | b.title)"

# Output: ['Foundation', 'I, Robot', 'A Brief History of Time', ...]

# Combine flatten with unique using asSet
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.favourites)->flatten()->asSet()->size()"

# Output: 11 (unique favourite books across all members)

# Shorthand for collect + flatten using dot notation
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories.subcategories.name"

# Output: ['Science Fiction', 'Fantasy', 'Mystery', 'Biography', 'Science', 'History', 'Programming', 'Engineering']
