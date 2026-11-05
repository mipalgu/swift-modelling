cd integration

# Generate Swift types from the metamodel: the model of this template is
# ProjectManagement.ecore itself
swift-mtl generate GenerateSwiftModels.mtl --model ProjectManagement.ecore --output swift-models

# Output: Generation complete

ls swift-models/*.swift

# Output:
# swift-models/Comment.swift
# swift-models/Department.swift
# swift-models/Milestone.swift
# swift-models/ModelReference.swift
# swift-models/Organisation.swift
# swift-models/Project.swift
# swift-models/ProjectStatus.swift
# swift-models/Task.swift
# swift-models/TaskPriority.swift
# swift-models/TaskStatus.swift
# swift-models/TeamMember.swift

# Compile the generated types with the report program
swiftc -parse-as-library -o project-report swift-models/*.swift ProjectReport.swift

# The Swift program reads the JSON of the web editor with JSONDecoder
./project-report updated-project-data.json

# Output:
# Organisation: Example Software Co
# Customer Portal Redesign (ACTIVE): 3 of 5 tasks completed, 190.0 of 360.0 estimated hours used
#   in progress: Implement customer data API (Bob Williams)
# Mobile Test Automation (ACTIVE): 0 of 3 tasks completed, 0.0 of 80.0 estimated hours used
#   in progress: Set up device lab (Frank Brown)

# It reads the JSON converted from the desktop tool's XMI file just as well
./project-report project-data.json

# Output:
# Customer Portal Redesign (ACTIVE): 2 of 5 tasks completed, 135.0 of 360.0 estimated hours used
#   in progress: Implement authentication API (Bob Williams)
