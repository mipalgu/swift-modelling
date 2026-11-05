#!/bin/sh
# Checks every migrated model: validation against Orders.ecore (with its
# OCL invariants), then object counts compared with the cleaned export.
set -eu

echo "== Validating the migrated models"
swift-ecore validate migrated/*.xmi -m Orders.ecore

# Evaluates an AQL query against a model and prints the bare result.
count() {
    swift-aql query "$1" -m "$2" "$3"
}

echo "== Comparing object counts with the cleaned exports"
failures=0
for model in migrated/*.xmi; do
    name=$(basename "$model")
    cleaned="cleaned/$name"
    for check in \
        "orders|self.orders->size()|self.orders->size()" \
        "items|self.orders.items->size()|self.orders.items->size()" \
        "products|self.products->size()|self.products->size()" \
        "customers|self.orders.customerEmail->asSet()->size()|self.customers->size()"
    do
        label=${check%%|*}
        queries=${check#*|}
        before=$(count "$cleaned" LegacyOrders.ecore "${queries%%|*}")
        after=$(count "$model" Orders.ecore "${queries#*|}")
        if [ "$before" = "$after" ]; then
            echo "$name: $label $after (as expected)"
        else
            echo "$name: $label expected $before but found $after"
            failures=$((failures + 1))
        fi
    done
done

if [ "$failures" -gt 0 ]; then
    echo "$failures count check(s) failed"
    exit 1
fi
echo "All count checks passed"
