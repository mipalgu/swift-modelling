# Validate the invalid bank instance against its metamodel and OCL constraints
# Expected error: the instance violates nine invariants, so validation fails
swift-ecore validate invalid-instance.xmi --metamodel bank-account.ecore \
  || echo "swift-ecore exited with status $?"

# Output:
# Checking constraint: uniqueAccountNumbers (Bank 'Problem Bank', /) ... violated
# Checking constraint: uniqueCustomerIds (Bank 'Problem Bank', /) ... violated
# Checking constraint: validEmail (Customer 'Tommy Young', //@customers.0) ... violated
# Checking constraint: adultCustomer (Customer 'Tommy Young', //@customers.0) ... violated
# Checking constraint: positiveBalance (Account '12345', //@accounts.0) ... violated
# Checking constraint: validAccountNumber (Account '12345', //@accounts.0) ... violated
# Checking constraint: positiveAmount (Transaction 'TXN001', //@accounts.0/@transactions.0) ... violated
# Checking constraint: validDescription (Transaction 'TXN002', //@accounts.0/@transactions.1) ... violated
# Checking constraint: sufficientMinimumBalance (Account '1234567890', //@accounts.2) ... violated
# OCL invariants: 14 of 23 check(s) satisfied
# Error: Validation failed: 9 error(s), 0 warning(s)
# swift-ecore exited with status 1
