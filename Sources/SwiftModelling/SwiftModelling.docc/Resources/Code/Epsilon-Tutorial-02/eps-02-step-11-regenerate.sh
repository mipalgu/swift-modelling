# Write your own notes into the protected region of the Smith page
sed 's/No notes yet./The Smiths live next door./' site/families/smith.md > smith.md
mv smith.md site/families/smith.md

# Generate again from the model with Mia, whom the EOL program added
swift-epsilon egl generate families.egx --model Families=families-2.xmi -m Families.ecore \
    -o site
cat site/families/smith.md

# Output:
# unchanged: families/march.md
# unchanged: families/sailor.md
# updated: families/smith.md
# # The Smith family
#
# Members: John, Sarah, Emma, Olivia, Mia
#
# <!-- protected region notes on begin -->
# The Smiths live next door.
# <!-- protected region notes end -->
