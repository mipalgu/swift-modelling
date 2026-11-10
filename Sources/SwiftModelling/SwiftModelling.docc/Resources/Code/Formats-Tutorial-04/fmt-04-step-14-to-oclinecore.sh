# Write the converted Ecore metamodel, with its OCL annotations, as OCLinEcore
swift-ecore convert Courses.ecore Courses-written.oclinecore
cat Courses-written.oclinecore

# Output:
# Conversion completed: Courses-written.oclinecore
# package courses : crs = 'http://www.example.org/courses'
# {
#     enum Level
#     {
#         literal introductory : 'introductory';
#         literal intermediate : 'intermediate';
#         literal advanced : 'advanced';
#     }
#     class Faculty
#     {
#         invariant UniqueCodes: courses->isUnique(c | c.code);
#         attribute name : String;
#         property courses#faculty : Course[*] { composes, ordered };
#         property students : Student[*] { composes, ordered };
#     }
#     class Course
#     {
#         invariant PositiveCapacity: capacity > 0;
#         invariant NotOverfull: enrolled->size() <= capacity;
#         invariant AdvancedNeedsPrerequisite: level = courses::Level::advanced implies prerequisites->notEmpty();
#         attribute code : String;
#         attribute title : String;
#         attribute level : Level;
#         attribute capacity : Integer;
#         property faculty#courses : Faculty[?];
#         property prerequisites : Course[*];
#         property enrolled#courses : Student[*];
#         attribute freePlaces : Integer { derived, readonly, transient, volatile }
#         {
#             derivation: capacity - enrolled->size();
#         }
#         operation isFull() : Boolean
#         {
#             body: enrolled->size() >= capacity;
#         }
#     }
#     class Student
#     {
#         invariant HasName: name.size() > 0;
#         attribute name : String;
#         property courses#enrolled : Course[*];
#     }
# }
