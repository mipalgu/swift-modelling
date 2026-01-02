# Run the UML to Swift code generator
swift-mtl generate \
  --template uml2swift.mtl \
  --metamodel uml-class.ecore \
  --model sample-model.xmi \
  --output ./generated/

# Output:
# Generating Swift code from UML model...
# Created: generated/Identifiable.swift
# Created: generated/TaskRepository.swift
# Created: generated/Priority.swift
# Created: generated/Status.swift
# Created: generated/Task.swift
# Created: generated/Project.swift
# Generation complete: 6 files created
