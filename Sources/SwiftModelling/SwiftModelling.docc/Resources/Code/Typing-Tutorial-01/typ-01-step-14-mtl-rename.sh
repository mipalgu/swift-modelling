# Map the feature and the literal to their new names
swift-mtl check-compat catalogue.mtl \
    --metamodel library=Library.ecore \
    --target-metamodel library=LibraryV2.ecore \
    --rename Book.isbn=ISBN \
    --rename Genre.history=historical
echo "exit status: $?"

# Output:
# compatible (partial): 0 error(s), 0 warning(s)
# exit status: 0
