# Check the query, with the type of self
# Expected error: pages is an ELong in the original and an EInt in the revision
swift-aql check-compat --expression-file long-books.aql \
    --variable self=library::Library \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    || echo "exit status: $?"

# Output:
# incompatible (partial): 1 error(s), 0 warning(s)
# error: library!Book.pages: provided data type 'EInt' is not compatible with required 'ELong' when read (numeric widening is off) [featureTypeMismatch]
# exit status: 1
