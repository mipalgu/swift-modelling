# Run the report against the families, with a value for its parameter
swift-epsilon eol run report.eol --model Families=sample-Families.xmi -m Families.ecore \
    --param greeting=Hello

# Output:
# March: Jim and Cindy, 2 children
# Sailor: Peter and Jackie, 3 children
# Smith: John and Sarah, 2 children
# Members: 13
# Greeting: Hello
