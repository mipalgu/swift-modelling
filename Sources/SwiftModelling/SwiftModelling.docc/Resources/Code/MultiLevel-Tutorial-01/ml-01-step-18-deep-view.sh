# The deep instances of ProductType at the bottom level
swift-aql query products.mdepth --deep-view 0 \
  "Bookshop::ProductType.allInstances()->collect(p | p.clabjectName())"

# Their prices, and the GST that their product types set one level up
swift-aql query products.mdepth --deep-view 0 \
  "Bookshop::ProductType.allInstances()->collect(p | p.price)"
swift-aql query products.mdepth --deep-view 0 \
  "Bookshop::ProductType.allInstances()->collect(p | p.gst)"

# The product types themselves, one level up
swift-aql query products.mdepth --deep-view 1 \
  "Catalogue::ProductType.allInstances()->collect(p | p.clabjectName())"

# Output:
# ["manual", "monthly"]
# [35.0, 9.5]
# [0.0, 10.0]
# ["Book", "Magazine"]
