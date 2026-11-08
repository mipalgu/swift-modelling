# Run the rules of the module, writing the pages below site/
swift-epsilon egl generate families.egx --model Families=sample-Families.xmi -m Families.ecore \
    -o site
cat site/families/smith.md

# Output:
# created: families/march.md
# created: families/sailor.md
# created: families/smith.md
# # The Smith family
#
# Members: John, Sarah, Emma, Olivia
#
# <!-- protected region notes on begin -->
# No notes yet.
# <!-- protected region notes end -->
