# Convert both textual metamodels to Ecore
swift-ecore convert Library.emf Library-emfatic.ecore
swift-ecore convert Library.xcore Library-xcore.ecore

# Output:
# Conversion completed: Library-emfatic.ecore
# warning: Library.xcore: line 14, column 26: The Xbase body of the operation is kept as text but not executed
