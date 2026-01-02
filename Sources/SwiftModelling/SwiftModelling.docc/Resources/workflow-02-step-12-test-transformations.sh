# Test the migration transformations with sample data
# Verifies transformations produce correct results

# Create test output directory
mkdir -p test-output

echo "=============================================="
echo "  Testing Migration Transformations"
echo "=============================================="

# Step 1: Run the core migration transformation
echo ""
echo "Step 1: Testing core migration transformation..."
swift-atl transform LegacyCustomer2CustomerManagement.atl \
    --source legacy-customer-data.xmi \
    --source-metamodel LegacyCustomer.ecore \
    --target test-output/migrated-customers.xmi \
    --target-metamodel ImprovedCustomer.ecore \
    --verbose

# Output:
# [INFO] Loading source metamodel: LegacyCustomer.ecore
# [INFO] Loading target metamodel: ImprovedCustomer.ecore
# [INFO] Loading source model: legacy-customer-data.xmi
# [INFO] Compiling transformation: LegacyCustomer2CustomerManagement.atl
# [INFO] Executing transformation...
#
# [PROGRESS] Processing CustomerDatabase: 1
# [PROGRESS] Processing Customer elements: 25
# [PROGRESS] Creating Organisation elements: 18 (deduplicated)
# [PROGRESS] Creating Contact elements: 25
# [PROGRESS] Creating Address elements: 50
#
# [INFO] Transformation completed in 0.62 seconds
# [INFO] Output saved to: test-output/migrated-customers.xmi

# Step 2: Validate the migrated model structure
echo ""
echo "Step 2: Validating migrated model structure..."
swift-ecore validate test-output/migrated-customers.xmi \
    --metamodel ImprovedCustomer.ecore

# Output:
# Validation Results:
#   [OK] Model conforms to CustomerManagement metamodel
#   [OK] All references resolved
#   [OK] All containment constraints satisfied
#   [OK] All multiplicity constraints satisfied

# Step 3: Run data quality improvements
echo ""
echo "Step 3: Applying data quality improvements..."
swift-atl transform CustomerQualityImprovements.atl \
    --source test-output/migrated-customers.xmi \
    --metamodel ImprovedCustomer.ecore \
    --target test-output/improved-customers.xmi \
    --refining \
    --verbose

# Output:
# [INFO] Running in refining mode
# [INFO] Applying quality improvements...
#
# [PROGRESS] Improving Contact elements: 25
# [PROGRESS] Improving Organisation elements: 18
# [PROGRESS] Improving Address elements: 50
# [PROGRESS] Improving Customer elements: 25
#
# Improvements Applied:
#   Phone numbers standardised: 22
#   ABNs formatted: 18
#   Emails normalised: 25
#   States standardised: 47
#   Postcodes corrected: 3
#
# [INFO] Quality improvements completed

# Step 4: Run validation transformation
echo ""
echo "Step 4: Running validation checks..."
swift-atl transform CustomerMigrationValidation.atl \
    --source test-output/improved-customers.xmi \
    --metamodel ImprovedCustomer.ecore \
    --validate-only

# Output:
# Migration Validation Report
# ===========================
#
# ## Structural Validation
#   Customers without organisation: 0
#   Orphaned contacts: 0
#   Customers without primary contact: 0
#   Customers without billing address: 0
#
# ## Data Integrity
#   Duplicate ABNs: 0
#   Duplicate customer IDs: 0
#   Duplicate contact emails: 0
#
# ## Business Rules
#   Invalid credit limits: 0
#   Invalid payment terms: 0
#   Invalid discounts: 0
#   Incomplete organisations: 0
#
# ## Address Validation
#   Invalid postcodes: 0
#   Invalid states: 0
#   Incomplete addresses: 0
#
# ## Contact Validation
#   Invalid emails: 0
#   Unnamed contacts: 0
#
# ## Cross-Reference Validation
#   Misaligned primary contacts: 0
#   Invalid category references: 0
#
# VALIDATION PASSED - No critical issues found

# Step 5: Compare element counts
echo ""
echo "Step 5: Comparing element counts..."
swift-ecore compare-counts \
    legacy-customer-data.xmi \
    test-output/improved-customers.xmi

# Output:
# Element Count Comparison
# ========================
#
# Source (Legacy):
#   CustomerDatabase: 1
#   Customer: 25
#   Total: 26
#
# Target (Improved):
#   CustomerManagementSystem: 1
#   Organisation: 18
#   Customer: 25
#   Contact: 25
#   Address: 50
#   CustomerNote: 12
#   CustomerCategory: 3
#   Total: 134
#
# Migration Summary:
#   Customers preserved: 25/25 (100%)
#   Organisations created: 18 (deduplicated from 25)
#   Data expanded: +108 elements (normalisation)

# Step 6: Verify round-trip capability
echo ""
echo "Step 6: Testing backwards compatibility..."
swift-atl transform ImprovedToLegacy.atl \
    --source test-output/improved-customers.xmi \
    --source-metamodel ImprovedCustomer.ecore \
    --target test-output/roundtrip-legacy.xmi \
    --target-metamodel LegacyCustomer.ecore

swift-ecore diff \
    legacy-customer-data.xmi \
    test-output/roundtrip-legacy.xmi \
    --ignore-timestamps

# Output:
# Difference Report
# =================
# Files are semantically equivalent
# (timestamps and formatting differences only)

echo ""
echo "=============================================="
echo "  All Transformation Tests PASSED"
echo "=============================================="
