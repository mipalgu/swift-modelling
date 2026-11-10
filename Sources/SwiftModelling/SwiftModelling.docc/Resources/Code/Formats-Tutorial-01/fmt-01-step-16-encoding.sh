# Save a copy of the transformation whose first comment is in ISO-8859-1
printf '%b\n' '-- Familles vers personnes (fichier h\xe9rit\xe9)' > Legacy2Persons.atl
cat Families2Persons.atl >> Legacy2Persons.atl

# Name the encoding of the transformation, so it is read without a warning
swift-atl transform Legacy2Persons.atl --encoding latin1 \
  --source sample-Families.xmi --source-metamodel Families.km3 \
  --target legacy-Persons.xmi --target-metamodel Persons.km3

# Output (the time varies):
# Transformation completed successfully in 5.493ms
