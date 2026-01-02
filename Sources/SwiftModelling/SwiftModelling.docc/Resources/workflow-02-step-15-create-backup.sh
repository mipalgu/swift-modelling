# Create backup before deployment
# Implements safety measures for rollback capability

# Create timestamped backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/migration_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

# Backup source models
cp legacy-orders-data.xmi "${BACKUP_DIR}/"
cp legacy-orders-v1.ecore "${BACKUP_DIR}/"

# Output:
# Created backup directory: backups/migration_20240120_143022
# Backed up: legacy-orders-data.xmi
# Backed up: legacy-orders-v1.ecore

# Create verification checksum
swift-ecore checksum legacy-orders-data.xmi > "${BACKUP_DIR}/source-checksum.sha256"
swift-ecore checksum migrated-orders-data.xmi > "${BACKUP_DIR}/target-checksum.sha256"

# Output:
# Generated checksums for verification

# Store transformation artifacts
cp LegacyOrders2Orders.atl "${BACKUP_DIR}/"
cp Orders2LegacyOrders.atl "${BACKUP_DIR}/"
cp orders-v2.ecore "${BACKUP_DIR}/"

# Create backup manifest
cat > "${BACKUP_DIR}/manifest.json" << 'EOF'
{
  "backupId": "migration_20240120_143022",
  "createdAt": "2024-01-20T14:30:22+11:00",
  "sourceMetamodel": {
    "name": "LegacyOrders",
    "version": "1.0",
    "nsURI": "http://www.example.org/legacy/orders/1.0"
  },
  "targetMetamodel": {
    "name": "Orders",
    "version": "2.0",
    "nsURI": "http://www.example.org/orders/2.0"
  },
  "sourceModel": "legacy-orders-data.xmi",
  "targetModel": "migrated-orders-data.xmi",
  "transformations": [
    "LegacyOrders2Orders.atl",
    "Orders2LegacyOrders.atl"
  ],
  "statistics": {
    "ordersCount": 4,
    "productsCount": 5,
    "customersCreated": 4
  }
}
EOF

# Output:
# Backup manifest created: backups/migration_20240120_143022/manifest.json

# Verify backup integrity
swift-ecore validate "${BACKUP_DIR}/legacy-orders-data.xmi" \
    --metamodel "${BACKUP_DIR}/legacy-orders-v1.ecore"

# Output:
# Backup validation: PASSED
# Source model can be restored from backup.

echo "Backup created successfully at: ${BACKUP_DIR}"
echo "Rollback command: ./rollback.sh ${BACKUP_DIR}"
