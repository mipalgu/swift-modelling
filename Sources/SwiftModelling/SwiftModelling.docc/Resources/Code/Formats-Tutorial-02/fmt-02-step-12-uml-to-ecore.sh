# Convert the classes of the UML model into an Ecore metamodel
swift-ecore convert Library.uml LibraryModel.ecore
swift-ecore inspect LibraryModel.ecore --detail full

# Output:
# Conversion completed: LibraryModel.ecore
# Metamodel: LibraryModel.ecore (Ecore)
# =====================================
#
# Package LibraryModel
#   Namespace URI: http:///LibraryModel.ecore
#   Namespace prefix: LibraryModel
#   Classes: 4 (1 abstract)
#   Enumerations: 1
#   Data types: 0
#
#   Enumeration Genre
#     Fiction = 0
#     Poetry = 1
#     Reference = 2
#
#   Class Library
#     Attributes:
#       name: EString [1..1]
#     References:
#       items: Item [0..*], containment
#
#   Abstract class Item
#     Attributes:
#       title: EString [1..1]
#
#   Class Book extends Item
#     Attributes:
#       isbn: EString [1..1]
#       pages: EInt [1..1]
#       genre: Genre [1..1]
#     References:
#       authors: Writer [1..*]
#
#   Class Writer
#     Attributes:
#       name: EString [1..1]
