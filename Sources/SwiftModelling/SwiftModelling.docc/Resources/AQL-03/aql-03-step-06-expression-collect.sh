# Flatten Operation - Combining Nested Collections
# Flatten reduces nested collections into a single flat collection
# (collect already flattens the collections its expression returns)

# Get all books from all authors (collect returns one flat collection)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.books)"

# Output: [Book(Pride and Prejudice), Book(Sense and Sensibility), Book(Foundation), Book(I, Robot), ...]

# flatten() leaves a collection without nested collections unchanged
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.books)->flatten()"

# Output: [Book(Pride and Prejudice), Book(Sense and Sensibility), Book(Foundation), Book(I, Robot), ...]

# flatten() merges the collections nested inside a collection
swift-aql evaluate --model library-data.xmi \
  --expression "Sequence{Sequence{'Fiction', 'Non-Fiction'}, Sequence{'Technical'}}->flatten()"

# Output: ["Fiction", "Non-Fiction", "Technical"]

# Get all subcategory names flattened
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c | c.subcategories)->flatten()->collect(s | s.name)"

# Output: ["Science Fiction", "Fantasy", "Mystery", "Biography", "Science", "History", "Programming", "Engineering"]

# Flatten member favourites to see all favourite books
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.favourites)->flatten()->collect(b | b.title)"

# Output: ["Foundation", "I, Robot", "A Brief History of Time", ...]

# Combine flatten with unique using asSet (unique favourite books across all members)
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.favourites)->flatten()->asSet()->size()"

# Output: 14

# Shorthand for collect + flatten using dot notation
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories.subcategories.name"

# Output: ["Science Fiction", "Fantasy", "Mystery", "Biography", "Science", "History", "Programming", "Engineering"]
