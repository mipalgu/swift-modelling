# Accept a narrower numeric type for a feature that the query only reads
swift-aql check-compat --expression-file long-books.aql \
    --variable self=library::Library \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    --allow-widening
echo "exit status: $?"

# Write the same report as JSON
swift-aql check-compat --expression-file long-books.aql \
    --variable self=library::Library \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    --allow-widening --format json > long-books-report.json
head -n 3 long-books-report.json

# Output:
# compatible (partial): 0 error(s), 0 warning(s)
# exit status: 0
# {
#   "compatible" : true,
#   "conclusive" : true,
