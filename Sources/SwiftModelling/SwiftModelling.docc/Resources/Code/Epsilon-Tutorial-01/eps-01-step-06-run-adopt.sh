# Add a daughter to the Smith family and store the changed model in a new file
swift-epsilon eol run adopt.eol --model Families=sample-Families.xmi -m Families.ecore \
    --param lastName=Smith --param firstName=Mia --store Families=families-2.xmi
grep -n 'firstName="Mia"' families-2.xmi

# Output:
# Mia Smith joins a family of 5
# 21:        <daughters firstName="Mia"/>
