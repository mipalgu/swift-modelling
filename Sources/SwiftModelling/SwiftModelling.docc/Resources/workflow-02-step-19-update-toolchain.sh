#!/bin/bash
# Update dependent tools and processes for new metamodel
# Systematically updates all tools that depend on the model structure

set -e

# Configuration
NEW_METAMODEL="./metamodels/ImprovedCustomer.ecore"
TOOLS_DIR="./tools"
TEMPLATES_DIR="./templates"
SCRIPTS_DIR="./scripts"
CONFIG_DIR="./config"

echo "=============================================="
echo "  Updating Toolchain for New Metamodel"
echo "=============================================="
echo ""

# Step 1: Regenerate code from new metamodel
echo "Step 1: Regenerating code from metamodel..."
swift-ecore generate \
    --metamodel "${NEW_METAMODEL}" \
    --output "${TOOLS_DIR}/generated" \
    --language swift \
    --include-validators \
    --include-serializers

# Output:
# Generating Swift code from CustomerManagement.ecore
# ===================================================
# Generated files:
#   - CustomerManagement/Organisation.swift
#   - CustomerManagement/Customer.swift
#   - CustomerManagement/Contact.swift
#   - CustomerManagement/Address.swift
#   - CustomerManagement/CustomerCategory.swift
#   - CustomerManagement/CustomerNote.swift
#   - CustomerManagement/OrganisationType.swift
#   - CustomerManagement/CustomerStatus.swift
#   - CustomerManagement/ContactType.swift
#   - CustomerManagement/AddressType.swift
#   - CustomerManagement/Validators.swift
#   - CustomerManagement/XMISerializer.swift
#   - CustomerManagement/JSONSerializer.swift
#
# Generated 13 files in ./tools/generated/

echo "  Code generation complete"

# Step 2: Update MTL templates
echo ""
echo "Step 2: Updating MTL templates..."

