# The names of the classes that the model declares
swift-aql evaluate --model Library.uml \
  --expression "model.packagedElement->filter(uml::Class).name"

# Output:
# ["Library", "Item", "Book", "Writer"]

# The abstract classes
swift-aql evaluate --model Library.uml \
  --expression "model.packagedElement->filter(uml::Class)->select(c | c.isAbstract).name"

# Output:
# ["Item"]
