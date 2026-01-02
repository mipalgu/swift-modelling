#!/bin/bash
# Rollback procedure for model migration
# Usage: ./rollback.sh <backup-directory>

set -e

BACKUP_DIR="${1:-}"
PROD_ENV="production"

if [ -z "${BACKUP_DIR}" ]; then
    echo "Usage: ./rollback.sh <backup-directory>"
    echo ""
    echo "Available backups:"
    ls -la backups/ | grep "^d"
    exit 1
fi

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "ERROR: Backup directory not found: ${BACKUP_DIR}"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  INITIATING ROLLBACK"
echo "═══════════════════════════════════════════════════════"
echo "  Backup: ${BACKUP_DIR}"
echo "  Environment: ${PROD_ENV}"
echo "═══════════════════════════════════════════════════════"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# Load backup manifest
if [ -f "${BACKUP_DIR}/manifest.json" ]; then
    echo "Loading backup manifest..."
    SOURCE_METAMODEL=$(jq -r '.sourceMetamodel.nsURI' "${BACKUP_DIR}/manifest.json")
    SOURCE_MODEL=$(jq -r '.sourceModel' "${BACKUP_DIR}/manifest.json")
    echo "  Restoring to: ${SOURCE_METAMODEL}"
fi

# Step 1: Verify backup integrity
echo ""
echo "Step 1: Verifying backup integrity..."
swift-ecore verify-checksum \
    "${BACKUP_DIR}/${SOURCE_MODEL}" \
    "${BACKUP_DIR}/source-checksum.sha256"

# Output:
# Checksum verification: PASSED ✓

# Step 2: Deploy legacy metamodel
echo ""
echo "Step 2: Restoring legacy metamodel..."
swift-ecore deploy "${BACKUP_DIR}/legacy-orders-v1.ecore" \
    --environment ${PROD_ENV} \
    --register-nsuri \
    --atomic

# Output:
# [INFO] Deploying metamodel to production...
# [INFO] Registered nsURI: http://www.example.org/legacy/orders/1.0
# [INFO] Metamodel restored successfully

# Step 3: Restore legacy model data
echo ""
echo "Step 3: Restoring legacy model data..."
swift-ecore deploy "${BACKUP_DIR}/${SOURCE_MODEL}" \
    --environment ${PROD_ENV} \
    --metamodel "${BACKUP_DIR}/legacy-orders-v1.ecore" \
    --atomic

# Output:
# [INFO] Restoring model from backup...
# [INFO] Model restored successfully

# Step 4: Verify rollback
echo ""
echo "Step 4: Verifying rollback..."
swift-ecore health-check \
    --environment ${PROD_ENV} \
    --timeout 30

# Output:
# Health Check Results
# ====================
# Metamodel registration: ✓
# Model loading: ✓
# Reference resolution: ✓
# Query performance: ✓
#
# Status: HEALTHY

# Step 5: Log rollback event
ROLLBACK_ID="rollback_$(date +%Y%m%d_%H%M%S)"
swift-ecore audit-log \
    --event "PRODUCTION_ROLLBACK" \
    --rollback-id "${ROLLBACK_ID}" \
    --backup-used "${BACKUP_DIR}"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ROLLBACK COMPLETED SUCCESSFULLY"
echo "═══════════════════════════════════════════════════════"
echo "  Rollback ID: ${ROLLBACK_ID}"
echo "  Restored to: Legacy Orders v1.0"
echo "  Backup used: ${BACKUP_DIR}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "IMPORTANT: Investigate the cause of the rollback and"
echo "           update the migration before re-deploying."
