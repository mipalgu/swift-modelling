# Deposits never stop, so bound the exploration to three steps
# Expected error: the state space is incomplete, so the invariant is inconclusive
swift-henshin explore bank.henshin_text bank.xmi --rules deposit \
    --param deposit.number=2 --param deposit.amount=10 --max-depth 3 \
    --invariant "self.accounts->forAll(a | a.balance >= 0)"

# Output:
# state space: 4 states, 3 transitions, 1 open
# deadlocks: 0
# expanded states: 3, applications: 3
# invariant aql(self.accounts->forAll(a | a.balance >= 0)): holds (inconclusive: state space incomplete)