# Update report templates
for template in "${TEMPLATES_DIR}"/*.mtl; do
    if [ -f "${template}" ]; then
        filename=$(basename "${template}")
        echo "  Updating: ${filename}"

        # Replace legacy class references
        sed -i.bak \
            -e 's/Legacy!Customer/Customer!Customer/g' \
            -e 's/\.companyName/.organisation.name/g' \
            -e 's/\.contactName/.primaryContact.name/g' \
            -e 's/\.contactEmail/.primaryContact.email/g' \
            -e 's/\.city/.suburb/g' \
            -e 's/\.abn/.organisation.australianBusinessNumber/g' \
            "${template}"
    fi
done

swift-mtl validate "${TEMPLATES_DIR}" \
    --metamodel "${NEW_METAMODEL}"

# Output:
# Validating MTL templates...
# [OK] customer-report.mtl
# [OK] invoice-template.mtl
# [OK] export-csv.mtl
# All templates valid

echo "  Templates updated"

# Step 3: Update ATL transformations
echo ""
echo "Step 3: Updating ATL transformations..."

# Recompile all transformations
for atl_file in "${TOOLS_DIR}"/transforms/*.atl; do
    if [ -f "${atl_file}" ]; then
        filename=$(basename "${atl_file}")
        echo "  Compiling: ${filename}"

        swift-atl compile "${atl_file}" \
            --metamodels "${CONFIG_DIR}/metamodels.json" \
            --output "${TOOLS_DIR}/transforms/compiled/"
    fi
done

# Output:
# Compiling ATL transformations...
# [OK] LegacyCustomer2CustomerManagement.atl
# [OK] CustomerQualityImprovements.atl
# [OK] CustomerMigrationValidation.atl
# [OK] ImprovedToLegacy.atl
# All transformations compiled

echo "  Transformations compiled"

# Step 4: Update configuration files
echo ""
echo "Step 4: Updating configuration files..."

# Update metamodel registry
cat > "${CONFIG_DIR}/metamodel-registry.json" << EOF
{
  "metamodels": {
    "CustomerManagement": {
      "version": "2.0",
      "nsURI": "http://www.example.org/customer/2.0",
      "file": "metamodels/ImprovedCustomer.ecore",
      "status": "active"
    },
    "LegacyCustomer": {
      "version": "1.0",
      "nsURI": "http://www.example.org/legacy/customer/1.0",
      "file": "metamodels/LegacyCustomer.ecore",
      "status": "deprecated",
      "deprecationDate": "2024-06-30"
    }
  },
  "defaultMetamodel": "CustomerManagement"
}
EOF
echo "  Metamodel registry updated"

# Update API configuration
cat > "${CONFIG_DIR}/api-config.json" << EOF
{
  "endpoints": {
    "customers": {
      "metamodel": "CustomerManagement",
      "rootClass": "CustomerManagementSystem",
      "supportedFormats": ["xmi", "json"]
    },
    "organisations": {
      "metamodel": "CustomerManagement",
      "rootClass": "Organisation",
      "supportedFormats": ["xmi", "json"]
    },
    "legacy": {
      "metamodel": "LegacyCustomer",
      "rootClass": "CustomerDatabase",
      "supportedFormats": ["xmi"],
      "deprecated": true,
      "sunset": "2024-06-30"
    }
  }
}
EOF
echo "  API configuration updated"

# Step 5: Update validation rules
echo ""
echo "Step 5: Updating validation rules..."

swift-ecore extract-constraints "${NEW_METAMODEL}" \
    --output "${CONFIG_DIR}/validation-rules.json"

# Output:
# Extracted validation rules:
# - Organisation.australianBusinessNumber: pattern [0-9 ]{11,14}
# - Customer.status: enum CustomerStatus
# - Contact.email: pattern email
# - Address.postcode: pattern [0-9]{4}
# - Address.state: enum ['NSW','VIC','QLD','SA','WA','TAS','NT','ACT']

echo "  Validation rules extracted"

# Step 6: Update query library
echo ""
echo "Step 6: Updating query library..."

# Generate standard queries for new structure
swift-ecore generate-queries "${NEW_METAMODEL}" \
    --output "${TOOLS_DIR}/queries/" \
    --include-navigation \
    --include-aggregation

# Output:
# Generated query library:
#   - navigation/get-customer-organisation.ocl
#   - navigation/get-organisation-customers.ocl
#   - navigation/get-customer-contacts.ocl
#   - aggregation/count-customers-by-status.ocl
#   - aggregation/sum-credit-limits.ocl
#   - aggregation/customers-by-category.ocl

echo "  Query library generated"

# Step 7: Update documentation
echo ""
echo "Step 7: Updating documentation..."

swift-ecore generate-docs "${NEW_METAMODEL}" \
    --output "./docs/metamodel/" \
    --format markdown \
    --include-diagrams

# Output:
# Generated documentation:
#   - docs/metamodel/index.md
#   - docs/metamodel/classes/Organisation.md
#   - docs/metamodel/classes/Customer.md
#   - docs/metamodel/classes/Contact.md
#   - docs/metamodel/classes/Address.md
#   - docs/metamodel/enumerations.md
#   - docs/metamodel/diagrams/class-diagram.svg
#   - docs/metamodel/diagrams/containment-diagram.svg

echo "  Documentation generated"

# Step 8: Run integration tests
echo ""
echo "Step 8: Running integration tests..."

swift-ecore test "${TOOLS_DIR}/tests/" \
    --metamodel "${NEW_METAMODEL}" \
    --report "${CONFIG_DIR}/test-results.json"

# Output:
# Running integration tests...
# [OK] test_load_customer
# [OK] test_query_by_status
# [OK] test_create_organisation
# [OK] test_update_contact
# [OK] test_serialize_xmi
# [OK] test_serialize_json
# [OK] test_validation_rules
#
# Tests: 7 passed, 0 failed

echo "  Integration tests passed"

# Step 9: Verify toolchain
echo ""
echo "Step 9: Verifying toolchain..."

swift-ecore verify-toolchain \
    --config "${CONFIG_DIR}/metamodel-registry.json" \
    --tools "${TOOLS_DIR}" \
    --templates "${TEMPLATES_DIR}"

# Output:
# Toolchain Verification
# ======================
# [OK] Metamodel registry valid
# [OK] Code generation output exists
# [OK] MTL templates compile
# [OK] ATL transformations compile
# [OK] Validation rules present
# [OK] Query library valid
# [OK] Documentation generated
#
# Toolchain Status: READY

echo ""
echo "=============================================="
echo "  Toolchain Update Complete"
echo "=============================================="
echo ""
echo "Updated components:"
echo "  - Generated code (Swift)"
echo "  - MTL templates (${TEMPLATES_DIR})"
echo "  - ATL transformations (${TOOLS_DIR}/transforms)"
echo "  - Configuration files (${CONFIG_DIR})"
echo "  - Validation rules"
echo "  - Query library"
echo "  - Documentation"
echo ""
echo "All integration tests passed."
echo "Toolchain ready for deployment."
