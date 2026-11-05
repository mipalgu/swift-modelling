# Advanced Grouping - Complex Data Organisation
# More sophisticated grouping patterns with aggregation

# Group books by category and count
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    c.name + ': ' + library.books->select(b |
      b.category = c or b.category.parent = c)->size().toString() + ' books')"

# Output: ["Fiction: 10 books", "Non-Fiction: 3 books", "Technical: 2 books"]

# Group books by price range
swift-aql evaluate --model library-data.xmi \
  --expression "let cheap = library.books->select(b | b.price < 15),
      medium = library.books->select(b | b.price >= 15 and b.price < 30),
      expensive = library.books->select(b | b.price >= 30)
    in 'Under 15: ' + cheap->size().toString() + ' ($' + cheap->collect(b | b.price)->sum().toString() + '), ' +
       '15 to 30: ' + medium->size().toString() + ' ($' + medium->collect(b | b.price)->sum().toString() + '), ' +
       'Over 30: ' + expensive->size().toString() + ' ($' + expensive->collect(b | b.price)->sum().toString() + ')'"

# Output: "Under 15: 8 ($100.91999999999999), 15 to 30: 3 ($51.97), Over 30: 4 ($175.98000000000002)"

# Group and aggregate - total pages per category
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories->collect(c |
    let categoryBooks = library.books->select(b | b.category = c or b.category.parent = c)
    in c.name + ': ' + categoryBooks->collect(b | b.pages)->sum().toString() + ' pages')"

# Output: ["Fiction: 3755 pages", "Non-Fiction: 1071 pages", "Technical: 553 pages"]

# Books per subcategory
swift-aql evaluate --model library-data.xmi \
  --expression "library.categories.subcategories->collect(s |
    s.name + ': ' + library.books->select(b | b.category = s)->size().toString())"

# Output: ["Science Fiction: 2", "Fantasy: 2", "Mystery: 2", "Biography: 0", "Science: 3", "History: 0", "Programming: 2", "Engineering: 0"]

# Group authors by number of books written
swift-aql evaluate --model library-data.xmi \
  --expression "let oneBook = library.authors->select(a | a.books->size() = 1),
      twoBooks = library.authors->select(a | a.books->size() = 2)
    in 'Authors with 1 book: ' + oneBook->collect(a | a.name)->sep('[', ', ', ']') +
       ', Authors with 2 books: ' + twoBooks->collect(a | a.name)->sep('[', ', ', ']')"

# Output: "Authors with 1 book: [Stephen Hawking, Robert Martin, Marie Curie, Ada Lovelace, Charles Darwin], Authors with 2 books: [Jane Austen, Isaac Asimov, Agatha Christie, J.R.R. Tolkien, George Orwell]"
