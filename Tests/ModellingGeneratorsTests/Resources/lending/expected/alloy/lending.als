/*
 * Alloy 6 module of the Ecore package lending (http://example.org/lending).
 *
 * Every class is a signature with a field for each feature; facts state the multiplicities, opposite references and
 * containment of the metamodel. Each translated invariant is a predicate with an assertion. The command 'instance'
 * finds an instance that satisfies all invariants, and each 'check' looks for an instance of the structure that
 * violates one invariant.
 *
 * Not exported:
 *  - operations: Member.canBorrow
 *  - derived and volatile features: Member.loanCount
 *  - the order and repetition of the values of many-valued features: fields are sets
 *  - the structure of values of the data types EDouble: they are uninterpreted atoms
 *  - invariants outside the translatable subset of OCL:
 *    - Named.NonEmptyName: string operations are not supported
 *
 * Integers are bounded by the bit width of each command and wrap around on overflow; an absent integer counts as zero
 * in comparisons. Strings are atoms that only support equality.
 */
module lending

open util/boolean

/** The objects of all classes of the package. */
abstract sig EObject {}

/** The class Library. */
sig Library extends EObject {
  name: one String,
  branches: set Branch,
  members: set Member,
  items: set Item
}

/** The class Named. */
abstract sig Named extends EObject {
  name: one String
}

/** The class Branch. */
sig Branch extends Named {
  code: one Int,
  holdings: set Item
}

/** The class Item. */
abstract sig Item extends Named {
  year: lone Int,
  status: one Status,
  location: lone Branch,
  loan: lone Loan
}

/** The class Book. */
sig Book extends Item {
  pages: one Int,
  isbn: lone String,
  rating: lone EDouble
}

/** The class Periodical. */
sig Periodical extends Item {
  issue: one Int
}

/** The class Restricted. */
sig Restricted in EObject {
  minimumAge: one Int
}

/** The class ReferenceBook. */
sig ReferenceBook extends Book {}

/** The class Member. */
sig Member extends Named {
  age: one Int,
  active: one Bool,
  loans: set Loan
}

/** The class Loan. */
sig Loan extends EObject {
  item: one Item,
  member: one Member,
  due: one Int
}

/** The literals of the enumeration Status. */
abstract sig Status {}
one sig Status_AVAILABLE, Status_ON_LOAN, Status_WITHDRAWN extends Status {}

/** Values of the data type EDouble, which the export does not interpret. */
sig EDouble {}

/** The further supertypes of classes, and the classes that only their subclasses instantiate. */
fact Inheritance {
  Restricted in ReferenceBook
  ReferenceBook in Restricted
}

/** The bounds of many-valued features. */
fact Multiplicities {
  all o: Member | #o.loans <= 3
}

/** Opposite references are converse relations. */
fact Opposites {
  Branch <: holdings = ~(Item <: location)
  Item <: loan = ~(Loan <: item)
  Loan <: member = ~(Member <: loans)
}

/** The objects that each object contains. */
fun contents: EObject -> EObject {
  Library <: branches + Library <: members + Library <: items + Member <: loans
}

/** Every object has at most one container and does not contain itself. */
fact Containment {
  all o: EObject | lone contents.o
  no o: EObject | o in o.^contents
}

/** The invariant UniqueBranchCodes of Library: self.branches->isUnique(b | b.code) */
pred Library_UniqueBranchCodes {
  all self: Library | all disj b_1, b_2: self.branches | b_1.code != b_2.code
}

assert Library_UniqueBranchCodes_holds {
  Library_UniqueBranchCodes
}

/** The invariant AvailableHasNoLoan of Item: self.status = Status::AVAILABLE implies self.loan->isEmpty() */
pred Item_AvailableHasNoLoan {
  all self: Item | (self.status = Status_AVAILABLE) implies (no self.loan)
}

assert Item_AvailableHasNoLoan_holds {
  Item_AvailableHasNoLoan
}

/** The invariant ReadingRoomOnly of ReferenceBook: self.status <> Status::ON_LOAN */
pred ReferenceBook_ReadingRoomOnly {
  all self: ReferenceBook | self.status != Status_ON_LOAN
}

assert ReferenceBook_ReadingRoomOnly_holds {
  ReferenceBook_ReadingRoomOnly
}

/** The invariant NonNegativeAge of Member: self.age >= 0 */
pred Member_NonNegativeAge {
  all self: Member | self.age >= 0
}

assert Member_NonNegativeAge_holds {
  Member_NonNegativeAge
}

/** The invariant AgeRestriction of Member: self.loans->forAll(l | l.item.oclIsKindOf(Restricted) implies self.age >= l.item.oclAsType(Restricted).minimumAge) */
pred Member_AgeRestriction {
  all self: Member | all l: self.loans | (l.item in Restricted) implies (self.age >= l.item.minimumAge)
}

assert Member_AgeRestriction_holds {
  Member_AgeRestriction
}

/** The invariant ActiveLoans of Member: self.active or self.loans->isEmpty() */
pred Member_ActiveLoans {
  all self: Member | (self.active = True) or (no self.loans)
}

assert Member_ActiveLoans_holds {
  Member_ActiveLoans
}

/** The invariant OnLoanStatus of Loan: self.item.status = Status::ON_LOAN */
pred Loan_OnLoanStatus {
  all self: Loan | self.item.status = Status_ON_LOAN
}

assert Loan_OnLoanStatus_holds {
  Loan_OnLoanStatus
}

/** All translated invariants. */
pred invariants {
  Library_UniqueBranchCodes
  Item_AvailableHasNoLoan
  ReferenceBook_ReadingRoomOnly
  Member_NonNegativeAge
  Member_AgeRestriction
  Member_ActiveLoans
  Loan_OnLoanStatus
}

/** Finds an instance of the metamodel that satisfies all translated invariants. */
run instance { invariants } for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Library_UniqueBranchCodes; one is expected unless the structure implies it. */
check Library_UniqueBranchCodes_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Item_AvailableHasNoLoan; one is expected unless the structure implies it. */
check Item_AvailableHasNoLoan_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates ReferenceBook_ReadingRoomOnly; one is expected unless the structure implies it. */
check ReferenceBook_ReadingRoomOnly_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Member_NonNegativeAge; one is expected unless the structure implies it. */
check Member_NonNegativeAge_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Member_AgeRestriction; one is expected unless the structure implies it. */
check Member_AgeRestriction_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Member_ActiveLoans; one is expected unless the structure implies it. */
check Member_ActiveLoans_holds for 4 but 5 Int, exactly 4 String

/** Looks for an instance of the structure that violates Loan_OnLoanStatus; one is expected unless the structure implies it. */
check Loan_OnLoanStatus_holds for 4 but 5 Int, exactly 4 String
