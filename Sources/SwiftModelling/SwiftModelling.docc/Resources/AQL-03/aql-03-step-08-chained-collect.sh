# Min and Max Operations - Finding Extremes
# Find minimum and maximum values in numeric collections

# Find the shortest book (by pages) (Notes on Programming)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)->min()"

# Output: 89

# Find the longest book (by pages) (The Lord of the Rings)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.pages)->max()"

# Output: 1178

# Find the cheapest book price (Animal Farm)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)->min()"

# Output: 8.99

# Find the most expensive book price (Notes on Programming)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.price)->max()"

# Output: 55.0

# Find the oldest book (earliest publication year) (Sense and Sensibility)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.publicationYear)->min()"

# Output: 1811

# Find the newest book (latest publication year) (Clean Code)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.publicationYear)->max()"

# Output: 2008

# Find oldest author birth year (Jane Austen)
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a | a.birthYear)->min()"

# Output: 1775

# Find maximum number of copies for any single book (1984)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.copies)->max()"

# Output: 10
