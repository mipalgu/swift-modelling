cd integration

# Check the XMI file of the desktop tool against the shared metamodel
swift-ecore validate project-data.xmi -m ProjectManagement.ecore

# Output: Validation completed successfully

# Convert it to JSON for the web editor; -m reads and writes it with the
# classes, enumerations and references that the metamodel defines
swift-ecore convert project-data.xmi project-data.json -m ProjectManagement.ecore

# Output: Conversion completed: project-data.json

# The JSON file is an instance of the same metamodel
swift-ecore validate project-data.json -m ProjectManagement.ecore

# Output: Validation completed successfully

# Both files hold the same model: compare them object by object
swift-ecore compare project-data.xmi project-data.json -m ProjectManagement.ecore --exit-code

# Output:
# Comparing models: project-data.xmi -> project-data.json
# No differences

# Every object names its class in eClass; references are {"$ref": path}
# objects with the same fragment paths as in the XMI file
grep -B 12 -A 3 '"id" : "TASK-004"' project-data.json

# Output:
# "assignee" : {
# "$ref" : "//@members.1"
# ...
# "dependencies" : [
# "$ref" : "//@projects.0/@tasks.2"
# ...
# "eClass" : "http://www.example.org/projectmanagement/1.0#//Task",
# "estimatedHours" : 60,
# "id" : "TASK-004",
# "priority" : "HIGH",
# "status" : "NOT_STARTED",
