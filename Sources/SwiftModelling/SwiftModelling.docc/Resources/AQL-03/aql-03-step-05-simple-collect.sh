# Nested Collect Operations
# Working with collections within collections

# Get all authors for each book (returns collection of collections)
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.authors)"

# Output: [[Author(Jane Austen)], [Author(Jane Austen)], [Author(Isaac Asimov)], ...]

# Get author names for each book
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.authors->collect(a | a.name))"

# Output: [['Jane Austen'], ['Jane Austen'], ['Isaac Asimov'], ...]

# Collect books from each category
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c | c.subcategories->collect(s | s.name))"

# Output: [['Science Fiction', 'Fantasy', 'Mystery'], ['Biography', 'Science', 'History'], ['Programming', 'Engineering']]

# Collect member borrowing information
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m | m.borrowed->collect(b | b.title))"

# Output: [['Foundation', 'A Brief History of Time'], ['Pride and Prejudice', '1984'], ...]

# Nested collect with transformations
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    c.name + ': ' + c.subcategories->size().toString() + ' subcategories')"

# Output: ['Fiction: 3 subcategories', 'Non-Fiction: 3 subcategories', 'Technical: 2 subcategories']
