# Execute the complete batch migration process
# Orchestrates migration, validation, and reporting

echo "=============================================="
echo "  Full Batch Migration Execution"
echo "=============================================="
echo ""

# Configuration
SOURCE_DIR="./legacy-data"
TARGET_DIR="./migrated-data"
BACKUP_DIR="./backups/pre-migration-$(date +%Y%m%d_%H%M%S)"

# Step 1: Create backup of source data
echo "Step 1: Creating backup of source data..."
mkdir -p "${BACKUP_DIR}"
cp -r "${SOURCE_DIR}"/* "${BACKUP_DIR}/"
echo "  Backup created: ${BACKUP_DIR}"

# Generate backup manifest
swift-ecore generate-manifest "${BACKUP_DIR}" \
    --output "${BACKUP_DIR}/manifest.json"

# Output:
# {
#   "backupId": "backup_20240315_100000",
#   "timestamp": "2024-03-15T10:00:00Z",
#   "sourceDirectory": "./legacy-data",
#   "fileCount": 25,
#   "totalSize": "2.5 MB",
#   "checksums": {
#     "customers-batch-001.xmi": "sha256:abc123...",
#     "customers-batch-002.xmi": "sha256:def456...",
#     ...
#   }
# }

echo "  Manifest generated"

# Step 2: Validate source data
echo ""
echo "Step 2: Validating source data..."
swift-ecore batch-validate "${SOURCE_DIR}" \
    --metamodel metamodels/LegacyCustomer.ecore \
    --report source-validation.json

# Output:
# Validating 25 files...
# [OK] customers-batch-001.xmi
# [OK] customers-batch-002.xmi
# ...
# Validation complete: 25/25 files valid

# Step 3: Run migration
echo ""
echo "Step 3: Running batch migration..."
./migrate-all-instances.sh "${SOURCE_DIR}" "${TARGET_DIR}"

# Output:
# ==============================================
#   Batch Migration Orchestration
# ==============================================
#
# Source directory: ./legacy-data
# Target directory: ./migrated-data
#
# Found 25 XMI files to migrate
# Progress: 25/25
#
# ==============================================
#   Migration Complete
# ==============================================
#
# Total files:   25
# Successful:    25
# Skipped:       0
# Failed:        0

# Step 4: Run validation pipeline
echo ""
echo "Step 4: Running validation pipeline..."
./validate-migration.sh "${TARGET_DIR}"

# Output:
# ==============================================
#   Migration Validation Pipeline
# ==============================================
#
# Validating files in: ./migrated-data
#
# Checking metamodel...
#   Metamodel: OK
#
# Validating migrated instances...
#   customers-batch-001-migrated.xmi: PASSED
#   customers-batch-002-migrated.xmi: PASSED
#   ...
#
# ==============================================
#   Validation Complete
# ==============================================
#
# Total files validated: 25
#   Passed:   25 (100%)
#   Warnings: 0 (0%)
#   Failed:   0 (0%)

# Step 5: Generate migration statistics
echo ""
echo "Step 5: Generating migration statistics..."
swift-ecore statistics "${TARGET_DIR}" \
    --metamodel metamodels/ImprovedCustomer.ecore \
    --format json \
    --output migration-statistics.json

# Output:
# Migration Statistics
# ====================
#
# Source Metrics:
#   Files processed: 25
#   Total legacy elements: 650
#
# Target Metrics:
#   Files created: 25
#   CustomerManagementSystem: 25
#   Organisation: 450 (deduplicated from 650)
#   Customer: 650
#   Contact: 650
#   Address: 1300
#   CustomerNote: 312
#   CustomerCategory: 3
#   Total elements: 3390
#
# Transformation Metrics:
#   Total processing time: 15.3 seconds
#   Average time per file: 0.61 seconds
#   Elements created per second: 221

# Step 6: Verify data integrity
echo ""
echo "Step 6: Verifying data integrity..."
swift-ecore reconcile \
    --source "${BACKUP_DIR}" \
    --source-metamodel metamodels/LegacyCustomer.ecore \
    --target "${TARGET_DIR}" \
    --target-metamodel metamodels/ImprovedCustomer.ecore \
    --report reconciliation-report.json

# Output:
# Data Reconciliation Report
# ==========================
#
# Source Records: 650 customers
# Target Records: 650 customers
# Match Rate: 100%
#
# Field Verification:
#   Customer IDs: 650/650 matched
#   Organisation ABNs: 450/450 matched
#   Email addresses: 650/650 matched
#   Phone numbers: 650/650 matched (after normalisation)
#
# Data Integrity: VERIFIED

echo ""
echo "=============================================="
echo "  Batch Migration Successfully Completed"
echo "=============================================="
echo ""
echo "Summary:"
echo "  Source files: 25"
echo "  Migrated files: 25"
echo "  Validation status: All passed"
echo "  Data integrity: Verified"
echo ""
echo "Output locations:"
echo "  Migrated data: ${TARGET_DIR}"
echo "  Backup: ${BACKUP_DIR}"
echo "  Reports: ./validation-reports/"
echo "  Statistics: ./migration-statistics.json"
