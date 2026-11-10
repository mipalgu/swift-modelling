# List the classes of the UML model with their features
swift-ecore query Library.uml --query "find Class"

# Output:
# Objects matching 'Class'
# ========================
# Found 4 match(es)
#
# 1. Class 'Library' (//@packagedElement.0)
#    name = "Library"
#    ownedAttribute: 2 contained object(s)
#
# 2. Class 'Item' (//@packagedElement.1)
#    name = "Item"
#    isAbstract = true
#    ownedAttribute: 1 contained object(s)
#
# 3. Class 'Book' (//@packagedElement.2)
#    name = "Book"
#    generalization: 1 contained object(s)
#    ownedAttribute: 4 contained object(s)
#
# 4. Class 'Writer' (//@packagedElement.3)
#    name = "Writer"
#    ownedAttribute: 1 contained object(s)
