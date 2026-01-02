# Average Calculations - Computing Mean Values
# Calculate averages using sum and size

# Calculate average book price
swift-aql evaluate --model library-data.xmi \
  --expression "let prices = library.books->collect(b | b.price)
    in prices->sum() / prices->size()"

# Output: 21.92 (approximately)

# Calculate average page count
swift-aql evaluate --model library-data.xmi \
  --expression "let pages = library.books->collect(b | b.pages)
    in pages->sum() / pages->size()"

# Output: 358.6 (approximately)

# Calculate average copies per book
swift-aql evaluate --model library-data.xmi \
  --expression "let copies = library.books->collect(b | b.copies)
    in copies->sum() / copies->size()"

# Output: 4.67 (approximately)

# Average price of fiction books only
swift-aql evaluate --model library-data.xmi \
  --expression "let fictionBooks = library.books->select(b |
        b.category.code = 'FIC' or b.category.parent.code = 'FIC'),
      prices = fictionBooks->collect(b | b.price)
    in prices->sum() / prices->size()"

# Output: Average price of fiction books

# Average publication year
swift-aql evaluate --model library-data.xmi \
  --expression "let years = library.books->collect(b | b.publicationYear)
    in years->sum() / years->size()"

# Output: 1912 (approximately - the mean publication year)

# Average author birth year
swift-aql evaluate --model library-data.xmi \
  --expression "let years = library.authors->collect(a | a.birthYear)
    in years->sum() / years->size()"

# Output: 1866 (approximately)

# Average books per member (favourites)
swift-aql evaluate --model library-data.xmi \
  --expression "let favCounts = library.members->collect(m | m.favourites->size())
    in favCounts->sum() / favCounts->size()"

# Output: 2.5 (approximately)
