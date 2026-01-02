# Grouping Basics - Organising Data by Criteria
# Group elements by shared characteristics

# Group books by availability status
swift-aql evaluate --model library-data.xmi \
  --expression "let available = library.books->select(b | b.available),
      unavailable = library.books->reject(b | b.available)
    in 'Available: ' + available->size() + ', Unavailable: ' + unavailable->size()"

# Output: "Available: 13, Unavailable: 2"

# Group authors by nationality
swift-aql evaluate --model library-data.xmi \
  --expression "let british = library.authors->select(a | a.nationality = 'British'),
      american = library.authors->select(a | a.nationality = 'American'),
      polish = library.authors->select(a | a.nationality = 'Polish')
    in 'British: ' + british->size() + ', American: ' + american->size() + ', Polish: ' + polish->size()"

# Output: "British: 7, American: 2, Polish: 1"

# List British author names
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->select(a | a.nationality = 'British')->collect(a | a.name)"

# Output: ['Jane Austen', 'Agatha Christie', 'Stephen Hawking', 'J.R.R. Tolkien', 'George Orwell', 'Ada Lovelace', 'Charles Darwin']

# Group books by publication century
swift-aql evaluate --model library-data.xmi \
  --expression "let c19 = library.books->select(b | b.publicationYear < 1900),
      c20 = library.books->select(b | b.publicationYear >= 1900 and b.publicationYear < 2000),
      c21 = library.books->select(b | b.publicationYear >= 2000)
    in '19th century: ' + c19->size() + ', 20th century: ' + c20->size() + ', 21st century: ' + c21->size()"

# Output: "19th century: 4, 20th century: 10, 21st century: 1"

# Group members by membership decade
swift-aql evaluate --model library-data.xmi \
  --expression "let pre2020 = library.members->select(m | m.membershipYear < 2020),
      post2020 = library.members->select(m | m.membershipYear >= 2020)
    in 'Before 2020: ' + pre2020->size() + ', 2020 onwards: ' + post2020->size()"

# Output: "Before 2020: 2, 2020 onwards: 4"
