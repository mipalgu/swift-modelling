# Add withdrawals and check for deadlocks again
# Expected error: once every dollar is withdrawn, no rule applies
swift-henshin explore payments.henshin_text small-bank.xmi --rules payOne,withdrawOne \
    --forbid overdrawn --deadlock

# Output:
# state space: 10 states, 24 transitions, complete
# deadlocks: 1
# expanded states: 10, applications: 24
# invariant not pattern overdrawn: holds
# deadlock freedom: does not hold
#   state 9 after 3 step(s)
#     1. 0 -> 3: withdrawOne(account=Account(1))
#     2. 3 -> 7: withdrawOne(account=Account(1))
#     3. 7 -> 9: withdrawOne(account=Account(2))
