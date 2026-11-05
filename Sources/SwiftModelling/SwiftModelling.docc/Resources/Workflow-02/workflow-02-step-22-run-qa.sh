cd refactoring
bash comprehensive-qa.sh
# Output:
# == Strict validation (warnings count as failures)
# ...
# Validated 3 files: 3 valid, 0 invalid
# PASS strict validation
# == orders-2024-01
# PASS orders-2024-01: every item refers to a product
# PASS orders-2024-01: statuses unchanged
# PASS orders-2024-01: item amounts unchanged
# ...
# No differences
# PASS orders-2024-01: JSON round trip
# ...
# PASS orders-2024-03: JSON round trip
# QA passed
