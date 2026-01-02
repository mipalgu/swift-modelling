# Collection Basics - Understanding AQL Collections
# Collections are the foundation of data manipulation in AQL

# Get all books in the library
swift-aql evaluate --model library-data.xmi \
  --expression "library.books"

# Output: [Book(Pride and Prejudice), Book(Sense and Sensibility), ...]

# Get the size of a collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->size()"

# Output: 15

# Check if a collection is empty
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->isEmpty()"

# Output: false

# Check if a collection is not empty
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->notEmpty()"

# Output: true

# Get the first element of a collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->first()"

# Output: Book(Pride and Prejudice)

# Get the last element of a collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->last()"

# Output: Book(On the Origin of Species)
