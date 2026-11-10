# See which objects a transfer matches, without writing a model
swift-henshin apply bank.henshin_text bank.xmi -u transfer \
    --param from=1 --param to=2 --param amount=30 --trace --dry-run

# Output:
# applied transfer(source=Account(1), target=Account(2), amount=30, from=1, to=2, x=80, y=20): created 0, deleted 0
# amount = 30
# from = 1
# to = 2
