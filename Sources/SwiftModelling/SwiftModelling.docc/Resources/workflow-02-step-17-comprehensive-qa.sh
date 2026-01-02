#!/bin/bash
# Comprehensive Quality Assurance for model migration
# Executes extensive validation and testing

set -e

# Configuration
MIGRATED_DIR="./migrated-data"
METAMODEL="./metamodels/ImprovedCustomer.ecore"
QA_REPORT_DIR="./qa-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

mkdir -p "${QA_REPORT_DIR}"

# Test execution function
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -n "  ${test_name}: "
    if eval "${test_command}" > /dev/null 2>&1; then
        echo "PASSED"
        ((TESTS_PASSED++))
        return 0
    else
        echo "FAILED"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "=============================================="
echo "  Comprehensive Quality Assurance"
echo "=============================================="
echo ""
echo "Target directory: ${MIGRATED_DIR}"
echo "Report directory: ${QA_REPORT_DIR}"
echo ""

# Section 1: Metamodel Validation
echo "1. Metamodel Validation"
echo "------------------------"
run_test "Schema well-formedness" \
    "swift-ecore validate ${METAMODEL}"
run_test "Namespace URI valid" \
    "swift-ecore check-nsuri ${METAMODEL}"
run_test "No circular containments" \
    "swift-ecore check-containment ${METAMODEL}"
run_test "Reference opposites consistent" \
    "swift-ecore check-opposites ${METAMODEL}"
echo ""

