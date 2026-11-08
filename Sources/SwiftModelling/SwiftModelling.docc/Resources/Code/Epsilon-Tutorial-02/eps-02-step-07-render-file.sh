# Write the overview to a file instead
swift-epsilon egl generate families.egl --model Families=sample-Families.xmi -m Families.ecore \
    --param title="Family Overview" -o families.md
head -n 3 families.md

# Output:
# created: families.md
# # Family Overview
#
# ## The March family
