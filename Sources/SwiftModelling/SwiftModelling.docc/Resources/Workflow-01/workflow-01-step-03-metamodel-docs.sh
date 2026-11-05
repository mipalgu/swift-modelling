# Write a full description of the metamodel: every class with its attributes,
# references, opposites and OCL invariants, the inheritance and the reference graph.
swift-ecore inspect ECommerce.ecore --detail full --show-references --show-supertypes \
    -o ecommerce-metamodel.txt

# Show the part that describes products and their business rules.
sed -n '/^  Class Product/,/Invariants/p' ecommerce-metamodel.txt

# Output:
# Inspection written: ecommerce-metamodel.txt
#   Class Product
#     Attributes:
#       name: EString [1..1]
#       sku: EString [1..1]
#       price: EDouble [0..1]
#       stock: EInt [0..1]
#     References:
#       category: Category [1..1], opposite Category.products
#     Invariants: positivePrice, nonNegativeStock
