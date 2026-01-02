# Validate the improved metamodel using swift-ecore
# Ensures the target metamodel is well-formed before migration

# Validate metamodel structure
swift-ecore validate ImprovedCustomer.ecore --verbose

# Output:
# Validating metamodel: ImprovedCustomer.ecore
# =============================================
#
# Package: CustomerManagement
#   Namespace URI: http://www.example.org/customer/2.0
#   Namespace Prefix: customer
#
# Checking class structure...
#   [OK] NamedElement (abstract)
#   [OK] IdentifiableElement (abstract, extends NamedElement)
#   [OK] Address
#   [OK] Contact (extends NamedElement)
#   [OK] Organisation (extends IdentifiableElement)
#   [OK] Customer (extends IdentifiableElement)
#   [OK] CustomerCategory (extends NamedElement)
#   [OK] CustomerNote
#   [OK] CustomerManagementSystem (extends NamedElement)
#
# Checking enumerations...
#   [OK] OrganisationType: 6 literals
#   [OK] CustomerStatus: 5 literals
#   [OK] ContactType: 4 literals
#   [OK] AddressType: 4 literals
#
# Checking references...
#   [OK] Contact.organisation <-> Organisation.contacts (bidirectional)
#   [OK] Customer.organisation <-> Organisation.customers (bidirectional)
#   [OK] Customer.category <-> CustomerCategory.customers (bidirectional)
#   [OK] CustomerNote.customer <-> Customer.notes (bidirectional)
#
# Validation Summary:
#   Classes: 9 (2 abstract)
#   Enumerations: 4
#   Attributes: 28
#   References: 18 (8 bidirectional pairs)
#   Containments: 6
#
# Result: VALID - No errors found

# Check for design best practices
swift-ecore analyse ImprovedCustomer.ecore --best-practices

# Output:
# Design Best Practices Analysis
# ==============================
#
# Naming Conventions:
#   [OK] All class names use PascalCase
#   [OK] All attribute names use camelCase
#   [OK] Australian English spelling used consistently
#       - organisation (not organization)
#       - standardising (not standardizing)
#
# Structure Analysis:
#   [OK] Abstract base classes provide shared functionality
#   [OK] Proper inheritance hierarchy established
#   [OK] No God classes detected (max 9 features per class)
#   [OK] All enumerations have at least 2 literals
#
# Reference Quality:
#   [OK] All bidirectional references have eOpposite defined
#   [OK] Containment references properly configured
#   [OK] No orphan references detected
#
# Required Attributes:
#   [OK] All required attributes have lowerBound="1"
#   [OK] Appropriate default values specified
#
# Documentation:
#   [INFO] 2 attributes have documentation annotations
#   [SUGGESTION] Consider adding documentation to all public attributes
#
# Score: 95/100 (Excellent)

# Compare with legacy metamodel structure
swift-ecore compare \
    LegacyCustomer.ecore \
    ImprovedCustomer.ecore \
    --summary

# Output:
# Metamodel Comparison Summary
# ============================
#
# Legacy: LegacyCustomer (v1.0)
# Target: CustomerManagement (v2.0)
#
# Improvements Made:
#   + Added abstract base classes (NamedElement, IdentifiableElement)
#   + Created proper enumerations (4 new EEnums)
#   + Extracted Address as structured class
#   + Extracted Contact as separate entity
#   + Separated Organisation from Customer
#   + Added CustomerCategory for classification
#   + Added CustomerNote for tracking
#
# Structural Metrics:
#                     Legacy    Improved    Change
#   Classes:          3         9           +200%
#   Abstract classes: 0         2           +2
#   Enumerations:     0         4           +4
#   Attributes/class: 12.3      3.1         -75%
#   References:       2         18          +800%
#
# Quality Improvements:
#   - God class eliminated (legacy Customer had 15 attributes)
#   - String enums replaced with proper EEnum types
#   - Denormalised data normalised
#   - Proper abstractions introduced
#
# Migration Complexity: MODERATE
# Estimated effort: 2-3 days for transformation development
