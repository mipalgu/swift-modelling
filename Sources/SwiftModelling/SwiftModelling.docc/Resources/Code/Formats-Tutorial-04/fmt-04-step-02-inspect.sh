# Show the classes, features and invariants of the OCLinEcore metamodel
swift-ecore inspect Courses.oclinecore --detail full

# Output:
# Metamodel: Courses.oclinecore (OCLinEcore)
# ==========================================
#
# Package courses
#   Namespace URI: http://www.example.org/courses
#   Namespace prefix: crs
#   Classes: 3
#   Enumerations: 1
#   Data types: 0
#
#   Enumeration Level
#     introductory = 0
#     intermediate = 1
#     advanced = 2
#
#   Class Faculty
#     Attributes:
#       name: EString [1..1]
#     References:
#       courses: Course [0..*], containment, opposite Course.faculty
#       students: Student [0..*], containment
#     Invariants: UniqueCodes
#
#   Class Course
#     Attributes:
#       code: EString [1..1]
#       title: EString [1..1]
#       level: Level [1..1]
#       capacity: EBigInteger [1..1]
#       freePlaces: EBigInteger [1..1], derived, transient, read-only
#     References:
#       faculty: Faculty [0..1], opposite Faculty.courses
#       prerequisites: Course [0..*]
#       enrolled: Student [0..*], opposite Student.courses
#     Operations:
#       isFull(): EBoolean
#     Invariants: PositiveCapacity, NotOverfull, AdvancedNeedsPrerequisite
#
#   Class Student
#     Attributes:
#       name: EString [1..1]
#     References:
#       courses: Course [0..*], opposite Course.enrolled
#     Invariants: HasName
