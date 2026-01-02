# Advanced Grouping - Complex Data Organisation
# More sophisticated grouping patterns with aggregation

# Group books by category and count
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    c.name + ': ' + library.books->select(b |
      b.category = c or b.category.parent = c)->size().toString() + ' books')"

# Output: ['Fiction: 10 books', 'Non-Fiction: 3 books', 'Technical: 2 books']

# Group books by price range
swift-aql evaluate --model library-data.xmi \
  --expression "let cheap = library.books->select(b | b.price < 15),
      medium = library.books->select(b | b.price >= 15 and b.price < 30),
      expensive = library.books->select(b | b.price >= 30)
    in 'Under $15: ' + cheap->size() + ' ($' + cheap->collect(b | b.price)->sum().toString() + '), ' +
       '$15-30: ' + medium->size() + ' ($' + medium->collect(b | b.price)->sum().toString() + '), ' +
       'Over $30: ' + expensive->size() + ' ($' + expensive->collect(b | b.price)->sum().toString() + ')'"

# Output: Price range distribution with totals

# Group and aggregate - total pages per category
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    let categoryBooks = library.books->select(b | b.category = c or b.category.parent = c)
    in c.name + ': ' + categoryBooks->collect(b | b.pages)->sum().toString() + ' pages')"

# Output: ['Fiction: 3973 pages', 'Non-Fiction: 1071 pages', 'Technical: 553 pages']

# Books per subcategory
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories.subcategories->collect(s |
    s.name + ': ' + library.books->select(b | b.category = s)->size().toString())"

# Output: ['Science Fiction: 2', 'Fantasy: 2', 'Mystery: 2', 'Biography: 0', 'Science: 3', 'History: 0', 'Programming: 2', 'Engineering: 0']

# Group authors by number of books written
swift-aql evaluate --model library-data.xmi \
  --expression "let oneBook = library.authors->select(a | a.books->size() = 1),
      twoBooks = library.authors->select(a | a.books->size() = 2)
    in 'Authors with 1 book: ' + oneBook->collect(a | a.name) +
       ', Authors with 2 books: ' + twoBooks->collect(a | a.name)"

# Output: Lists of authors grouped by book count
