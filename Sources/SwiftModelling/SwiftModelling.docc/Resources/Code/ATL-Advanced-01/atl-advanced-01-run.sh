# Run the Class2Relational transformation
swift-atl transform \
  --transformation class2relational.atl \
  --source-metamodel class.ecore \
  --target-metamodel relational.ecore \
  --input sample-classes.xmi \
  --output output-relational.xmi

# Output:
# Transformation complete.
# Created schema 'library' with:
#   - 6 tables (Author, Book, Member, Loan, Book_keywords, Member_borrowedBooks)
#   - 4 SQL types (INTEGER, VARCHAR(255), BOOLEAN, DATE)
#   - Primary key columns for each main table
#   - Foreign key columns for class references
