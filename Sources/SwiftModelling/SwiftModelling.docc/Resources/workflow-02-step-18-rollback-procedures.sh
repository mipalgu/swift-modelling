#!/bin/bash
# Rollback procedures for model migration
# Restores legacy model state if issues are discovered

set -e

# Configuration
BACKUP_BASE_DIR="./backups"
PROD_DATA_DIR="./production-data"
LEGACY_METAMODEL="./metamodels/LegacyCustomer.ecore"
IMPROVED_METAMODEL="./metamodels/ImprovedCustomer.ecore"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
list_backups() {
    echo "Available backups:"
    echo ""
    ls -la "${BACKUP_BASE_DIR}" | grep "^d" | grep -v "^\." | awk '{print "  " $NF}'
    echo ""
}

verify_backup() {
    local backup_dir="$1"

    echo "Verifying backup integrity..."

    # Check manifest exists
    if [ ! -f "${backup_dir}/manifest.json" ]; then
        echo -e "${RED}ERROR: Manifest not found${NC}"
        return 1
    fi

    # Verify checksums
    swift-ecore verify-checksums "${backup_dir}" \
        --manifest "${backup_dir}/manifest.json"

    echo -e "${GREEN}Backup integrity verified${NC}"
}

rollback_to_backup() {
    local backup_dir="$1"

    echo ""
    echo "=============================================="
    echo "  INITIATING ROLLBACK"
    echo "=============================================="
    echo ""
    echo -e "${YELLOW}WARNING: This will restore production to legacy format${NC}"
    echo ""
    echo "Backup: ${backup_dir}"
    echo "Target: ${PROD_DATA_DIR}"
    echo ""

    # Confirm rollback
    read -p "Type 'ROLLBACK' to confirm: " confirm
    if [ "${confirm}" != "ROLLBACK" ]; then
        echo "Rollback cancelled."
        exit 0
    fi

    # Step 1: Create safety backup of current state
    echo ""
    echo "Step 1: Creating safety backup of current state..."
    SAFETY_BACKUP="${BACKUP_BASE_DIR}/pre-rollback-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${SAFETY_BACKUP}"
    cp -r "${PROD_DATA_DIR}"/* "${SAFETY_BACKUP}/"
    swift-ecore generate-manifest "${SAFETY_BACKUP}" \
        --output "${SAFETY_BACKUP}/manifest.json"
    echo "  Safety backup: ${SAFETY_BACKUP}"

    # Step 2: Verify source backup
    echo ""
    echo "Step 2: Verifying source backup..."
    verify_backup "${backup_dir}"

    # Step 3: Stop dependent services
    echo ""
    echo "Step 3: Stopping dependent services..."
    # swift-ecore service stop customer-api
    # swift-ecore service stop reporting-service
    echo "  Services stopped (simulated)"

    # Step 4: Restore legacy metamodel
    echo ""
    echo "Step 4: Restoring legacy metamodel..."
    swift-ecore deploy "${backup_dir}/LegacyCustomer.ecore" \
        --environment production \
        --register-nsuri \
        --atomic

    # Output:
    # [INFO] Deploying metamodel to production
    # [INFO] Registered nsURI: http://www.example.org/legacy/customer/1.0
    # [INFO] Metamodel deployed successfully

    # Step 5: Restore legacy data
    echo ""
    echo "Step 5: Restoring legacy model data..."
    rm -rf "${PROD_DATA_DIR:?}"/*
    cp -r "${backup_dir}"/*.xmi "${PROD_DATA_DIR}/"
    echo "  Data restored: $(ls -1 ${PROD_DATA_DIR}/*.xmi | wc -l) files"

    # Step 6: Validate restored data
    echo ""
    echo "Step 6: Validating restored data..."
    swift-ecore batch-validate "${PROD_DATA_DIR}" \
        --metamodel "${LEGACY_METAMODEL}"

    # Output:
    # Validating files...
    # [OK] All files valid

    # Step 7: Restart services with legacy configuration
    echo ""
    echo "Step 7: Restarting services with legacy configuration..."
    # swift-ecore service start customer-api --config legacy
    # swift-ecore service start reporting-service --config legacy
    echo "  Services restarted (simulated)"

    # Step 8: Run health checks
    echo ""
    echo "Step 8: Running health checks..."
    swift-ecore health-check \
        --environment production \
        --timeout 60

    # Output:
    # Health Check Results
    # ====================
    # Metamodel registration: OK
    # Model loading: OK
    # Reference resolution: OK
    # Query performance: OK
    #
    # Status: HEALTHY

    # Step 9: Log rollback event
    ROLLBACK_ID="rollback_$(date +%Y%m%d_%H%M%S)"
    swift-ecore audit-log \
        --event "PRODUCTION_ROLLBACK" \
        --rollback-id "${ROLLBACK_ID}" \
        --reason "Post-migration issue detected" \
        --backup-used "${backup_dir}"

    echo ""
    echo "=============================================="
    echo -e "  ${GREEN}ROLLBACK COMPLETED SUCCESSFULLY${NC}"
    echo "=============================================="
    echo ""
    echo "Rollback ID: ${ROLLBACK_ID}"
    echo "Restored to: Legacy Customer v1.0"
    echo "Backup used: ${backup_dir}"
    echo "Safety backup: ${SAFETY_BACKUP}"
    echo ""
    echo -e "${YELLOW}IMPORTANT:${NC}"
    echo "  1. Investigate root cause of the issue"
    echo "  2. Update migration transformations"
    echo "  3. Re-test before attempting migration again"
    echo "  4. Notify stakeholders of the rollback"
}

convert_back_to_legacy() {
    echo ""
    echo "Converting improved format back to legacy format..."
    echo ""

    # Use ATL transformation for conversion
    swift-atl batch-transform ImprovedToLegacy.atl \
        --source-dir "${PROD_DATA_DIR}" \
        --source-metamodel "${IMPROVED_METAMODEL}" \
        --target-dir "${PROD_DATA_DIR}-legacy" \
        --target-metamodel "${LEGACY_METAMODEL}" \
        --verbose

    # Output:
    # [INFO] Converting 25 files...
    # [PROGRESS] customers-batch-001-migrated.xmi -> customers-batch-001.xmi
    # [PROGRESS] customers-batch-002-migrated.xmi -> customers-batch-002.xmi
    # ...
    # [INFO] Conversion complete: 25/25 files

    # Validate converted files
    swift-ecore batch-validate "${PROD_DATA_DIR}-legacy" \
        --metamodel "${LEGACY_METAMODEL}"

    echo ""
    echo "Conversion complete. Legacy files in: ${PROD_DATA_DIR}-legacy"
}

# Main script
case "${1:-}" in
    list)
        list_backups
        ;;
    verify)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 verify <backup-directory>"
            exit 1
        fi
        verify_backup "$2"
        ;;
    rollback)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 rollback <backup-directory>"
            echo ""
            list_backups
            exit 1
        fi
        rollback_to_backup "$2"
        ;;
    convert)
        convert_back_to_legacy
        ;;
    *)
        echo "Model Migration Rollback Procedures"
        echo "===================================="
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  list              List available backups"
        echo "  verify <dir>      Verify backup integrity"
        echo "  rollback <dir>    Perform full rollback to backup"
        echo "  convert           Convert improved data to legacy format"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 verify ./backups/pre-migration-20240315_100000"
        echo "  $0 rollback ./backups/pre-migration-20240315_100000"
        echo ""
        ;;
esac
