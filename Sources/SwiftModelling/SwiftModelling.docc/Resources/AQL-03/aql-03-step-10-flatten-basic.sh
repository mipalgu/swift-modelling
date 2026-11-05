# Average Calculations - Computing Mean Values
# Calculate averages using sum and size
# Dividing an integer by an integer truncates, so multiply an integer sum by 1.0
# to get a real average

# Calculate average book price
swift-aql evaluate --model library-data.xmi \
  --expression "let prices = library.books->collect(b | b.price)
    in prices->sum() / prices->size()"

# Output: 21.924666666666667

# Calculate average page count
swift-aql evaluate --model library-data.xmi \
  --expression "let pages = library.books->collect(b | b.pages)
    in pages->sum() * 1.0 / pages->size()"

# Output: 358.6

# Calculate average copies per book
swift-aql evaluate --model library-data.xmi \
  --expression "let copies = library.books->collect(b | b.copies)
    in copies->sum() * 1.0 / copies->size()"

# Output: 4.666666666666667

# Average price of fiction books only
swift-aql evaluate --model library-data.xmi \
  --expression "let fictionBooks = library.books->select(b |
        b.category.code = 'FIC' or b.category.parent.code = 'FIC'),
      prices = fictionBooks->collect(b | b.price)
    in prices->sum() / prices->size()"

# Output: 15.290000000000001

# Average publication year
swift-aql evaluate --model library-data.xmi \
  --expression "let years = library.books->collect(b | b.publicationYear)
    in years->sum() * 1.0 / years->size()"

# Output: 1918.8

# Average author birth year
swift-aql evaluate --model library-data.xmi \
  --expression "let years = library.authors->collect(a | a.birthYear)
    in years->sum() * 1.0 / years->size()"

# Output: 1876.5

# Average books per member (favourites)
swift-aql evaluate --model library-data.xmi \
  --expression "let favCounts = library.members->collect(m | m.favourites->size())
    in favCounts->sum() * 1.0 / favCounts->size()"

# Output: 2.6666666666666665
