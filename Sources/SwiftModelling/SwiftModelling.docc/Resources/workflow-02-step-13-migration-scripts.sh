#!/bin/bash
# Migration orchestration script for batch instance migration
# Handles multiple instance files with progress tracking and error handling

set -e

# Configuration
SOURCE_DIR="${1:-./legacy-data}"
TARGET_DIR="${2:-./migrated-data}"
LOG_DIR="./migration-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/migration_${TIMESTAMP}.log"

# Metamodel paths
LEGACY_METAMODEL="./metamodels/LegacyCustomer.ecore"
IMPROVED_METAMODEL="./metamodels/ImprovedCustomer.ecore"

# Transformation paths
MIGRATION_ATL="./transforms/LegacyCustomer2CustomerManagement.atl"
QUALITY_ATL="./transforms/CustomerQualityImprovements.atl"
VALIDATION_ATL="./transforms/CustomerMigrationValidation.atl"

# Counters
TOTAL_FILES=0
SUCCESS_COUNT=0
FAILURE_COUNT=0
SKIPPED_COUNT=0

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

# Create directories
mkdir -p "${TARGET_DIR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${TARGET_DIR}/backup"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Error handler
handle_error() {
    local file="$1"
    local error="$2"
    log "ERROR: Failed to migrate ${file}: ${error}"
    echo "${file}" >> "${LOG_DIR}/failed_files_${TIMESTAMP}.txt"
    ((FAILURE_COUNT++))
}

# Migrate single file
migrate_file() {
    local source_file="$1"
    local filename=$(basename "${source_file}")
    local target_file="${TARGET_DIR}/${filename%.xmi}-migrated.xmi"
    local temp_file="${TARGET_DIR}/.temp_${filename}"

    log "Processing: ${filename}"

    # Step 1: Run core migration
    if ! swift-atl transform "${MIGRATION_ATL}" \
        --source "${source_file}" \
        --source-metamodel "${LEGACY_METAMODEL}" \
        --target "${temp_file}" \
        --target-metamodel "${IMPROVED_METAMODEL}" \
        --quiet 2>> "${LOG_FILE}"; then
        handle_error "${filename}" "Migration transformation failed"
        return 1
    fi

    # Step 2: Apply quality improvements
    if ! swift-atl transform "${QUALITY_ATL}" \
        --source "${temp_file}" \
        --metamodel "${IMPROVED_METAMODEL}" \
        --target "${target_file}" \
        --refining \
        --quiet 2>> "${LOG_FILE}"; then
        handle_error "${filename}" "Quality improvement failed"
        rm -f "${temp_file}"
        return 1
    fi

    # Clean up temp file
    rm -f "${temp_file}"

    # Step 3: Validate result
    if ! swift-atl transform "${VALIDATION_ATL}" \
        --source "${target_file}" \
        --metamodel "${IMPROVED_METAMODEL}" \
        --validate-only \
        --quiet 2>> "${LOG_FILE}"; then
        log "WARNING: Validation issues in ${filename}"
        echo "${filename}" >> "${LOG_DIR}/validation_warnings_${TIMESTAMP}.txt"
    fi

    log "SUCCESS: ${filename} -> ${target_file}"
    ((SUCCESS_COUNT++))
    return 0
}

# Main execution
echo "=============================================="
echo "  Batch Migration Orchestration"
echo "=============================================="
echo ""
echo "Source directory: ${SOURCE_DIR}"
echo "Target directory: ${TARGET_DIR}"
echo "Log file: ${LOG_FILE}"
echo ""

log "Starting batch migration"
log "Configuration:"
log "  Source: ${SOURCE_DIR}"
log "  Target: ${TARGET_DIR}"
log "  Legacy metamodel: ${LEGACY_METAMODEL}"
log "  Improved metamodel: ${IMPROVED_METAMODEL}"

# Validate prerequisites
if [ ! -d "${SOURCE_DIR}" ]; then
    echo -e "${RED}ERROR: Source directory not found: ${SOURCE_DIR}${NC}"
    exit 1
fi

if [ ! -f "${LEGACY_METAMODEL}" ]; then
    echo -e "${RED}ERROR: Legacy metamodel not found: ${LEGACY_METAMODEL}${NC}"
    exit 1
fi

if [ ! -f "${IMPROVED_METAMODEL}" ]; then
    echo -e "${RED}ERROR: Improved metamodel not found: ${IMPROVED_METAMODEL}${NC}"
    exit 1
fi

# Count files
TOTAL_FILES=$(find "${SOURCE_DIR}" -name "*.xmi" -type f | wc -l | tr -d ' ')
log "Found ${TOTAL_FILES} XMI files to migrate"

if [ "${TOTAL_FILES}" -eq 0 ]; then
    echo -e "${YELLOW}No XMI files found in ${SOURCE_DIR}${NC}"
    exit 0
fi

# Process each file
CURRENT=0
for source_file in "${SOURCE_DIR}"/*.xmi; do
    if [ -f "${source_file}" ]; then
        ((CURRENT++))
        echo -ne "\rProgress: ${CURRENT}/${TOTAL_FILES} "

        # Check if already migrated
        filename=$(basename "${source_file}")
        target_file="${TARGET_DIR}/${filename%.xmi}-migrated.xmi"
        if [ -f "${target_file}" ]; then
            log "SKIPPED: ${filename} (already migrated)"
            ((SKIPPED_COUNT++))
            continue
        fi

        # Migrate the file
        migrate_file "${source_file}" || true
    fi
done

echo ""
echo ""
echo "=============================================="
echo "  Migration Complete"
echo "=============================================="
echo ""
echo -e "Total files:   ${TOTAL_FILES}"
echo -e "${GREEN}Successful:    ${SUCCESS_COUNT}${NC}"
echo -e "${YELLOW}Skipped:       ${SKIPPED_COUNT}${NC}"
echo -e "${RED}Failed:        ${FAILURE_COUNT}${NC}"
echo ""
echo "Log file: ${LOG_FILE}"

if [ "${FAILURE_COUNT}" -gt 0 ]; then
    echo -e "${RED}Failed files listed in: ${LOG_DIR}/failed_files_${TIMESTAMP}.txt${NC}"
fi

log "Migration completed. Success: ${SUCCESS_COUNT}, Failed: ${FAILURE_COUNT}, Skipped: ${SKIPPED_COUNT}"

# Exit with error if any failures
if [ "${FAILURE_COUNT}" -gt 0 ]; then
    exit 1
fi
