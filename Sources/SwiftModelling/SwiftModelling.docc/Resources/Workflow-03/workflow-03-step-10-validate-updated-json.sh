cd integration

# Check the file from the web editor before anything else uses it
swift-ecore validate updated-project-data.json -m ProjectManagement.ecore

# Output: Validation completed successfully

# Queries show the edits: task states and the new task of PROJ-002
swift-aql query updated-project-data.json -m ProjectManagement.ecore \
  "self.projects.tasks->select(t | t.status <> pm::TaskStatus::NOT_STARTED)->collect(t | t.id + ' ' + t.status.toString())"

# Output: ["TASK-001 COMPLETED", "TASK-002 COMPLETED", "TASK-003 COMPLETED", "TASK-004 IN_PROGRESS", "TASK-008 IN_PROGRESS"]

# Validation protects the other tools: a web client that sends a status
# the metamodel does not define is rejected before the data spreads
sed 's/"status" : "IN_PROGRESS"/"status" : "STARTED"/' updated-project-data.json > rejected-update.json

# Expected error: STARTED is not a literal of TaskStatus
swift-ecore validate rejected-update.json -m ProjectManagement.ecore

# Output:
# error: Task 'Implement customer data API' (//@projects.0/@tasks.3): Value 'STARTED' is not a literal of enumeration TaskStatus (feature 'status')
# error: Task 'Set up device lab' (//@projects.1/@tasks.2): Value 'STARTED' is not a literal of enumeration TaskStatus (feature 'status')
# Error: Validation failed: 2 error(s), 0 warning(s)
