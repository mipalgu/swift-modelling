swift-ecore inspect Company.ecore --detail full --show-supertypes

# Output:
# Class Person
#   Subclasses: Employee, Manager
# Class Employee extends Person
#   Attributes:
#     employeeId: EString [0..1]
#   Inherited features:
#     name: EString [0..1], from Person
#     email: EString [0..1], from Person
#     status: EmploymentStatus [0..1], from Person
#     employer: Company [0..1], container, opposite Company.employees, from Person
# Class Manager extends Person
# Inheritance hierarchy:
#   Person
#     Employee
#     Manager
#   Company
