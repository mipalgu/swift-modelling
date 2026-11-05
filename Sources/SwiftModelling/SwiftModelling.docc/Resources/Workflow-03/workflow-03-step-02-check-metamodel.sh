# Work in the integration directory that holds the files of this tutorial
cd integration

# Check the shared metamodel before any tool relies on it
swift-ecore validate ProjectManagement.ecore

# Output: Validation completed successfully

# Look at its packages, classes and enumerations
swift-ecore inspect ProjectManagement.ecore

# Output:
# Package ProjectManagement
#   Namespace URI: http://www.example.org/projectmanagement/1.0
#   Classes: 7
#   Enumerations: 3
# ...
#   Enumeration TaskStatus
#     NOT_STARTED = 0
#     IN_PROGRESS = 1
# ...
#   Class Organisation

# Measure its size: attributes, references, containment and opposites
swift-ecore statistics ProjectManagement.ecore

# Output:
# Classes: 7
# Enumerations: 3
# Attributes: 31
# References: 17
#   Containment: 6
#   Bidirectional pairs: 2
