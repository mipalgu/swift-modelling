# Deploy and test the complete cross-format integration system
# Final step of the Cross-Format Integration tutorial

echo "========================================"
echo "Cross-Format Integration Deployment"
echo "========================================"
echo ""

# Step 1: Generate all code artefacts
echo "=== Step 1: Generate Code Artefacts ==="

# Generate REST API server
swift-mtl generate GenerateRestAPI.mtl \
    --metamodel ProjectManagement.ecore \
    --output ./Server/

# Output:
# [GENERATED] openapi.yaml
# [GENERATED] routes.swift
# [GENERATED] DTOs.swift

# Generate Swift API client
swift-mtl generate GenerateSwiftAPI.mtl \
    --metamodel ProjectManagement.ecore \
    --output ./Client/

# Output:
# [GENERATED] ProjectManagementAPI.swift
# [GENERATED] APIProtocols.swift
# [GENERATED] APIExtensions.swift

# Generate event API
swift-mtl generate GenerateEventAPI.mtl \
    --metamodel ProjectManagement.ecore \
    --output ./Events/

# Output:
# [GENERATED] Events.swift
# [GENERATED] WebSocketClient.swift
# [GENERATED] RealTimeSyncManager.swift

echo ""
echo "=== Step 2: Build Server ==="

# Build server application
cd ./Server
swift build --configuration release

# Output:
# Building for production...
# Build complete!

echo ""
echo "=== Step 3: Deploy to Staging ==="

# Deploy to staging environment
deploy-tool deploy \
    --environment staging \
    --app project-management-api \
    --version 1.0.0

# Output:
# [DEPLOY] Uploading artefacts to staging...
# [DEPLOY] Configuring environment variables...
# [DEPLOY] Starting application...
# [DEPLOY] Health check: PASSED
# [DEPLOY] Deployment complete: https://api-staging.acme.com.au/v1

echo ""
echo "=== Step 4: Run Integration Tests ==="

# Test XMI -> JSON conversion
echo "Testing XMI to JSON conversion..."
swift-integration-test \
    --scenario xmi-to-json \
    --input test-data/sample-project.xmi \
    --expected test-data/expected-project.json

# Output:
# [TEST] Loading XMI: test-data/sample-project.xmi
# [TEST] Converting to JSON...
# [TEST] Comparing with expected output...
# [TEST] PASSED: XMI to JSON conversion

# Test JSON -> XMI conversion
echo "Testing JSON to XMI conversion..."
swift-integration-test \
    --scenario json-to-xmi \
    --input test-data/sample-project.json \
    --expected test-data/expected-project.xmi

# Output:
# [TEST] Loading JSON: test-data/sample-project.json
# [TEST] Converting to XMI...
# [TEST] Comparing with expected output...
# [TEST] PASSED: JSON to XMI conversion

# Test roundtrip integrity
echo "Testing roundtrip integrity..."
swift-integration-test \
    --scenario roundtrip \
    --input test-data/sample-project.xmi \
    --format-chain "xmi,json,swift,json,xmi"

# Output:
# [TEST] Starting roundtrip test...
# [TEST] XMI -> JSON: OK
# [TEST] JSON -> Swift: OK
# [TEST] Swift -> JSON: OK
# [TEST] JSON -> XMI: OK
# [TEST] Comparing original and result...
# [TEST] PASSED: Roundtrip integrity maintained

# Test synchronisation
echo "Testing bidirectional synchronisation..."
swift-integration-test \
    --scenario sync \
    --base test-data/base-model.xmi \
    --changes-xmi test-data/xmi-changes.json \
    --changes-json test-data/json-changes.json

# Output:
# [TEST] Loading base model...
# [TEST] Applying XMI changes...
# [TEST] Applying JSON changes...
# [TEST] Detecting conflicts...
# [TEST] Resolving conflicts...
# [TEST] Verifying merged model...
# [TEST] PASSED: Bidirectional synchronisation

# Test real-time events
echo "Testing real-time event streaming..."
swift-integration-test \
    --scenario realtime \
    --clients 3 \
    --duration 10s

# Output:
# [TEST] Spawning 3 test clients...
# [TEST] Client 1: Connected
# [TEST] Client 2: Connected
# [TEST] Client 3: Connected
# [TEST] Client 1: Creating element...
# [TEST] Client 2: Received create event
# [TEST] Client 3: Received create event
# [TEST] Client 2: Updating element...
# [TEST] Client 1: Received update event
# [TEST] Client 3: Received update event
# [TEST] Event propagation time: avg 45ms
# [TEST] PASSED: Real-time event streaming

echo ""
echo "=== Step 5: Performance Benchmarks ==="

swift-benchmark \
    --scenarios all \
    --iterations 100

# Output:
# Benchmark Results:
# +--------------------------+----------+----------+----------+
# | Scenario                 | Min      | Avg      | Max      |
# +--------------------------+----------+----------+----------+
# | XMI Parse (1000 elems)   | 12ms     | 15ms     | 22ms     |
# | JSON Parse (1000 elems)  | 8ms      | 10ms     | 14ms     |
# | XMI to JSON Transform    | 25ms     | 32ms     | 48ms     |
# | JSON to XMI Transform    | 28ms     | 35ms     | 52ms     |
# | Conflict Detection       | 5ms      | 8ms      | 12ms     |
# | Conflict Resolution      | 10ms     | 15ms     | 25ms     |
# | Full Sync Cycle          | 85ms     | 110ms    | 145ms    |
# | WebSocket Event          | 2ms      | 5ms      | 10ms     |
# +--------------------------+----------+----------+----------+
# All benchmarks within acceptable limits.

echo ""
echo "=== Step 6: Deploy to Production ==="

# Confirm deployment
read -p "Deploy to production? (y/n) " confirm
if [ "$confirm" = "y" ]; then
    deploy-tool deploy \
        --environment production \
        --app project-management-api \
        --version 1.0.0 \
        --rollback-on-failure

    # Output:
    # [DEPLOY] Creating production backup...
    # [DEPLOY] Uploading artefacts to production...
    # [DEPLOY] Configuring environment variables...
    # [DEPLOY] Starting blue-green deployment...
    # [DEPLOY] Routing traffic to new version...
    # [DEPLOY] Health check: PASSED
    # [DEPLOY] Deployment complete: https://api.acme.com.au/v1
fi

echo ""
echo "========================================"
echo "Deployment Summary"
echo "========================================"
echo ""
echo "Environments:"
echo "  - Staging: https://api-staging.acme.com.au/v1"
echo "  - Production: https://api.acme.com.au/v1"
echo ""
echo "API Documentation:"
echo "  - OpenAPI Spec: https://api.acme.com.au/v1/docs/openapi.yaml"
echo "  - Interactive Docs: https://api.acme.com.au/v1/docs"
echo ""
echo "WebSocket Endpoints:"
echo "  - Staging: wss://api-staging.acme.com.au/v1/events"
echo "  - Production: wss://api.acme.com.au/v1/events"
echo ""
echo "Generated Client Libraries:"
echo "  - Swift Package: ./Client/ProjectManagementAPI.swift"
echo "  - Event Types: ./Events/Events.swift"
echo "  - Sync Manager: ./Events/RealTimeSyncManager.swift"
echo ""
echo "Integration Test Results: ALL PASSED"
echo "Performance Benchmarks: WITHIN LIMITS"
echo ""
echo "Cross-Format Integration deployment complete!"
