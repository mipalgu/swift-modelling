# Collect Operation - Transforming Collections
# The collect operation extracts or transforms values from each element

# Extract all book titles
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.title)"

# Output: ['Pride and Prejudice', 'Sense and Sensibility', 'Foundation', ...]

# Extract page counts from all books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)"

# Output: [432, 409, 244, 224, 256, 272, 212, 300, 1178, 328, 112, 464, 156, 89, 703]

# Extract prices as a collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)"

# Output: [12.99, 11.99, 15.99, 14.99, 13.99, 12.99, 18.99, 14.99, 35.99, 9.99, 8.99, 39.99, 45.0, 55.0, 16.99]

# Shorthand syntax without explicit iterator variable
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors.name"

# Output: ['Jane Austen', 'Isaac Asimov', 'Agatha Christie', ...]

# Collect computed values - calculate age of each book
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | 2024 - b.publicationYear)"

# Output: [211, 213, 73, 74, 90, 88, 36, 87, 70, 75, 79, 16, 120, 181, 165]
