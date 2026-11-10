# Show the classes, features and operations of the Emfatic metamodel
swift-ecore inspect Library.emf --detail full

# Output:
# Metamodel: Library.emf (Emfatic)
# ================================
#
# Package lending
#   Namespace URI: http://www.example.org/lending
#   Namespace prefix: lend
#   Classes: 4 (1 abstract)
#   Enumerations: 1
#   Data types: 0
#
#   Enumeration Genre
#     fiction = 0
#     poetry = 1
#     reference = 2
#
#   Class Library
#     Attributes:
#       name: EString [1..1]
#     References:
#       items: Item [0..*], containment
#       writers: Writer [0..*], containment
#
#   Abstract class Item
#     Attributes:
#       identifier: EString [1..1], id
#       title: EString [1..1]
#       copies: EInt [0..1], default 1
#     Operations:
#       isLoanable(): EBoolean
#
#   Class Book extends Item
#     Attributes:
#       genre: Genre [0..1]
#     References:
#       authors: Writer [1..*], opposite Writer.books
#
#   Class Writer
#     Attributes:
#       name: EString [1..1]
#     References:
#       books: Book [0..*], opposite Book.authors
