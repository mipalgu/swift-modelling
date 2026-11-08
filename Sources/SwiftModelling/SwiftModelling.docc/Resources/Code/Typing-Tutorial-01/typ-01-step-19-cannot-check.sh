# Name a query file that does not exist
# Expected error: the check cannot be made
swift-aql check-compat --expression-file long-book.aql \
    --variable self=library::Library \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    || echo "exit status: $?"

# Output:
# Error: Expression file not found or not readable: long-book.aql
# exit status: 3
