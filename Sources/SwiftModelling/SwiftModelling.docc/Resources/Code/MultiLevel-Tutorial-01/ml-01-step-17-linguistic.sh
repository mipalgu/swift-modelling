# Without a deep view, the model is read as instances of the linguistic metamodel
swift-aql query products.mdepth "self.levels.name"

# Output:
# ["Catalogue", "Bookshop", "Shelf"]
