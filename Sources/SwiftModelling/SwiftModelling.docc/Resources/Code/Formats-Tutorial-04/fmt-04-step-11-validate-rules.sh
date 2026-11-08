# Validate the timetable with the constraints of a Complete OCL document
swift-ecore validate timetable.xmi --metamodel Timetable.ecore --ocl timetable-rules.ocl

# Output:
# Checking constraint: EnoughSeats (Timetable, /) ... untranslated (The operation 'iterate' has no AQL translation)
# OCL invariants: 9 of 10 check(s) satisfied
# Validation completed successfully
