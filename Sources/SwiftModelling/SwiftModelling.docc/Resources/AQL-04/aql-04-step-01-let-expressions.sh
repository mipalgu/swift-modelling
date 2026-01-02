# Let Expressions - Variable Bindings in AQL
# Let expressions allow you to bind intermediate values to names for reuse

# Simple let binding with a constant
swift-aql evaluate --model webapp-data.xmi \
  --expression "let highRated = 4.5 in library.books->select(b | b.rating >= highRated)"

# Output: [Book(Foundation), Book(1984), Book(Pride and Prejudice)]

# Let binding reduces repetition and improves readability
# The variable name can be used throughout the expression after 'in'

# Nested let bindings for complex queries
swift-aql evaluate --model webapp-data.xmi \
  --expression "let minPages = 300 in let minRating = 4.0 in
    library.books->select(b | b.pages >= minPages and b.rating >= minRating)"

# Output: [Book(Foundation), Book(A Brief History of Time), Book(The Lord of the Rings)]

# Let bindings with collection operations
swift-aql evaluate --model webapp-data.xmi \
  --expression "let authors = library.authors in
    let prolificAuthors = authors->select(a | a.books->size() >= 3) in
    prolificAuthors->collect(a | a.name)"

# Output: ['Isaac Asimov', 'Jane Austen', 'Arthur Conan Doyle']

# Let with computed values
swift-aql evaluate --model webapp-data.xmi \
  --expression "let totalBooks = library.books->size() in
    let avgRating = library.books->collect(b | b.rating)->sum() / totalBooks in
    library.books->select(b | b.rating >= avgRating)"

# Output: [Books with above-average ratings]

# Let bindings scope - variables are only available after 'in'
swift-aql evaluate --model webapp-data.xmi \
  --expression "let popularThreshold = 1000 in
    let popularBooks = library.books->select(b | b.copies >= popularThreshold) in
    Tuple{
      threshold = popularThreshold,
      count = popularBooks->size(),
      titles = popularBooks->collect(b | b.title)
    }"

# Output: Tuple{threshold=1000, count=5, titles=['Foundation', '1984', ...]}

# Multiple sequential let bindings
swift-aql evaluate --model webapp-data.xmi \
  --expression "let fiction = library.categories->select(c | c.name = 'Fiction')->first() in
    let sciFi = fiction.subcategories->select(s | s.name = 'Science Fiction')->first() in
    sciFi.books->collect(b | b.title)"

# Output: ['Foundation', 'Foundation and Empire', 'Second Foundation']

# Let bindings are immutable - once bound, values cannot change
# This ensures referential transparency and predictable query behaviour
