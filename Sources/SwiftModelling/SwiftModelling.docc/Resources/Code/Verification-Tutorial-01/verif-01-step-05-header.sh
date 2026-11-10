# The comment at the top of the module says what was not exported, and why
head -n 18 verification/organisation.als

# Output:
# /*
#  * Alloy 6 module of the Ecore package organisation (http://www.example.org/organisation).
#  *
#  * Every class is a signature with a field for each feature; facts state the multiplicities, opposite references and
#  * containment of the metamodel. Each translated invariant is a predicate with an assertion. The command 'instance'
#  * finds an instance that satisfies all invariants, and each 'check' looks for an instance of the structure that
#  * violates one invariant.
#  *
#  * Not exported:
#  *  - the order and repetition of the values of many-valued features: fields are sets
#  *  - invariants outside the translatable subset of OCL:
#  *    - Department.NonEmptyName: string operations are not supported
#  *
#  * Integers are bounded by the bit width of each command and wrap around on overflow; an absent integer counts as zero
#  * in comparisons. Strings are atoms that only support equality.
#  */
# module organisation
