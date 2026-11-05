# Set Operations - Union, Intersection, Difference
# Working with sets and unique collections

# Convert collection to set (remove duplicates)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.nationality)->asSet()"

# Output: ["British", "American", "Polish"]

# Union of two collections - all favourite and borrowed books
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten(),
      favourites = library.members->collect(m | m.favourites)->flatten()
    in borrowed->union(favourites)->asSet()->size()"

# Output: 14

# Intersection - books that are both borrowed AND favourited
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in borrowed->intersection(favourites)->collect(b | b.title)"

# Output: ["Foundation", "A Brief History of Time", "Pride and Prejudice", "1984", ..., "On the Origin of Species"]

# Difference - favourites that are not currently borrowed
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in favourites->difference(borrowed)->collect(b | b.title)"

# Output: ["I, Robot", "Sense and Sensibility", "The ABC Murders", "Radioactive Substances"]

# Symmetric difference - books in one set but not both (the union of both differences)
swift-aql evaluate --model library-data.xmi \
  --expression "let borrowed = library.members->collect(m | m.borrowed)->flatten()->asSet(),
      favourites = library.members->collect(m | m.favourites)->flatten()->asSet()
    in borrowed->difference(favourites)->union(favourites->difference(borrowed))->size()"

# Output: 4

# Check if one set is subset of another (Alice's favourites do not include every book)
swift-aql evaluate --model library-data.xmi \
  --expression "let aliceFavs = library.members->select(m | m.name = 'Alice Thompson')->first().favourites->asSet(),
      allBooks = library.books->asSet()
    in aliceFavs->includesAll(allBooks)"

# Output: false
