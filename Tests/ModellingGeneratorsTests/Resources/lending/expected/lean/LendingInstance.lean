import Lending

/-!
# Lean 4 module of a model of the Ecore package lending (http://example.org/lending)

The model lists every object with its identifier, which is its position in the model; the comment before each object
names it by its class and identifier. The theorem `wellFormed` holds exactly if the model satisfies the multiplicities,
opposite references and containment of the metamodel, and each theorem `<Class>_<Invariant>_holds` holds exactly if
the model satisfies the invariant. `decide` proves each theorem by evaluation; Lean reports every theorem that does
not hold as an error at its position.

Unset optional values are `none` or empty lists. A required value that the model leaves unset is written with the
comment 'unset': a reference as the identifier 0, which no object has, so that `wellFormed` fails, and an attribute as
the default value of its type (0, false, the first literal of an enumeration, or the empty string). Values of data
types that the export does not interpret are their serialised text.
-/

namespace LendingInstance

open Lending

/-- The objects of the model. -/
def model : Lending.Model := {
  objects := [
    -- Library1
    (1, .ofLibrary { name := "Riverside Library", branches := [2, 3], members := [4, 6], items := [7, 8, 9] }),
    -- Branch2
    (2, .ofBranch { name := "Central", code := 1, holdings := [7, 9] }),
    -- Branch3
    (3, .ofBranch { name := "Northside", code := 2, holdings := [8] }),
    -- Member4
    (4, .ofMember { name := "Alex", age := 34, active := true, loans := [5] }),
    -- Loan5
    (5, .ofLoan { item := 8, member := 4, due := 14 }),
    -- Member6
    (6, .ofMember { name := "Sam", age := 12, active := false, loans := [] }),
    -- Book7
    (7, .ofBook { name := "A Field Guide to Birds", year := some 2019, status := Status.AVAILABLE, location := some 2, loan := none, pages := 320, isbn := some "978-0-00-000000-2", rating := none }),
    -- Periodical8
    (8, .ofPeriodical { name := "Science Monthly", year := none, status := Status.ON_LOAN, location := some 3, loan := some 5, issue := 42 }),
    -- ReferenceBook9
    (9, .ofReferenceBook { name := "Atlas of the World", year := some 2021, status := Status.AVAILABLE, location := some 2, loan := none, pages := 200, isbn := none, rating := none, minimumAge := 16 })
  ]
}

/-- The model satisfies the multiplicities, opposite references and containment of the metamodel. -/
theorem wellFormed : WellFormed model := by decide

/-- The model satisfies the invariant UniqueBranchCodes of Library. -/
theorem Library_UniqueBranchCodes_holds : Library.UniqueBranchCodes model := by decide

/-- The model satisfies the invariant AvailableHasNoLoan of Item. -/
theorem Item_AvailableHasNoLoan_holds : Item.AvailableHasNoLoan model := by decide

/-- The model satisfies the invariant ReadingRoomOnly of ReferenceBook. -/
theorem ReferenceBook_ReadingRoomOnly_holds : ReferenceBook.ReadingRoomOnly model := by decide

/-- The model satisfies the invariant NonNegativeAge of Member. -/
theorem Member_NonNegativeAge_holds : Member.NonNegativeAge model := by decide

/-- The model satisfies the invariant AgeRestriction of Member. -/
theorem Member_AgeRestriction_holds : Member.AgeRestriction model := by decide

/-- The model satisfies the invariant ActiveLoans of Member. -/
theorem Member_ActiveLoans_holds : Member.ActiveLoans model := by decide

/-- The model satisfies the invariant OnLoanStatus of Loan. -/
theorem Loan_OnLoanStatus_holds : Loan.OnLoanStatus model := by decide

end LendingInstance
