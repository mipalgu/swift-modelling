# Leave out the metamodel of the target model
# Expected error: without Catalogue.ecore, the verdict is inconclusive
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --rename Writer=Author \
    || echo "exit status: $?"

# Output:
# compatible (partial, inconclusive): 0 error(s), 0 warning(s)
# uncertain: line 1: no model type was given for metamodel 'Catalogue'
# uncertain: line 8: type 'Catalogue::Entry' names an unknown metamodel 'Catalogue'
# uncertain: line 9: feature 'title' applied to an expression of unknown type
# uncertain: line 10: feature 'creators' applied to an expression of unknown type
# exit status: 2
