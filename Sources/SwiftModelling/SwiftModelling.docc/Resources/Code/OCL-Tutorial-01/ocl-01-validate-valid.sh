# Validate the valid bank instance against OCL constraints
swift-ecore validate \
  --metamodel bank-account.ecore \
  --model valid-instance.xmi

# Output:
# Validating model against metamodel constraints...
#
# Checking constraint: uniqueAccountNumbers ... PASSED
# Checking constraint: uniqueCustomerIds ... PASSED
# Checking constraint: validEmail (Customer: John Smith) ... PASSED
# Checking constraint: validEmail (Customer: Jane Doe) ... PASSED
# Checking constraint: validEmail (Customer: Bob Wilson) ... PASSED
# Checking constraint: adultCustomer (Customer: John Smith, age=35) ... PASSED
# Checking constraint: adultCustomer (Customer: Jane Doe, age=28) ... PASSED
# Checking constraint: adultCustomer (Customer: Bob Wilson, age=18) ... PASSED
# Checking constraint: positiveBalance (all accounts) ... PASSED
# Checking constraint: validAccountNumber (all accounts) ... PASSED
# Checking constraint: sufficientMinimumBalance (savings accounts) ... PASSED
# Checking constraint: positiveAmount (all transactions) ... PASSED
# Checking constraint: validDescription (all transactions) ... PASSED
#
# Validation complete: All 13 constraints satisfied.
# Model is VALID.
