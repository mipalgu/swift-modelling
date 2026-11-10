# Any reference may cross levels in a non-strict model
swift-ecore validate displays-undeclared.mdepth --level-crossing non-strict

# Expected error: by default, seeAlso must not leave its level without declaring it
swift-ecore validate displays-undeclared.mdepth

# Output:
# Validation completed successfully
# error: 'Shelf.manual.seeAlso' refers to 'Bookshop.Magazine' at level 1, but it may refer only to level 0, as it declares no other target level
# Error: Validation failed: 1 error(s), 0 warning(s)
