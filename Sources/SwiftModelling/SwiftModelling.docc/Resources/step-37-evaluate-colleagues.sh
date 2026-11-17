# From an employee, the employer reference leads to the company
swift-aql query company-model.xmi --query "self.employer" --context "emp1"

# Output: Company(Tech Innovations Ltd)

# From the company, its opposite reference, employees, leads to everyone, the employee included
swift-aql query company-model.xmi --query "self.employer.employees" --context "emp1"

# Output: [Employee(Alice Johnson), Employee(Bob Smith), Manager(Carol Williams)]

# Leave out the employee itself to get the colleagues
swift-aql query company-model.xmi --query-file queries/colleagues.aql --context "emp1"

# Output: ["Bob Smith", "Carol Williams"]

# The same query answers for any employee, here the manager
swift-aql query company-model.xmi --query-file queries/colleagues.aql --context "mgr1"

# Output: ["Alice Johnson", "Bob Smith"]
