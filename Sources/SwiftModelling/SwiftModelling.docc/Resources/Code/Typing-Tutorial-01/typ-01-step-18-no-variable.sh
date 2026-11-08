# Check the query without the type of self
# Expected error: the uses of self cannot be checked, so the verdict is inconclusive
swift-aql check-compat --expression-file long-books.aql \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    --allow-widening \
    || echo "exit status: $?"

# Output:
# compatible (partial, inconclusive): 0 error(s), 0 warning(s)
# uncertain: line 1: variable 'self' is not bound
# uncertain: line 1: feature 'books' applied to an expression of unknown type; candidate owners: library!Library
# exit status: 2
