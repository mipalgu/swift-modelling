# Export the structure of the metamodel as JSON for web-based tools and
# other programs that do not read Ecore.
swift-ecore inspect ECommerce.ecore --detail full --format json -o ecommerce-metamodel.json

# The JSON lists the package with its namespace URI, and every class with
# its attributes, references and constraints, such as those of Product.
grep '"nsURI"' ecommerce-metamodel.json
grep -m 1 -A 3 '"constraints"' ecommerce-metamodel.json

# Output:
# Inspection written: ecommerce-metamodel.json
# "nsURI" : "http://www.example.org/shop",
# "constraints" : [
# "positivePrice",
# "nonNegativeStock"
