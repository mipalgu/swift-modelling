# Run the XMI to JSON transformation
# Converts Java EMF project data to web-friendly JSON format

# Execute the ATL transformation
swift-atl transform XMI2JSON.atl \
    --source project-data.xmi \
    --source-metamodel ProjectManagement.ecore \
    --target project-data.json \
    --target-metamodel JsonModel.ecore \
    --verbose

# Output:
# [INFO] Loading source metamodel: ProjectManagement.ecore
# [INFO] Loading target metamodel: JsonModel.ecore
# [INFO] Loading source model: project-data.xmi
# [INFO] Compiling transformation: XMI2JSON.atl
# [INFO] Executing transformation...
#
# [PROGRESS] Processing Organisation: 1
# [PROGRESS] Processing Department: 3
# [PROGRESS] Processing TeamMember: 6
# [PROGRESS] Processing Project: 2
# [PROGRESS] Processing Milestone: 4
# [PROGRESS] Processing Task: 7
# [PROGRESS] Processing Comment: 3
#
# [INFO] Created JSON elements:
#   - Root object: 1
#   - Nested objects: 25
#   - Arrays: 18
#   - Properties: 142
#
# [INFO] Transformation completed in 0.23 seconds
# [INFO] Output saved to: project-data.json

# Validate the JSON output against schema
swift-json validate project-data.json \
    --schema project-schema.json

# Output:
# Validation successful. JSON conforms to schema.

# Pretty-print a sample of the output
swift-json query project-data.json \
    --path '$.projects[0]' \
    --format pretty

# Output:
# {
#   "id": "PROJ-001",
#   "name": "Customer Portal Redesign",
#   "description": "Modernise the customer-facing portal...",
#   "status": "ACTIVE",
#   "startDate": "2024-01-01",
#   "targetEndDate": "2024-06-30",
#   "budget": 250000.0,
#   "ownerId": "MEMBER-001",
#   "departmentId": "DEPT-ENG",
#   "teamMemberIds": ["MEMBER-001", "MEMBER-002", "MEMBER-003", "MEMBER-004"],
#   "milestones": [...],
#   "tasks": [...]
# }

# Generate statistics
echo "Conversion Statistics:"
swift-json stats project-data.json

# Output:
# Total objects: 26
# Total arrays: 18
# Total properties: 142
# File size: 12.4 KB (vs 18.2 KB XMI = 32% reduction)
