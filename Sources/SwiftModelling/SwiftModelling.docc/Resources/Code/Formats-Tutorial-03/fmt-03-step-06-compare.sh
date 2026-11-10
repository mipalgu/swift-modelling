# Compare the two Ecore metamodels
swift-ecore compare Library-emfatic.ecore Library-xcore.ecore

# Output:
# Comparing metamodels: Library-emfatic.ecore -> Library-xcore.ecore
# ~ attribute Library.name unique: true -> false
# ~ reference Library.items resolve proxies: true -> false
# ~ reference Library.writers resolve proxies: true -> false
# ~ attribute Item.identifier unique: true -> false
# ~ attribute Item.title unique: true -> false
# ~ attribute Item.copies unique: true -> false
# ~ attribute Book.genre unique: true -> false
# ~ attribute Writer.name unique: true -> false
# 8 differences: 0 added, 0 removed, 8 changed
