# Show the levels of the model and the clabjects of each level
swift-ecore inspect products.mdepth

# Output:
# Multi-level model: products.mdepth (MetaDepth)
# Potency scheme: metadepth
# Level crossing: declared
# Level 2: Catalogue
#   ProductType @2 { gst, price }
# Level 1: Bookshop (instance of Catalogue)
#   Book : ProductType @1 { pages }
#   Magazine : ProductType @1 { issue }
# Level 0: Shelf (instance of Bookshop)
#   manual : Book @0
#   monthly : Magazine @0
