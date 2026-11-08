# Check the transformation against the revised library metamodel
# Expected error: the revised metamodel has no class Writer
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    || echo "exit status: $?"

# Output:
# incompatible (partial): 2 error(s), 0 warning(s)
# error: Library!Book.authors: provided type 'Author' is not a subclass of required type 'Writer' [featureTypeMismatch]
# error: Library!Writer: provided metamodel has no class 'Writer' [missingClass]
# hint: --rename Writer=Author (similarStructure)
# exit status: 1
