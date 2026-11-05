swift-ecore inspect Company.ecore --detail full --show-references

# Output:
# Class Person
#   References:
#     employer: Company [0..1], container, opposite Company.employees
# Class Company
#   References:
#     employees: Person [0..*], containment, opposite Person.employer
# Reference graph:
#   Person.employer -> Company [0..1], opposite Company.employees
#   Company.employees -> Person [0..*], containment, opposite Person.employer
