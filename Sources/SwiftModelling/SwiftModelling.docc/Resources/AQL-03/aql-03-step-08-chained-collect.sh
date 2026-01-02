# Min and Max Operations - Finding Extremes
# Find minimum and maximum values in numeric collections

# Find the shortest book (by pages)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)->min()"

# Output: 89 (Notes on Programming)

# Find the longest book (by pages)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)->max()"

# Output: 1178 (The Lord of the Rings)

# Find the cheapest book price
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)->min()"

# Output: 8.99 (Animal Farm)

# Find the most expensive book price
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)->max()"

# Output: 55.0 (Notes on Programming)

# Find the oldest book (earliest publication year)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.publicationYear)->min()"

# Output: 1811 (Sense and Sensibility)

# Find the newest book (latest publication year)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.publicationYear)->max()"

# Output: 2008 (Clean Code)

# Find oldest author birth year
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.birthYear)->min()"

# Output: 1775 (Jane Austen)

# Find maximum number of copies for any single book
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.copies)->max()"

# Output: 10 (1984)
