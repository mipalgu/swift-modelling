# Iteration Basics - Processing Each Element
# Fundamental iteration patterns in AQL

# Process each book to create a summary string
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b | b.title + ' (' + b.publicationYear.toString() + ')')"

# Output: ['Pride and Prejudice (1813)', 'Sense and Sensibility (1811)', ...]

# Create book descriptions with multiple fields
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b |
    b.title + ' by ' + b.authors->first().name + ', ' + b.pages.toString() + ' pages')"

# Output: ['Pride and Prejudice by Jane Austen, 432 pages', ...]

# Process authors with their book counts
swift-aql evaluate --model library-data.xmi \
  --expression "library.authors->collect(a |
    a.name + ' (' + a.nationality + ') - ' + a.books->size().toString() + ' book(s)')"

# Output: ['Jane Austen (British) - 2 book(s)', 'Isaac Asimov (American) - 2 book(s)', ...]

# Generate member summaries
swift-aql evaluate --model library-data.xmi \
  --expression "library.members->collect(m |
    m.name + ' (ID: ' + m.memberId + ') - ' +
    m.borrowed->size().toString() + ' borrowed, ' +
    m.favourites->size().toString() + ' favourites')"

# Output: ['Alice Thompson (ID: M001) - 2 borrowed, 3 favourites', ...]

# Process with conditional text
swift-aql evaluate --model library-data.xmi \
  --expression "library.books->collect(b |
    b.title + ': ' + if b.available then 'In Stock' else 'Checked Out' endif)"

# Output: ['Pride and Prejudice: In Stock', ..., 'I, Robot: Checked Out', ...]

# Category hierarchy display
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    c.name + ' -> ' + c.subcategories->collect(s | s.name)->toString())"

# Output: ['Fiction -> [Science Fiction, Fantasy, Mystery]', ...]
