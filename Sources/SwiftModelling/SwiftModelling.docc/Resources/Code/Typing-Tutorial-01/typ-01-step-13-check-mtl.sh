# Check the template module against the revised metamodel
# Expected error: the template reads isbn and the literal history
swift-mtl check-compat catalogue.mtl \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    || echo "exit status: $?"

# Output:
# incompatible (partial): 2 error(s), 1 warning(s)
# error: library!Book.isbn: provided class 'Book' has no feature 'isbn' (read) [missingFeature]
# error: library!Genre.history: provided enumeration 'Genre' has no literal 'history' [missingLiteral]
# warning: library!Genre.historical: 'Book.genre' is read, and models may hold literal 'historical' of 'Genre', which the module does not know [unexpectedLiteral]
# hint: --rename Book.isbn=ISBN (caseDifference)
# hint: --rename Genre.history=historical (uniqueStructuralCandidate)
# exit status: 1
