/*
 * Alloy 6 module of a model of the Ecore package lending (http://example.org/lending).
 *
 * Every object of the model is an atom, and the fact 'Model' fixes the objects of every signature and the values of
 * every feature. The command 'conforms' has an instance exactly if the model satisfies the multiplicities, opposite
 * references and containment of the metamodel; each 'check' reports no counterexample exactly if the model satisfies
 * the invariant. Values of uninterpreted data types are not fixed.
 */
module lending_instance

open lending
open util/boolean

one sig Library1 extends Library {}

one sig Branch2, Branch3 extends Branch {}

one sig Book7 extends Book {}

one sig Periodical8 extends Periodical {}

one sig ReferenceBook9 extends ReferenceBook {}

one sig Member4, Member6 extends Member {}

one sig Loan5 extends Loan {}

/** The objects and values of the model. */
fact Model {
  EObject = Library1 + Branch2 + Branch3 + Member4 + Loan5 + Member6 + Book7 + Periodical8 + ReferenceBook9
  Restricted = ReferenceBook9
  Library1.name = "Riverside Library"
  Library1.branches = Branch2 + Branch3
  Library1.members = Member4 + Member6
  Library1.items = Book7 + Periodical8 + ReferenceBook9
  Branch2.name = "Central"
  Branch2.code = 1
  Branch2.holdings = Book7 + ReferenceBook9
  Branch3.name = "Northside"
  Branch3.code = 2
  Branch3.holdings = Periodical8
  Member4.name = "Alex"
  Member4.age = 34
  Member4.active = True
  Member4.loans = Loan5
  Loan5.item = Periodical8
  Loan5.member = Member4
  Loan5.due = 14
  Member6.name = "Sam"
  Member6.age = 12
  Member6.active = False
  no Member6.loans
  Book7.name = "A Field Guide to Birds"
  Book7.year = 2019
  Book7.status = Status_AVAILABLE
  Book7.location = Branch2
  no Book7.loan
  Book7.pages = 320
  Book7.isbn = "978-0-00-000000-2"
  -- Book7.rating is not fixed: values of EDouble are uninterpreted
  Periodical8.name = "Science Monthly"
  no Periodical8.year
  Periodical8.status = Status_ON_LOAN
  Periodical8.location = Branch3
  Periodical8.loan = Loan5
  Periodical8.issue = 42
  ReferenceBook9.name = "Atlas of the World"
  ReferenceBook9.year = 2021
  ReferenceBook9.status = Status_AVAILABLE
  ReferenceBook9.location = Branch2
  no ReferenceBook9.loan
  ReferenceBook9.pages = 200
  no ReferenceBook9.isbn
  -- ReferenceBook9.rating is not fixed: values of EDouble are uninterpreted
  ReferenceBook9.minimumAge = 16
}

/** The model satisfies the structure of the metamodel exactly if this command has an instance. */
run conforms {} for 9 but 12 Int

assert Library_UniqueBranchCodes_satisfied {
  Library_UniqueBranchCodes
}
check Library_UniqueBranchCodes_satisfied for 9 but 12 Int

assert Item_AvailableHasNoLoan_satisfied {
  Item_AvailableHasNoLoan
}
check Item_AvailableHasNoLoan_satisfied for 9 but 12 Int

assert ReferenceBook_ReadingRoomOnly_satisfied {
  ReferenceBook_ReadingRoomOnly
}
check ReferenceBook_ReadingRoomOnly_satisfied for 9 but 12 Int

assert Member_NonNegativeAge_satisfied {
  Member_NonNegativeAge
}
check Member_NonNegativeAge_satisfied for 9 but 12 Int

assert Member_AgeRestriction_satisfied {
  Member_AgeRestriction
}
check Member_AgeRestriction_satisfied for 9 but 12 Int

assert Member_ActiveLoans_satisfied {
  Member_ActiveLoans
}
check Member_ActiveLoans_satisfied for 9 but 12 Int

assert Loan_OnLoanStatus_satisfied {
  Loan_OnLoanStatus
}
check Loan_OnLoanStatus_satisfied for 9 but 12 Int
