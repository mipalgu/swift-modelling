swift-ecore convert Courses.oclinecore Courses.ecore

# The invariants are kept in OCL annotations of their classes
grep -c 'source="http://www.eclipse.org/emf/2002/Ecore/OCL/Pivot"' Courses.ecore

# Each class names its invariants in the constraints detail of its Ecore annotation
grep 'key="constraints"' Courses.ecore

# Output:
# Conversion completed: Courses.ecore
# 5
#       <details key="constraints" value="UniqueCodes"/>
#       <details key="constraints" value="PositiveCapacity NotOverfull AdvancedNeedsPrerequisite"/>
#       <details key="constraints" value="HasName"/>
