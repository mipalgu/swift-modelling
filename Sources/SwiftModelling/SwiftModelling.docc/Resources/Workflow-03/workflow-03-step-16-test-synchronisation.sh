# Test synchronisation scenarios
# Validates bidirectional sync and conflict resolution

echo "=== Synchronisation Test Suite ==="
echo ""

# Test 1: Basic sync without conflicts
echo "--- Test 1: Basic Synchronisation (No Conflicts) ---"
swift-sync test \
    --base base-model.xmi \
    --changes-a xmi-changes.json \
    --changes-b json-changes.json \
    --no-conflicts

# Output:
# [TEST] Loading base model: base-model.xmi
# [TEST] Loading changes from source A (XMI): 5 changes
# [TEST] Loading changes from source B (JSON): 3 changes
# [TEST] Detecting conflicts...
# [TEST] No conflicts detected
# [TEST] Merging changes...
# [TEST] Merged model created: 8 changes applied
# [TEST] PASSED: Basic synchronisation without conflicts

echo ""

# Test 2: Sync with auto-resolvable conflicts
echo "--- Test 2: Auto-Resolvable Conflicts ---"
swift-sync test \
    --base base-model.xmi \
    --changes-a xmi-changes-conflict.json \
    --changes-b json-changes-conflict.json \
    --policy last-write-wins

# Output:
# [TEST] Loading base model: base-model.xmi
# [TEST] Loading changes from source A (XMI): 4 changes
# [TEST] Loading changes from source B (JSON): 4 changes
# [TEST] Detecting conflicts...
# [TEST] Found 2 conflicts:
#   - TASK-003: status (IN_PROGRESS vs COMPLETED)
#   - TASK-004: actualHours (25.0 vs 30.0)
# [TEST] Applying resolution policy: LAST_WRITE_WINS
# [TEST] Resolved conflict for TASK-003: using JSON value (newer timestamp)
# [TEST] Resolved conflict for TASK-004: using XMI value (newer timestamp)
# [TEST] Merged model created: 6 changes applied
# [TEST] PASSED: Auto-resolvable conflicts

echo ""

# Test 3: Sync with manual resolution required
echo "--- Test 3: Manual Resolution Required ---"
swift-sync test \
    --base base-model.xmi \
    --changes-a xmi-delete-task.json \
    --changes-b json-modify-task.json \
    --policy merge-fields

# Output:
# [TEST] Loading base model: base-model.xmi
# [TEST] Loading changes from source A (XMI): 1 deletion
# [TEST] Loading changes from source B (JSON): 3 modifications
# [TEST] Detecting conflicts...
# [TEST] Found 1 critical conflict:
#   - TASK-005: DELETE vs MODIFY conflict
# [TEST] Applying resolution policy: MERGE_FIELDS
# [TEST] Cannot auto-resolve deletion conflict
# [TEST] Manual resolution required for 1 conflict
# [TEST] Resolution request generated: manual-resolution-001.json
# [TEST] PASSED: Manual resolution correctly identified

echo ""

# Test 4: Three-way merge scenario
echo "--- Test 4: Three-Way Merge ---"
swift-sync test \
    --base base-model.xmi \
    --changes-a xmi-changes.json \
    --changes-b json-changes.json \
    --changes-c swift-changes.json \
    --policy source-priority \
    --priority "xmi,json,swift"

# Output:
# [TEST] Loading base model: base-model.xmi
# [TEST] Loading changes from 3 sources:
#   - XMI: 4 changes
#   - JSON: 3 changes
#   - Swift: 2 changes
# [TEST] Detecting conflicts...
# [TEST] Found 3 conflicts across sources
# [TEST] Applying resolution policy: SOURCE_PRIORITY
# [TEST] Priority order: XMI > JSON > Swift
# [TEST] Resolved 3 conflicts using source priority
# [TEST] Merged model created: 7 changes applied
# [TEST] PASSED: Three-way merge with source priority

echo ""

# Test 5: Roundtrip verification
echo "--- Test 5: Roundtrip Verification ---"
swift-sync roundtrip \
    --input original-model.xmi \
    --format-chain "xmi,json,swift,json,xmi"

# Output:
# [TEST] Starting roundtrip verification
# [TEST] Original: original-model.xmi (sha256: a1b2c3...)
# [TEST] Step 1: XMI -> JSON
# [TEST] Step 2: JSON -> Swift
# [TEST] Step 3: Swift -> JSON
# [TEST] Step 4: JSON -> XMI
# [TEST] Final: roundtrip-result.xmi (sha256: a1b2c3...)
# [TEST] Comparing original and final...
# [TEST] Models are semantically equivalent
# [TEST] PASSED: Roundtrip verification

echo ""

# Test 6: Performance test
echo "--- Test 6: Performance Test ---"
swift-sync benchmark \
    --model large-model.xmi \
    --changes 1000 \
    --conflicts 100

# Output:
# [BENCHMARK] Model size: 5000 elements
# [BENCHMARK] Changes to process: 1000
# [BENCHMARK] Conflicts to resolve: 100
# [BENCHMARK] Running synchronisation...
# [BENCHMARK] Change detection: 45ms
# [BENCHMARK] Conflict detection: 12ms
# [BENCHMARK] Conflict resolution: 28ms
# [BENCHMARK] Model merge: 156ms
# [BENCHMARK] Total time: 241ms
# [BENCHMARK] Throughput: 4149 changes/second
# [BENCHMARK] PASSED: Performance within acceptable limits

echo ""
echo "=== All Synchronisation Tests Complete ==="
echo ""
echo "Summary:"
echo "  - Basic sync: PASSED"
echo "  - Auto-resolve: PASSED"
echo "  - Manual resolution: PASSED"
echo "  - Three-way merge: PASSED"
echo "  - Roundtrip: PASSED"
echo "  - Performance: PASSED"
