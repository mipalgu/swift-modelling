# Which rules can disable which, at the coarsest granularity?
swift-henshin analyse bank.henshin_text --granularity binary

# Output:
# Conflicts:
#              | 0 1 2 3
# openAccount  | x . . .
# deposit      | . x x x
# transfer     | . x x x
# closeAccount | . x x x
# openAccount conflicts with openAccount: produce-forbid
# deposit conflicts with deposit: change-use
#   note: the attribute conditions of deposit are ignored, which may report more interactions
# deposit conflicts with transfer: change-use
#   note: the attribute conditions of deposit are ignored, which may report more interactions
#   note: the attribute conditions of transfer are ignored, which may report more interactions
# deposit conflicts with closeAccount: change-use
#   note: the attribute conditions of deposit are ignored, which may report more interactions
# transfer conflicts with deposit: change-use
#   note: the attribute conditions of transfer are ignored, which may report more interactions
#   note: the attribute conditions of deposit are ignored, which may report more interactions
# transfer conflicts with transfer: change-use
#   note: the attribute conditions of transfer are ignored, which may report more interactions
# transfer conflicts with closeAccount: change-use
#   note: the attribute conditions of transfer are ignored, which may report more interactions
# closeAccount conflicts with deposit: delete-use
#   note: the attribute conditions of deposit are ignored, which may report more interactions
# closeAccount conflicts with transfer: delete-use
#   note: the attribute conditions of transfer are ignored, which may report more interactions
# closeAccount conflicts with closeAccount: delete-use
