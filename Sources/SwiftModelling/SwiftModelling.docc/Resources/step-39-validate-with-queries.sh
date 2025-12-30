#!/bin/bash
# Validate that all managers are full-time
managers_count=$(swift-aql query company-model.xmi \
  --query "self.employees->select(e | e.oclIsKindOf(Manager))->size()" \
  --context "company1")

fulltime_managers=$(swift-aql query company-model.xmi \
  --query "self.employees->select(e | e.oclIsKindOf(Manager) and e.status = EmploymentStatus::FULL_TIME)->size()" \
  --context "company1")

if [ "$managers_count" -eq "$fulltime_managers" ]; then
  echo "✓ All managers are full-time"
else
  echo "✗ Not all managers are full-time"
  exit 1
fi
