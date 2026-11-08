# The attributes that Book declares itself
swift-aql evaluate --model Library.uml \
  --expression "model.packagedElement->filter(uml::Class)->select(c | c.name = 'Book').ownedAttribute.name"

# Output:
# ["isbn", "pages", "genre", "authors"]

# The classes that Book specialises
swift-aql evaluate --model Library.uml \
  --expression "model.packagedElement->filter(uml::Class)->select(c | c.name = 'Book').generalization.general.name"

# Output:
# ["Item"]
