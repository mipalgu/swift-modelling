cd integration

# A textual diff is useless across formats; compare the models instead.
# Objects are matched by class and identifier, whatever the file format.
swift-ecore compare project-data.xmi updated-project-data.json -m ProjectManagement.ecore

# Output:
# Comparing models: project-data.xmi -> updated-project-data.json
# ~ object Milestone 'Backend API Ready' (//@projects.0/@milestones.1) completed: false -> true
# ~ object Task 'Implement authentication API' (//@projects.0/@tasks.2) status: IN_PROGRESS -> COMPLETED
# ~ object Task 'Implement authentication API' (//@projects.0/@tasks.2) actualHours: 35.0 -> 78.0
# ~ object Task 'Implement customer data API' (//@projects.0/@tasks.3) status: NOT_STARTED -> IN_PROGRESS
# ~ object Task 'Implement customer data API' (//@projects.0/@tasks.3) actualHours: 0.0 -> 12.0
# ~ object Project 'Mobile Test Automation' (//@projects.1) status: PLANNING -> ACTIVE
# ~ object TeamMember 'Frank Brown' (//@members.5) assignedTasks: [Task 'Evaluate testing tools'] -> [Task 'Evaluate testing tools', Task 'Set up device lab']
# + object Comment 'CMT-003' (//@projects.0/@tasks.2/@comments.1)
# + object Task 'Set up device lab' (//@projects.1/@tasks.2)
# 9 differences: 2 added, 0 removed, 7 changed

# --summary counts the objects of each class in both versions
swift-ecore compare project-data.xmi updated-project-data.json -m ProjectManagement.ecore --summary

# Output:
# Objects per class:
#   Comment: 2 -> 3 (+1)
# ...
#   Task: 7 -> 8 (+1)
#   TeamMember: 6 -> 6
#   Total: 25 -> 27 (+2)
# Objects: 2 added, 0 removed, 5 changed, 20 unchanged
