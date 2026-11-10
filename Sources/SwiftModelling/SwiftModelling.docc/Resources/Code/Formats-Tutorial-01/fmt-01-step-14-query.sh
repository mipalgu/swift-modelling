# Query the result with the KM3 metamodel as its metamodel
swift-ecore query output-Persons.xmi --metamodel Persons.km3 --query "find Female"

# Output:
# Objects matching 'Female'
# =========================
# Found 7 match(es)
#
# 1. Female 'Cindy March' (/6)
#    fullName = "Cindy March"
# ...
# 7. Female 'Olivia Smith' (/12)
#    fullName = "Olivia Smith"
