# Conflicts and dependencies of opening and closing accounts, with their atoms
swift-henshin analyse bank.henshin_text --rules openAccount,closeAccount \
    --direction both --granularity atoms

# Output:
# Conflicts:
#              | 0 1
# openAccount  | 1 .
# closeAccount | . 1
# openAccount conflicts with openAccount: produce-forbid
#   atoms: 1
#     produce-forbid #4=#5 in 1 minimal reason(s)
# closeAccount conflicts with closeAccount: delete-use
#   atoms: 1
#     delete-use #17=#17 in 1 minimal reason(s)
#
# Dependencies:
#              | 0 1
# openAccount  | . 1
# closeAccount | 1 .
# openAccount enables closeAccount: produce-use
#   atoms: 1
#     produce-use #4=#17 in 1 minimal reason(s)
# closeAccount enables openAccount: delete-forbid
#   atoms: 1
#     delete-forbid #17=#5 in 1 minimal reason(s)
