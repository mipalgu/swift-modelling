# Validate the invalid bank instance against OCL constraints
swift-ecore validate \
  --metamodel bank-account.ecore \
  --model invalid-instance.xmi

# Output:
# Validating model against metamodel constraints...
#
# Checking constraint: uniqueAccountNumbers ... FAILED
#   Violation: Duplicate account number '1234567890' found
#
# Checking constraint: uniqueCustomerIds ... FAILED
#   Violation: Duplicate customer ID 'CUST001' found
#
# Checking constraint: validEmail (Customer: Tommy Young) ... FAILED
#   Violation: Email 'invalid-email' does not contain '@'
#
# Checking constraint: adultCustomer (Customer: Tommy Young) ... FAILED
#   Violation: Customer age 16 is less than required minimum 18
#
# Checking constraint: positiveBalance (Account: 12345) ... FAILED
#   Violation: Balance -500.00 is negative
#
# Checking constraint: validAccountNumber (Account: 12345) ... FAILED
#   Violation: Account number '12345' has 5 digits, expected 10
#
# Checking constraint: sufficientMinimumBalance (Account: 9999888877) ... FAILED
#   Violation: Savings balance 50.00 is below minimum 100.00
#
# Checking constraint: positiveAmount (Transaction: TXN001) ... FAILED
#   Violation: Transaction amount -100.00 is negative
#
# Checking constraint: validDescription (Transaction: TXN002) ... FAILED
#   Violation: Transaction description is empty
#
# Validation complete: 9 constraint violations found.
# Model is INVALID.
