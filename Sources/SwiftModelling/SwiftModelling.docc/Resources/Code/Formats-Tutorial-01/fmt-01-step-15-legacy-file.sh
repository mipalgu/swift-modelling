# Create a KM3 file whose comment is written in ISO-8859-1, as older tools saved it
printf '%b\n' '-- Familles et membres (fichier h\xe9rit\xe9)' > Legacy.km3
cat Families.km3 >> Legacy.km3

swift-ecore inspect Legacy.km3

# Output:
# warning: Legacy.km3: line 1, column 34: The text is not valid UTF-8 and was read as ISO-8859-1
# Metamodel: Legacy.km3 (KM3)
# ===========================
#
# Package Families
#   Namespace URI: http://www.example.org/families
# ...
#   Class Family
#   Class Member