# Section 2: Instance Validation
echo "2. Instance Validation"
echo "----------------------"
for file in "${MIGRATED_DIR}"/*-migrated.xmi; do
    if [ -f "${file}" ]; then
        filename=$(basename "${file}")
        run_test "Valid: ${filename}" \
            "swift-ecore validate ${file} --metamodel ${METAMODEL}"
    fi
done
echo ""

# Section 3: Data Integrity Tests
echo "3. Data Integrity Tests"
echo "-----------------------"
run_test "No orphaned references" \
    "swift-ecore check-references ${MIGRATED_DIR} --metamodel ${METAMODEL}"
run_test "All required fields populated" \
    "swift-ecore check-required ${MIGRATED_DIR} --metamodel ${METAMODEL}"
run_test "No duplicate identifiers" \
    "swift-ecore check-unique ${MIGRATED_DIR} --field identifier"
run_test "Referential integrity verified" \
    "swift-ecore check-integrity ${MIGRATED_DIR} --metamodel ${METAMODEL}"
echo ""

# Section 4: Business Rule Tests
echo "4. Business Rule Tests"
echo "----------------------"

# Test: All organisations have valid ABN format
run_test "ABN format valid" \
    "swift-ecore query ${MIGRATED_DIR} \
        --expression 'Organisation.allInstances()->forAll(o |
            o.australianBusinessNumber.size() = 0 or
            o.australianBusinessNumber.replace(\" \", \"\").size() = 11)' \
        --metamodel ${METAMODEL}"

# Test: All customers have credit limit >= 0
run_test "Credit limits non-negative" \
    "swift-ecore query ${MIGRATED_DIR} \
        --expression 'Customer.allInstances()->forAll(c |
            c.creditLimit.oclIsUndefined() or c.creditLimit >= 0)' \
        --metamodel ${METAMODEL}"

# Test: Payment terms within range
run_test "Payment terms valid (0-365)" \
    "swift-ecore query ${MIGRATED_DIR} \
        --expression 'Customer.allInstances()->forAll(c |
            c.paymentTermsDays >= 0 and c.paymentTermsDays <= 365)' \
        --metamodel ${METAMODEL}"

# Test: Email format valid
run_test "Email addresses valid" \
    "swift-ecore query ${MIGRATED_DIR} \
        --expression 'Contact.allInstances()->forAll(c |
            c.email.matches(\"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]{2,}\"))' \
        --metamodel ${METAMODEL}"

# Test: Australian postcodes valid
run_test "Postcodes valid (4 digits)" \
    "swift-ecore query ${MIGRATED_DIR} \
        --expression 'Address.allInstances()->forAll(a |
            a.postcode.matches(\"[0-9]{4}\"))' \
        --metamodel ${METAMODEL}"
echo ""

# Section 5: Performance Tests
echo "5. Performance Tests"
echo "--------------------"

# Test: Load time acceptable
run_test "Load time < 5 seconds" \
    "timeout 5 swift-ecore load ${MIGRATED_DIR} --metamodel ${METAMODEL}"

# Test: Query performance
run_test "Query performance < 2 seconds" \
    "timeout 2 swift-ecore query ${MIGRATED_DIR} \
        --expression 'Customer.allInstances()->size()' \
        --metamodel ${METAMODEL}"

# Test: Memory usage reasonable
run_test "Memory usage < 512MB" \
    "swift-ecore memory-check ${MIGRATED_DIR} --max-mb 512"
echo ""

# Section 6: Regression Tests
echo "6. Regression Tests"
echo "-------------------"

# Test: Round-trip preservation
run_test "Round-trip data preservation" \
    "./test-roundtrip.sh ${MIGRATED_DIR}"

# Test: Backward compatibility
run_test "Legacy format export works" \
    "swift-atl transform ImprovedToLegacy.atl \
        --source ${MIGRATED_DIR}/customers-batch-001-migrated.xmi \
        --source-metamodel ${METAMODEL} \
        --target /tmp/legacy-test.xmi \
        --target-metamodel metamodels/LegacyCustomer.ecore"

# Test: Comparision with expected output
run_test "Output matches expected" \
    "swift-ecore diff ${MIGRATED_DIR} ./expected-output --ignore-timestamps"
echo ""

# Section 7: Integration Tests
echo "7. Integration Tests"
echo "--------------------"
run_test "API endpoint accessible" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health | grep -q 200"
run_test "Model can be served via API" \
    "swift-ecore serve ${MIGRATED_DIR} --port 8081 --test-mode"
run_test "Query API functional" \
    "curl -s http://localhost:8081/query -d 'Customer.allInstances()->size()'"
echo ""

# Generate QA Report
echo "Generating QA Report..."
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))

cat > "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md" << EOF
# Comprehensive QA Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | ${TOTAL_TESTS} |
| Passed | ${TESTS_PASSED} |
| Failed | ${TESTS_FAILED} |
| Skipped | ${TESTS_SKIPPED} |
| Pass Rate | ${PASS_RATE}% |

## Test Categories

1. Metamodel Validation: Ensures schema correctness
2. Instance Validation: Verifies all migrated files
3. Data Integrity: Checks references and constraints
4. Business Rules: Validates domain logic
5. Performance: Tests load times and resource usage
6. Regression: Ensures no functionality lost
7. Integration: Tests system interactions

## Recommendation

EOF

if [ "${TESTS_FAILED}" -eq 0 ]; then
    echo "**APPROVED FOR PRODUCTION**" >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
    echo "" >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
    echo "All quality gates passed. Migration is ready for production deployment." >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
else
    echo "**NOT APPROVED - ISSUES FOUND**" >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
    echo "" >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
    echo "${TESTS_FAILED} test(s) failed. Address issues before proceeding." >> "${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"
fi

echo ""
echo "=============================================="
echo "  QA Complete"
echo "=============================================="
echo ""
echo "Total tests: ${TOTAL_TESTS}"
echo "  Passed: ${TESTS_PASSED}"
echo "  Failed: ${TESTS_FAILED}"
echo "  Skipped: ${TESTS_SKIPPED}"
echo "  Pass rate: ${PASS_RATE}%"
echo ""
echo "Report: ${QA_REPORT_DIR}/qa-report-${TIMESTAMP}.md"

if [ "${TESTS_FAILED}" -gt 0 ]; then
    echo ""
    echo "WARNING: Some tests failed. Review before proceeding."
    exit 1
fi
