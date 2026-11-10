# Explore every state that payOne reaches, and check four properties
swift-henshin explore payments.henshin_text small-bank.xmi --rules payOne \
    --invariant "self.accounts.balance->sum() = 3" \
    --reach "self.accounts->exists(a | a.balance = 3)" \
    --forbid overdrawn --deadlock --dot payments.dot

# Output:
# state space: 4 states, 6 transitions, complete
# deadlocks: 0
# expanded states: 4, applications: 6
# invariant aql(self.accounts.balance->sum() = 3): holds
# invariant not pattern overdrawn: holds
# reachable aql(self.accounts->exists(a | a.balance = 3)): holds
#   state 2 after 1 step(s)
#     1. 0 -> 2: payOne(source=Account(2), target=Account(1))
# deadlock freedom: holds
