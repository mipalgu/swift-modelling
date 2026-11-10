# Open account 3 for Ben and fund it in one step
swift-henshin apply bank.henshin_text bank.xmi -u openAndFund \
    --param client=Ben --param number=3 --param amount=50 -o bank-funded.xmi
grep 'balance=' bank-funded.xmi

# Output:
# account = Account(3)
#     <accounts id="1" balance="80">
#     <accounts id="2" balance="20">
#     <accounts id="3" balance="50">
