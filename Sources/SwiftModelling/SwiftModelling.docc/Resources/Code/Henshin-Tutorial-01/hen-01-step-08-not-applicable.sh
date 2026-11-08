# Try to transfer more than account 2 holds
# Expected error: the condition of the rule rejects the only match, so nothing is written
swift-henshin apply bank.henshin_text bank.xmi -u transfer \
    --param from=2 --param to=1 --param amount=30 -o bank-overdrawn.xmi

# Output:
# error: the unit 'transfer' could not be applied to bank.xmi; nothing was written
