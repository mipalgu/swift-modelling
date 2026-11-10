# Validate a model whose book has no title
# Expected error: title is required, so validation fails
swift-ecore validate library-untitled.xmi --metamodel Library.xcore \
  || echo "swift-ecore exited with status $?"

# Output:
# warning: Library.xcore: line 14, column 26: The Xbase body of the operation is kept as text but not executed
# error: Book 'B3' (//@items.0): Feature 'title' needs at least 1 value(s) but has 0
# Error: Validation failed: 1 error(s), 0 warning(s)
# swift-ecore exited with status 1
