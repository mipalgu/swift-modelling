# Validate with strict levels, which admit no crossing at all
# Expected error: the declared reference, the leap potency and the deep reference all cross levels
swift-ecore validate displays.mdepth --level-crossing strict

# Output:
# error: 'ProductType.seeAlso' is declared to refer to level 1, which crosses levels (--level-crossing strict)
# error: 'Display' has a leap potency, which crosses levels (--level-crossing strict)
# error: 'Display.items' is a deep reference, which crosses levels (--level-crossing strict)
# Error: Validation failed: 3 error(s), 0 warning(s)
