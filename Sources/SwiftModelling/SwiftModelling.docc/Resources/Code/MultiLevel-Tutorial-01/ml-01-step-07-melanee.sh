# Inspect and validate the model with Melanee potency
swift-ecore inspect products-melanee.mdepth
swift-ecore validate products-melanee.mdepth

# Output:
# Multi-level model: products-melanee.mdepth (MetaDepth)
# Potency scheme: melanee
# Level crossing: declared
# Level 2: Catalogue
#   ProductType @2 { gst, price, discount }
#   Category @* { label }
# Level 1: Bookshop (instance of Catalogue)
#   Book : ProductType @1
#   Fiction : Category @*
# Level 0: Shelf (instance of Bookshop)
#   manual : Book @0
#   crime : Fiction @*
# Validation completed successfully
