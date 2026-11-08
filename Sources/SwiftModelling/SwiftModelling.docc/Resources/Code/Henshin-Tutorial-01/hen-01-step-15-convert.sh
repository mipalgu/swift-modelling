# Write the XMI module as Henshin Text, and read it back
swift-henshin convert fees.henshin fees.henshin_text
cat fees.henshin_text
swift-henshin validate fees.henshin_text

# Output:
# ePackageImport bank
#
# // Takes a fee from an account that covers it
# rule chargeFee(IN number:EInt, IN fee:EInt, VAR balance:EInt) {
#     conditions [balance >= fee]
#     graph {
#         node account:Account {
#             id = number
#             balance = balance
#             set balance = balance - fee
#         }
#     }
# }
# fees.henshin_text: 0 error(s), 0 warning(s)
