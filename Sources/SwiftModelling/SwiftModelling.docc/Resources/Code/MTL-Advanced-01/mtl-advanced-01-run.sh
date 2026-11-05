# Run the UML to Swift code generator
swift-mtl generate \
  --template uml2swift.mtl \
  --metamodel uml-class.ecore \
  --model sample-model.xmi \
  --output ./generated/

# Output:
# ✓ Generation complete

# generated/ now holds one Swift file for each class, protocol and
# enumeration of the model: Identifiable.swift, Priority.swift,
# Project.swift, Status.swift, Task.swift and TaskRepository.swift.
