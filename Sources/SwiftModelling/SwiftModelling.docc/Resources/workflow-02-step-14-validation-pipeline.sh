#!/bin/bash
# Validation pipeline for migrated model instances
# Performs comprehensive checks on all migrated files

set -e

# Configuration
MIGRATED_DIR="${1:-./migrated-data}"
REPORT_DIR="./validation-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/validation_report_${TIMESTAMP}.md"

# Metamodel path
IMPROVED_METAMODEL="./metamodels/ImprovedCustomer.ecore"
VALIDATION_ATL="./transforms/CustomerMigrationValidation.atl"

# Counters
TOTAL_FILES=0
PASSED_COUNT=0
WARNING_COUNT=0
FAILED_COUNT=0

# Create directories
mkdir -p "${REPORT_DIR}"

# Initialise report
cat > "${REPORT_FILE}" << EOF
# Migration Validation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Directory:** ${MIGRATED_DIR}

---

## Summary

| Metric | Count |
|--------|-------|
EOF

echo "=============================================="
echo "  Migration Validation Pipeline"
echo "=============================================="
echo ""
echo "Validating files in: ${MIGRATED_DIR}"
echo "Report: ${REPORT_FILE}"
echo ""

# Validate metamodel first
echo "Checking metamodel..."
if ! swift-ecore validate "${IMPROVED_METAMODEL}" --quiet; then
    echo "ERROR: Metamodel validation failed"
    exit 1
fi
echo "  Metamodel: OK"

# Process each migrated file
echo ""
echo "Validating migrated instances..."

for file in "${MIGRATED_DIR}"/*-migrated.xmi; do
    if [ -f "${file}" ]; then
        ((TOTAL_FILES++))
        filename=$(basename "${file}")
        echo -n "  ${filename}: "

        # Step 1: Structural validation
        if ! swift-ecore validate "${file}" \
            --metamodel "${IMPROVED_METAMODEL}" \
            --quiet 2>/dev/null; then
            echo "FAILED (structural)"
            ((FAILED_COUNT++))
            echo "| ${filename} | FAILED | Structural validation error |" >> "${REPORT_FILE}.details"
            continue
        fi

        # Step 2: Run ATL validation transformation
        validation_output=$(swift-atl transform "${VALIDATION_ATL}" \
            --source "${file}" \
            --metamodel "${IMPROVED_METAMODEL}" \
            --validate-only \
            --quiet 2>&1) || true

        # Check validation result
        if echo "${validation_output}" | grep -q "VALIDATION PASSED"; then
            echo "PASSED"
            ((PASSED_COUNT++))
            echo "| ${filename} | PASSED | All checks passed |" >> "${REPORT_FILE}.details"
        elif echo "${validation_output}" | grep -q "VALIDATION FAILED"; then
            # Extract issue count
            issue_count=$(echo "${validation_output}" | grep -o '[0-9]* critical issues' | head -1)
            echo "WARNING (${issue_count})"
            ((WARNING_COUNT++))
            echo "| ${filename} | WARNING | ${issue_count} |" >> "${REPORT_FILE}.details"
        else
            echo "FAILED (unknown)"
            ((FAILED_COUNT++))
            echo "| ${filename} | FAILED | Unknown validation error |" >> "${REPORT_FILE}.details"
        fi
    fi
done

# Calculate percentages
if [ "${TOTAL_FILES}" -gt 0 ]; then
    PASS_PERCENT=$((PASSED_COUNT * 100 / TOTAL_FILES))
    WARN_PERCENT=$((WARNING_COUNT * 100 / TOTAL_FILES))
    FAIL_PERCENT=$((FAILED_COUNT * 100 / TOTAL_FILES))
else
    PASS_PERCENT=0
    WARN_PERCENT=0
    FAIL_PERCENT=0
fi

# Complete the report
cat >> "${REPORT_FILE}" << EOF
| Total Files | ${TOTAL_FILES} |
| Passed | ${PASSED_COUNT} (${PASS_PERCENT}%) |
| Warnings | ${WARNING_COUNT} (${WARN_PERCENT}%) |
| Failed | ${FAILED_COUNT} (${FAIL_PERCENT}%) |

---

## Detailed Results

| File | Status | Details |
|------|--------|---------|
EOF

if [ -f "${REPORT_FILE}.details" ]; then
    cat "${REPORT_FILE}.details" >> "${REPORT_FILE}"
    rm "${REPORT_FILE}.details"
fi

# Add validation criteria section
cat >> "${REPORT_FILE}" << EOF

---

## Validation Criteria

### Structural Validation
- Model conforms to CustomerManagement metamodel
- All references are resolved
- Containment constraints satisfied
- Multiplicity constraints satisfied

### Data Integrity
- No duplicate ABNs across organisations
- No duplicate customer identifiers
- No duplicate contact emails within organisation

### Business Rules
- Credit limits are non-negative
- Payment terms between 0 and 365 days
- Discount percentages between 0 and 100

### Address Validation
- Australian postcodes are 4 digits
- States are valid Australian state abbreviations
- Required address fields are populated

### Contact Validation
- Email addresses have valid format
- All contacts have names

### Cross-Reference Validation
- Primary contacts belong to customer's organisation
- Category references are valid

---

## Recommendations

EOF

if [ "${FAILED_COUNT}" -gt 0 ]; then
    cat >> "${REPORT_FILE}" << EOF
### Critical Issues
- ${FAILED_COUNT} files failed validation and require investigation
- Review failed files in detail before proceeding to production
- Consider re-running migration with fixes

EOF
fi

if [ "${WARNING_COUNT}" -gt 0 ]; then
    cat >> "${REPORT_FILE}" << EOF
### Warnings
- ${WARNING_COUNT} files have validation warnings
- Review warnings to determine if manual intervention needed
- Warnings may indicate data quality issues from source

EOF
fi

cat >> "${REPORT_FILE}" << EOF
### Next Steps
1. Address any failed validations
2. Review warnings for potential data issues
3. Run comprehensive QA tests
4. Prepare for production deployment

EOF

# Print summary
echo ""
echo "=============================================="
echo "  Validation Complete"
echo "=============================================="
echo ""
echo "Total files validated: ${TOTAL_FILES}"
echo "  Passed:   ${PASSED_COUNT} (${PASS_PERCENT}%)"
echo "  Warnings: ${WARNING_COUNT} (${WARN_PERCENT}%)"
echo "  Failed:   ${FAILED_COUNT} (${FAIL_PERCENT}%)"
echo ""
echo "Full report: ${REPORT_FILE}"

# Determine exit status
if [ "${FAILED_COUNT}" -gt 0 ]; then
    echo ""
    echo "WARNING: Some files failed validation. Review before proceeding."
    exit 1
elif [ "${WARNING_COUNT}" -gt 0 ]; then
    echo ""
    echo "NOTE: Some files have warnings. Review recommended."
    exit 0
else
    echo ""
    echo "All validations passed successfully."
    exit 0
fi
