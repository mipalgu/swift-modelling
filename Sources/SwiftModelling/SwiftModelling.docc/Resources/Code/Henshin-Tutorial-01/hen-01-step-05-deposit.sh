# Pay 15 dollars into account 2 and write the result to a new model
swift-henshin apply bank.henshin_text bank.xmi --unit deposit \
    --param number=2 --param amount=15 --output bank-deposit.xmi
grep 'balance=' bank-deposit.xmi

# Output:
# amount = 15
# number = 2
#     <accounts id="1" balance="80">
#     <accounts id="2" balance="35">
