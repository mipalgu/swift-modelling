cd integration

# AQL queries work on the JSON file as on the XMI file
swift-aql query project-data.json -m ProjectManagement.ecore \
  "self.projects->collect(p | p.name + ': ' + p.tasks->size().toString() + ' tasks')"

# Output: ["Customer Portal Redesign: 5 tasks", "Mobile Test Automation: 2 tasks"]

# Follow references: which tasks have not started, and who owns them?
swift-aql query project-data.json -m ProjectManagement.ecore \
  "self.projects.tasks->select(t | t.status = pm::TaskStatus::NOT_STARTED)->collect(t | t.id + ' ' + t.assignee.name)"

# Output: ["TASK-004 Bob Williams", "TASK-005 Alice Chen", "TASK-006 Emma Wilson", "TASK-007 Frank Brown"]

# The same query on the XMI file gives the same answer
swift-aql query project-data.xmi -m ProjectManagement.ecore \
  "self.projects.tasks->select(t | t.status = pm::TaskStatus::NOT_STARTED)->collect(t | t.id + ' ' + t.assignee.name)"

# Output: ["TASK-004 Bob Williams", "TASK-005 Alice Chen", "TASK-006 Emma Wilson", "TASK-007 Frank Brown"]

# Opposite references are kept as well: tasks per team member
swift-aql query project-data.json -m ProjectManagement.ecore \
  "self.members->collect(m | m.name + ': ' + m.assignedTasks->size().toString())"

# Output: ["Alice Chen: 1", "Bob Williams: 2", "Carol Thompson: 1", "David Kim: 1", "Emma Wilson: 1", "Frank Brown: 1"]
