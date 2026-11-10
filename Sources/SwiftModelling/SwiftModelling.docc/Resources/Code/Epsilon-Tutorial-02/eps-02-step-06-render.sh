# Render the overview on standard output, with its title as a parameter
swift-epsilon egl generate families.egl --model Families=sample-Families.xmi -m Families.ecore \
    --param title="Family Overview"

# Output:
# # Family Overview
#
# ## The March family
#
# - Parents: Jim and Cindy
# - Sons: Brandon
# - Daughters: Brenda
#
# ## The Sailor family
#
# - Parents: Peter and Jackie
# - Sons: David, Dylan
# - Daughters: Kelly
#
# ## The Smith family
#
# - Parents: John and Sarah
# - Daughters: Emma, Olivia
