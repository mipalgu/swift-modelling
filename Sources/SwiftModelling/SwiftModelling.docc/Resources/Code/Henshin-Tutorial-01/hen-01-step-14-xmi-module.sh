# Validate the XMI module and charge a fee of 5 dollars on account 1
swift-henshin validate fees.henshin --metamodel Bank.ecore
swift-henshin apply fees.henshin bank.xmi -u chargeFee --metamodel Bank.ecore \
    --param number=1 --param fee=5 --trace --dry-run

# Output:
# fees.henshin: 0 error(s), 0 warning(s)
# applied chargeFee(account=Account(1), balance=80, fee=5, number=1): created 0, deleted 0
# fee = 5
# number = 1
