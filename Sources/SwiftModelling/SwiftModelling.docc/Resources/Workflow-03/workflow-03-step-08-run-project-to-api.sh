cd integration

# Check the transformation against both metamodels without running it
swift-atl transform ProjectToAPI.atl --validate-only \
  --source-metamodel ProjectManagement.ecore --target-metamodel ProjectAPI.ecore

# Map the project data to the compact web view; the source may be XMI or JSON
mkdir -p web
swift-atl transform ProjectToAPI.atl \
  --source project-data.json --source-metamodel ProjectManagement.ecore \
  --target web/project-summary.json --target-metamodel ProjectAPI.ecore

# Output: Transformation completed successfully

# The result is an instance of ProjectAPI.ecore
swift-ecore validate web/project-summary.json -m ProjectAPI.ecore

# Output: Validation completed successfully

# People are now names, dependencies are identifiers, and totals are computed
grep -A 9 '"department" : "ENG"' web/project-summary.json

# Output:
# "department" : "ENG",
# "eClass" : "http://www.example.org/projectapi/1.0#//ProjectSummary",
# "estimatedHours" : 360,
# "id" : "PROJ-001",
# "name" : "Customer Portal Redesign",
# "openTaskCount" : 3,
# "owner" : "Alice Chen",
# "status" : "ACTIVE",
# "taskCount" : 5,

# Web clients can query the view directly
swift-aql query web/project-summary.json -m ProjectAPI.ecore \
  "self.projects->collect(p | p.id + ': ' + p.openTaskCount.toString() + ' of ' + p.taskCount.toString() + ' tasks open')"

# Output: ["PROJ-001: 3 of 5 tasks open", "PROJ-002: 2 of 2 tasks open"]
