cd integration

# Apply the domain rule to the web editor's model; refining mode copies
# everything that no rule matches
mkdir -p sync
swift-atl transform ReconcileProject.atl --refining \
  --source updated-project-data.json --target sync/reconciled-project-data.json \
  --metamodel ProjectManagement.ecore

# Output: Transformation completed successfully

# The rule changed exactly one value: MS-002 is open again
swift-ecore compare updated-project-data.json sync/reconciled-project-data.json -m ProjectManagement.ecore

# Output:
# Comparing models: updated-project-data.json -> reconciled-project-data.json
# ~ object Milestone 'Backend API Ready' (//@projects.0/@milestones.1) completed: true -> false
# 1 difference: 0 added, 0 removed, 1 changed

# Write XMI for the desktop tool; --validate writes nothing if the model is invalid
swift-ecore convert sync/reconciled-project-data.json sync/project-data.xmi -m ProjectManagement.ecore --validate

# Output: Conversion completed: sync/project-data.xmi

swift-aql query sync/project-data.xmi -m ProjectManagement.ecore \
  "self.projects.milestones->collect(m | m.id + ' ' + m.completed.toString())"

# Output: ["MS-001 true", "MS-002 false", "MS-003 false", "MS-004 false"]

# Round trip: XMI to JSON and back must reproduce the original model
swift-ecore convert project-data.xmi sync/roundtrip.json -m ProjectManagement.ecore
swift-ecore convert sync/roundtrip.json sync/roundtrip.xmi -m ProjectManagement.ecore

# --exit-code makes the comparison fail if there is any difference
swift-ecore compare project-data.xmi sync/roundtrip.xmi -m ProjectManagement.ecore --exit-code

# Output:
# Comparing models: project-data.xmi -> roundtrip.xmi
# No differences
