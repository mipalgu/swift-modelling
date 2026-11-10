# Apply the first fix of each finding, validate again and store the repaired model
swift-epsilon evl validate families.evl --model Families=families-errors.xmi -m Families.ecore \
    --fix --store Families=families-fixed.xmi
grep -n 'Sailor\|Unknown' families-fixed.xmi

# Output:
# applied: Capitalise sailor
# applied: Name the member Unknown
# All constraints are satisfied
# 9:    <families:Family lastName="Sailor">
# 13:        <sons firstName="Unknown"/>
