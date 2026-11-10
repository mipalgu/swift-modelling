# Transform the families into persons, printing each rule application
swift-epsilon etl transform Families2Persons.etl --model Families=sample-Families.xmi \
    --target Persons=persons.xmi -m Families.ecore -m Persons.ecore --trace

# Output:
# Member2Male: Member -> Male
# ...
# Member2Female: Member -> Female
