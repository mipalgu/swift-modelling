swift-ecore inspect company-model.json --metamodel Company.ecore --detail full

# Output:
# Model: company-model.json (JSON)
# Root objects: 1
# Objects: 4
# Classes:
#   Company: 1
#   Employee: 2
#   Manager: 1
# Objects:
#   Company 'Tech Innovations Ltd' (/)
#     employees:
#       Employee 'Alice Johnson' (//@employees.0)
#         status = FULL_TIME
#       Manager 'Carol Williams' (//@employees.2)
#         department = "Engineering"
