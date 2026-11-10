# Match classes by object type matching, then by MOF class matching
# Expected error: MOF class matching compares the multiplicities exactly
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --rename Writer=Author \
    --subtyping object-type-matching
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --rename Writer=Author \
    --subtyping mof-class-matching \
    || echo "exit status: $?"

# Output:
# compatible (partial): 0 error(s), 0 warning(s)
# incompatible (partial): 1 error(s), 0 warning(s)
# error: Library!Book.authors: lower bounds differ: required [0..*], provided [1..*] [multiplicityMismatch]
# exit status: 1
