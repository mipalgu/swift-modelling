# Includes and Excludes Operations - Membership Testing
# Check if collections contain specific elements

# Check if a specific book is in the library
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.title)->includes('1984')"

# Output: true

# Check if a book title is NOT in the library
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.title)->excludes('War and Peace')"

# Output: true

# Check if member has borrowed a specific book
swift-aql evaluate --model library-data.xmi \
  --expression "let aliceBorrowed = library.members->select(m | m.name = 'Alice Thompson')->first().borrowed,
      foundation = library.books->select(b | b.title = 'Foundation')->first()
    in aliceBorrowed->includes(foundation)"

# Output: true

# Check if all specified items are in a collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.nationality)->includesAll(Sequence{'British', 'American'})"

# Output: true

# Check if none of the specified items are in collection
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.nationality)->excludesAll(Sequence{'French', 'German'})"

# Output: true

# Check if any category contains programming books
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories.subcategories->collect(s | s.code)->includes('PROG')"

# Output: true

# Check member's favourites include a specific title
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->select(m |
    m.favourites->collect(b | b.title)->includes('Foundation'))->collect(m | m.name)"

# Output: ['Alice Thompson']

# Check which members have NOT borrowed any books
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->select(m |
    library.books->excludesAll(m.borrowed))->collect(m | m.name)"

# Output: ['Emma Williams']
