# Write the metamodel of the bottom level as Ecore and inspect it
swift-ecore convert products.mdepth shelf.ecore --level 0
swift-ecore inspect shelf.ecore --detail full

# Output:
# Conversion completed: shelf.ecore
# Metamodel: shelf.ecore (Ecore)
# Package Bookshop
#   Namespace URI: urn:swift-ecore:multilevel:view:Catalogue:Shelf:pair
#   Classes: 2
#   Class Book
#     Attributes:
#       pages: EInt [0..1]
#       gst: EDouble [0..1], derived, read-only
#       price: EDouble [0..1], default 0.0
#   Class Magazine
#     Attributes:
#       issue: EInt [0..1]
#       gst: EDouble [0..1], derived, read-only
#       price: EDouble [0..1], default 0.0
