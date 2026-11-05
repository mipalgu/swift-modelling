# Evaluate a query on the company, selected by its xmi:id
swift-aql query company-model.xmi --query "self.employees" --context "company1"

# Output: [Employee(Alice Johnson), Employee(Bob Smith), Manager(Carol Williams)]

# Evaluate the query saved in a file
swift-aql query company-model.xmi --query-file queries/all-employees.aql --context "company1"

# Output: [Employee(Alice Johnson), Employee(Bob Smith), Manager(Carol Williams)]
