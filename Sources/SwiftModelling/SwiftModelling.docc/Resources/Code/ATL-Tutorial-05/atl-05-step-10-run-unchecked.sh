# Evaluate the query that casts without checking
# Expected error: Ben Okafor is a Developer, so the cast to Manager fails
swift-atl query UncheckedTeamSizes.atl --source organisation.xmi

# Output:
# Query failed: Type error: Cannot cast a value of type 'Developer' to 'Organisation!Manager'
