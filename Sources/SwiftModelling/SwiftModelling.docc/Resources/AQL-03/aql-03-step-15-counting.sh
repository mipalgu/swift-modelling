# Set Operations - Union, Intersection, Difference
# Working with sets and unique collections

# Convert collection to set (remove duplicates)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.nationality)->asSet()"

# Output: {'British', 'American', 'Polish'}

# Union of two collections - all favourite and borrowed books
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten(),
      favourites = library.members->collect(m | m.favourites)->flatten()
    in borrowed->union(favourites)->asSet()->size()"

# Output: Number of unique books that are either borrowed or favourited

# Intersection - books that are both borrowed AND favourited
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in borrowed->intersection(favourites)->collect(b | b.title)"

# Output: Titles of books in both sets

# Difference - favourites that are not currently borrowed
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in favourites->difference(borrowed)->collect(b | b.title)"

# Output: Books that are favourited but not borrowed

# Symmetric difference - books in one set but not both
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in borrowed->symmetricDifference(favourites)->size()"

# Output: Count of books in exactly one of the two sets

# Check if one set is subset of another
swift-aql evaluate --model library-data.xmi \
  --expression "let aliceFavs = library.members->select(m | m.name = 'Alice Thompson')->first().favourites->asSet(),
      allBooks = library.books->asSet()
    in aliceFavs->includesAll(allBooks)"

# Output: false (Alice's favourites is not a superset of all books)
