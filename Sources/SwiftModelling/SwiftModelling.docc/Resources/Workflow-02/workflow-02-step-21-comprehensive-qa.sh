#!/bin/sh
# Quality assurance for the migrated models. Every check computes its
# result; the script fails if any check fails.
set -u

failures=0

# Records the outcome of a check: description, expected, actual value.
check() {
    if [ "$2" = "$3" ]; then
        echo "PASS $1"
    else
        echo "FAIL $1: expected $2, got $3"
        failures=$((failures + 1))
    fi
}

# Evaluates an AQL query against a model and prints the bare result.
aql() {
    swift-aql query "$1" -m "$2" "$3"
}

echo "== Strict validation (warnings count as failures)"
if swift-ecore validate --strict migrated/*.xmi -m Orders.ecore; then
    check "strict validation" ok ok
else
    check "strict validation" ok failed
fi

mkdir -p qa
for model in migrated/*.xmi; do
    name=$(basename "$model" .xmi)
    cleaned="cleaned/$name.xmi"
    echo "== $name"

    check "$name: every item refers to a product" 0 \
        "$(aql "$model" Orders.ecore "self.orders.items->select(i | i.product = null)->size()")"

    check "$name: statuses unchanged" \
        "$(aql "$cleaned" LegacyOrders.ecore "self.orders.status")" \
        "$(aql "$model" Orders.ecore "self.orders->collect(o | o.status.toString())")"

    check "$name: item amounts unchanged" \
        "$(aql "$cleaned" LegacyOrders.ecore "self.orders.items->collect(i | i.qty * i.unitPrice)->sum()")" \
        "$(aql "$model" Orders.ecore "self.orders.items->collect(i | i.quantity * i.unitPrice)->sum()")"

    # XMI -> JSON -> XMI must not change the model.
    swift-ecore convert "$model" "qa/$name.json" -m Orders.ecore --force
    swift-ecore convert "qa/$name.json" "qa/$name.xmi" -m Orders.ecore --force
    if swift-ecore compare "$model" "qa/$name.xmi" -m Orders.ecore --exit-code; then
        check "$name: JSON round trip" same same
    else
        check "$name: JSON round trip" same different
    fi
done

if [ "$failures" -gt 0 ]; then
    echo "QA failed: $failures check(s)"
    exit 1
fi
echo "QA passed"
