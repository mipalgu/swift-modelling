# Deploy migrated model to production
# Execute with caution after staging validation

# Verify staging tests passed
if ! swift-atl test verify --environment staging; then
    echo "ERROR: Staging tests not passed. Aborting production deployment."
    exit 1
fi

# Set production environment
PROD_ENV="production"
DEPLOYMENT_ID="deploy_$(date +%Y%m%d_%H%M%S)"
ROLLBACK_BACKUP="backups/production_${DEPLOYMENT_ID}"

# Create production backup before deployment
echo "Creating pre-deployment backup..."
mkdir -p "${ROLLBACK_BACKUP}"

swift-ecore export \
    --environment ${PROD_ENV} \
    --output "${ROLLBACK_BACKUP}/current-production.xmi"

# Output:
# [INFO] Exporting current production model...
# [INFO] Backup saved to: backups/production_deploy_20240120_150000/current-production.xmi

# Deploy metamodel to production
echo "Deploying metamodel v2.0 to production..."
swift-ecore deploy orders-v2.ecore \
    --environment ${PROD_ENV} \
    --register-nsuri \
    --atomic

# Output:
# [INFO] Deploying metamodel to production...
# [INFO] Registered nsURI: http://www.example.org/orders/2.0
# [INFO] Metamodel deployed successfully

# Deploy migrated model with atomic transaction
echo "Deploying migrated model to production..."
swift-ecore deploy migrated-orders-data.xmi \
    --environment ${PROD_ENV} \
    --metamodel orders-v2.ecore \
    --atomic \
    --on-error rollback

# Output:
# [INFO] Starting atomic deployment...
# [INFO] Validating model against metamodel...
# [INFO] Deploying model to production...
# [INFO] Deployment completed successfully
# [INFO] Deployment ID: deploy_20240120_150000

# Verify production health
echo "Verifying production health..."
swift-ecore health-check \
    --environment ${PROD_ENV} \
    --timeout 30

# Output:
# Health Check Results
# ====================
# Metamodel registration: ✓
# Model loading: ✓
# Reference resolution: ✓
# Query performance: ✓ (avg 8ms)
#
# Status: HEALTHY

# Log deployment event
swift-ecore audit-log \
    --event "PRODUCTION_DEPLOYMENT" \
    --deployment-id "${DEPLOYMENT_ID}" \
    --metamodel "Orders v2.0" \
    --model "migrated-orders-data.xmi"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  PRODUCTION DEPLOYMENT SUCCESSFUL"
echo "═══════════════════════════════════════════════════════"
echo "  Deployment ID: ${DEPLOYMENT_ID}"
echo "  Rollback backup: ${ROLLBACK_BACKUP}"
echo "  Rollback command: ./rollback.sh ${ROLLBACK_BACKUP}"
echo "═══════════════════════════════════════════════════════"
