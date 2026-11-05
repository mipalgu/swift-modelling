cd integration

# Check the three templates before generating
swift-mtl validate GenerateRestAPI.mtl GenerateSwiftAPI.mtl GenerateEventAPI.mtl

# Generate the REST description, the shared DTOs and the server routes
swift-mtl generate GenerateRestAPI.mtl --model ProjectManagement.ecore --output api/rest

# Generate the Swift client and the event API
swift-mtl generate GenerateSwiftAPI.mtl --model ProjectManagement.ecore --output api/client
swift-mtl generate GenerateEventAPI.mtl --model ProjectManagement.ecore --output api/events

ls api/rest/openapi.yaml api/rest/*.swift api/client/*.swift api/events/*.swift

# Output:
# api/client/ProjectManagementClient.swift
# api/events/ProjectManagementEvents.swift
# api/rest/DTOs.swift
# api/rest/openapi.yaml
# api/rest/routes.swift

# Every class with an identifier became a REST resource
grep -E '^  /[a-z]+:' api/rest/openapi.yaml

# Output:
# /departments:
# /teammembers:
# /projects:
# /milestones:
# /tasks:
# /comments:

# The DTOs, the client and the events use Foundation only: type-check them
# together (routes.swift needs the Vapor package of a server project)
swiftc -typecheck api/rest/DTOs.swift api/client/ProjectManagementClient.swift \
  api/events/ProjectManagementEvents.swift
echo "Type check passed"

# Output: Type check passed

# Generation is repeatable: record checksums, regenerate, and compare
shasum -a 256 api/rest/openapi.yaml api/rest/*.swift api/client/*.swift api/events/*.swift > api-checksums.txt
swift-mtl generate GenerateRestAPI.mtl --model ProjectManagement.ecore --output api/rest
shasum -a 256 -c api-checksums.txt

# Output:
# api/rest/openapi.yaml: OK
# api/rest/DTOs.swift: OK
# api/rest/routes.swift: OK
# api/client/ProjectManagementClient.swift: OK
# api/events/ProjectManagementEvents.swift: OK
