# Require every element of the original metamodel, after renaming
# Expected error: the revised metamodel has no address of a library
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --mode total-non-isomorphic \
    --rename Writer=Author,Book.isbn=ISBN,Library.writers=authors \
    --rename Genre.history=historical \
    --allow-widening \
    || echo "exit status: $?"

# Output:
# incompatible (totalNonIsomorphic): 1 error(s), 0 warning(s)
# error: Library!Library.address: provided class 'Library' has no feature 'address' (read) [missingFeature]
# exit status: 1
