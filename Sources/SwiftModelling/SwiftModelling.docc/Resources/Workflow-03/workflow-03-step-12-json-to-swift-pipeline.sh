# Complete JSON to Swift pipeline
# Takes JSON input, validates, and generates type-safe Swift code

# Step 1: Validate JSON against schema
echo "=== Step 1: Validating JSON ==="
swift-json validate updated-project-data.json \
    --schema project-schema.json \
    --verbose

# Output:
# [INFO] Loading schema: project-schema.json
# [INFO] Validating: updated-project-data.json
# [INFO] Validation successful
# [INFO] Objects validated: 35
# [INFO] Arrays validated: 22
# [INFO] Properties validated: 186

# Step 2: Convert JSON to XMI for metamodel validation
echo ""
echo "=== Step 2: Converting JSON to XMI ==="
swift-atl transform JSON2XMI.atl \
    --source updated-project-data.json \
    --source-metamodel JsonModel.ecore \
    --target updated-project-data.xmi \
    --target-metamodel ProjectManagement.ecore \
    --verbose

# Output:
# [INFO] Loading source metamodel: JsonModel.ecore
# [INFO] Loading target metamodel: ProjectManagement.ecore
# [INFO] Compiling transformation: JSON2XMI.atl
# [INFO] Executing transformation...
# [PROGRESS] Processing root Organisation
# [PROGRESS] Creating 3 departments
# [PROGRESS] Creating 7 team members (1 new)
# [PROGRESS] Creating 2 projects
# [PROGRESS] Creating 5 milestones
# [PROGRESS] Creating 9 tasks (2 new)
# [PROGRESS] Creating 8 comments
# [INFO] Resolving cross-references...
# [INFO] Transformation completed in 0.31 seconds

# Step 3: Validate XMI against metamodel
echo ""
echo "=== Step 3: Validating XMI ==="
swift-ecore validate updated-project-data.xmi \
    --metamodel ProjectManagement.ecore

# Output:
# Validation successful. Model conforms to ProjectManagement metamodel.
# Elements: 35, References resolved: 48

# Step 4: Generate Swift code from metamodel
echo ""
echo "=== Step 4: Generating Swift Code ==="
swift-mtl generate GenerateSwiftModels.mtl \
    --metamodel ProjectManagement.ecore \
    --output ./Generated/

# Output:
# [INFO] Loading template: GenerateSwiftModels.mtl
# [INFO] Loading metamodel: ProjectManagement.ecore
# [INFO] Generating Swift code...
# [GENERATED] ProjectStatus.swift
# [GENERATED] TaskPriority.swift
# [GENERATED] TaskStatus.swift
# [GENERATED] Organisation.swift
# [GENERATED] Department.swift
# [GENERATED] TeamMember.swift
# [GENERATED] Project.swift
# [GENERATED] Milestone.swift
# [GENERATED] Task.swift
# [GENERATED] Comment.swift
# [GENERATED] ProjectManagementModels.swift
# [INFO] Generated 11 Swift files in ./Generated/

# Step 5: Compile and validate generated Swift
echo ""
echo "=== Step 5: Compiling Swift Code ==="
swiftc -parse ./Generated/*.swift

# Output:
# (no output means successful compilation)

# Step 6: Test loading JSON into generated types
echo ""
echo "=== Step 6: Testing Model Loading ==="
swift test-model-loading.swift \
    --json updated-project-data.json \
    --types ./Generated/

# Output:
# [TEST] Loading organisation from JSON...
# [TEST] Organisation loaded: Acme Software Solutions
# [TEST] Departments: 3
# [TEST] Members: 7
# [TEST] Projects: 2
# [TEST] All references resolved successfully
# [TEST] Model loading test PASSED

echo ""
echo "=== Pipeline Complete ==="
echo "Generated Swift files are ready in ./Generated/"
echo "Use 'import ProjectManagementModels' in your Swift project"
