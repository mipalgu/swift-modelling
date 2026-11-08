# Repeat a transfer of 20 dollars from account 1 to account 2 while it applies
swift-henshin explore bank.henshin_text bank.xmi --rules transfer \
    --param transfer.from=1 --param transfer.to=2 --param transfer.amount=20 \
    --reach "self.accounts->exists(a | a.balance = 100)"

# Output:
# state space: 5 states, 4 transitions, complete
# deadlocks: 1
# expanded states: 5, applications: 4
# reachable aql(self.accounts->exists(a | a.balance = 100)): holds
#   state 4 after 4 step(s)
#     1. 0 -> 1: transfer(source=Account(1), target=Account(2), amount=20, from=1, to=2)
#     2. 1 -> 2: transfer(source=Account(1), target=Account(2), amount=20, from=1, to=2)
#     3. 2 -> 3: transfer(source=Account(1), target=Account(2), amount=20, from=1, to=2)
#     4. 3 -> 4: transfer(source=Account(1), target=Account(2), amount=20, from=1, to=2)
