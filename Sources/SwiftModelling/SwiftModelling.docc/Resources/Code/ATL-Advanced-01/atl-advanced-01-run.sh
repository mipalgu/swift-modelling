# Run the Class2Relational transformation
swift-atl transform class2relational.atl \
  --source IN=sample-classes.xmi \
  --target OUT=output-relational.xmi

# The metamodels are found through the -- @path directives in the
# transformation, which name class.ecore and relational.ecore beside it.
#
# Output (the time varies):
# Transformation completed successfully in 19.2ms
#
# output-relational.xmi then holds the schema 'library' with:
#   - 4 SQL types (INTEGER, VARCHAR(255), BOOLEAN, DATE)
#   - 6 tables (Author, Book, Member, Loan, Book_keywords, Member_borrowedBooks)
#   - 25 columns, including an id primary key column in each of the 4 class tables
#   - Foreign key columns for class references (author_id, book_id, member_id)
#
# The file also records the opposite references (owner and schema) that the
# metamodel declares, so it is longer than expected-output.xmi, which shows
# the same schema in containment form only.
