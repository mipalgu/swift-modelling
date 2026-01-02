# Deploy migrated model to staging environment
# Validates deployment before production

# Set environment variables
STAGING_ENV="staging"
MODEL_VERSION="2.0"

# Deploy metamodel first
swift-ecore deploy orders-v2.ecore \
    --environment ${STAGING_ENV} \
    --register-nsuri

# Output:
# [INFO] Deploying metamodel to staging...
# [INFO] Registered nsURI: http://www.example.org/orders/2.0
# [INFO] Metamodel deployed successfully

# Deploy migrated model data
swift-ecore deploy migrated-orders-data.xmi \
    --environment ${STAGING_ENV} \
    --metamodel orders-v2.ecore

# Output:
# [INFO] Validating model against metamodel...
# [INFO] Deploying model to staging...
# [INFO] Model deployed successfully
# [INFO] Deployment ID: deploy_20240120_143500

# Run staging environment tests
swift-atl test run staging-tests.atl \
    --environment ${STAGING_ENV}

# Output:
# Running Staging Environment Tests
# =================================
#
# Test: Model loads correctly
#   Status: PASSED ✓
#
# Test: All references resolve
#   Status: PASSED ✓
#
# Test: Query performance acceptable
#   Avg query time: 12ms (threshold: 100ms)
#   Status: PASSED ✓
#
# Test: CRUD operations work
#   Create customer: PASSED ✓
#   Read order: PASSED ✓
#   Update product: PASSED ✓
#   Delete test data: PASSED ✓
#
# Test: Backward compatibility endpoint
#   Legacy format export: PASSED ✓
#   Legacy API compatibility: PASSED ✓
#
# ══════════════════════════════════════════
# Staging Tests: 6 passed, 0 failed
# ══════════════════════════════════════════

# Verify staging deployment health
curl -s http://staging.example.com/api/health | jq .

# Output:
# {
#   "status": "healthy",
#   "metamodel": {
#     "name": "Orders",
#     "version": "2.0",
#     "nsURI": "http://www.example.org/orders/2.0"
#   },
#   "model": {
#     "elementCount": 44,
#     "lastUpdated": "2024-01-20T14:35:00+11:00"
#   }
# }

echo "Staging deployment successful"
echo "Review at: https://staging.example.com/models/orders"
