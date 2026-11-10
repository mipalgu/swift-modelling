# A translated invariant: a predicate over all departments, an assertion of it and its check
grep -A 2 -e "^pred Department_WithinCapacity" -e "^assert Department_WithinCapacity" \
  verification/organisation.als
grep "^check Department_WithinCapacity" verification/organisation.als

# Output:
# pred Department_WithinCapacity {
#   all self: Department | #self.members <= self.capacity
# }
# ...
# assert Department_WithinCapacity_holds {
#   Department_WithinCapacity
# }
# check Department_WithinCapacity_holds for 4 but 5 Int, exactly 4 String
