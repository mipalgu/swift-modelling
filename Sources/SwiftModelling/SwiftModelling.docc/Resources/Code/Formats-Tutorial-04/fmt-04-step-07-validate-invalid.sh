# Validate a faculty that violates every invariant once
# Expected error: the faculty violates five invariants, so validation fails
swift-ecore validate faculty-invalid.xmi --metamodel Courses.oclinecore \
  || echo "swift-ecore exited with status $?"

# Output:
# Checking constraint: UniqueCodes (Faculty 'Faculty of Arts', /) ... violated
# Checking constraint: NotOverfull (Course 'Drawing', //@courses.0) ... violated
# Checking constraint: PositiveCapacity (Course 'Painting', //@courses.1) ... violated
# Checking constraint: AdvancedNeedsPrerequisite (Course 'Studio Practice', //@courses.2) ... violated
# Checking constraint: HasName (Student, //@students.1) ... violated
# OCL invariants: 7 of 12 check(s) satisfied
# Error: Validation failed: 5 error(s), 0 warning(s)
# swift-ecore exited with status 1
