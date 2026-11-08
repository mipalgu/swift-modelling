# Follow the hint and map Writer to Author
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=LibraryV2.ecore \
    --rename Writer=Author
echo "exit status: $?"

# Output:
# compatible (partial): 0 error(s), 0 warning(s)
# exit status: 0
