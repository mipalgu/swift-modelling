# Require equal names for everything that the transformation uses
# Expected error: renamings do not apply in an isomorphic mode
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --rename Writer=Author \
    --mode partial-isomorphic \
    || echo "exit status: $?"

# Output:
# warning: --rename is ignored in the mode partial-isomorphic, which admits no renaming
# incompatible (partialIsomorphic): 2 error(s), 0 warning(s)
# error: Library!Book.authors: provided type 'Author' is not a subclass of required type 'Writer' [featureTypeMismatch]
# error: Library!Writer: provided metamodel has no class 'Writer' [missingClass]
# hint: --rename Writer=Author (similarStructure)
# exit status: 1
