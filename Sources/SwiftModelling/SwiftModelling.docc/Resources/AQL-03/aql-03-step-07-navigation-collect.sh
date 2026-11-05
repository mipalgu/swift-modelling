# Sum Operation - Adding Numeric Values
# Sum aggregates numeric collections into a single total

# Calculate total pages across all books
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)->sum()"

# Output: 5379

# Calculate total value of library inventory
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)->sum()"

# Output: 328.87

# Calculate total copies in the library
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.copies)->sum()"

# Output: 70

# Calculate total inventory value (price * copies)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price * b.copies)->sum()"

# Output: 1262.33

# Sum pages of available books only
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.available)->collect(b | b.pages)->sum()"

# Output: 3977

# Sum with filtered collection - total value of fiction books (fiction includes its subcategories)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->select(b | b.category.code = 'FIC' or b.category.parent.code = 'FIC')
    ->collect(b | b.price)->sum()"

# Output: 152.9
