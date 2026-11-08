# Check the transformation against the metamodel it was written for
swift-atl check-compat Library2Catalogue.atl \
    --metamodel Library=Library.ecore \
    --metamodel Catalogue=Catalogue.ecore \
    --target-metamodel Library=Library.ecore
echo "exit status: $?"

# Output:
# compatible (partial): 0 error(s), 0 warning(s)
# exit status: 0
