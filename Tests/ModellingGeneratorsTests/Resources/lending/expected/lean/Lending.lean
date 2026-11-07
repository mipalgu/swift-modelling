/-!
# Lean 4 module of the Ecore package lending (http://example.org/lending)

Every concrete class is a structure with a field for each feature, inherited features first, and an object of a model
is a value of the sum type `Obj`, with one constructor per concrete class. Each class has a membership test
`Obj.is<Class>`, which holds for the objects of its subclasses too, and each feature an accessor
`Obj.<Class>_<feature>`. A model lists its objects with their identifiers. `WellFormed` states the multiplicities,
opposite references and containment of the metamodel, and each translated invariant is a proposition over a model.
All of them are decidable, so that `decide` checks a model by evaluation.

Objects form a closed sum type rather than structures that implement a type class. A model is then a plain list with
decidable equality, membership in abstract classes and in several supertypes is a total function over the
constructors, and every proposition reduces by evaluation. A type class would leave the set of classes open, so that
the objects of a model would need an existential package, which has neither decidable equality nor a case analysis
that `decide` can evaluate.

Not exported:
- operations: Member.canBorrow
- derived and volatile features: Member.loanCount
- whether many-valued features are ordered or unique: their values are lists in model order, and only references
  must be free of repetitions
- the structure of values of the data types EDouble: they are their serialised text
- invariants outside the translatable subset of OCL:
  - Named.NonEmptyName: string operations are not supported

Integers are unbounded. A comparison involving an absent value is false, as an OCL invariant over an invalid value is
not satisfied. Strings only support equality.
-/

namespace Lending

/-- The identifier of an object of a model. -/
abbrev ObjectId := Nat

/-- The literals of the enumeration Status. -/
inductive Status where
  | AVAILABLE
  | ON_LOAN
  | WITHDRAWN
  deriving DecidableEq, Repr

/-- Values of the data type EDouble, which the export represents by their serialised text. -/
abbrev EDouble := String

/-- The values of the features of an object of the class Library. -/
structure Library where
  name : String
  branches : List ObjectId
  members : List ObjectId
  items : List ObjectId
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class Branch. -/
structure Branch where
  name : String
  code : Int
  holdings : List ObjectId
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class Book. -/
structure Book where
  name : String
  year : Option Int
  status : Status
  location : Option ObjectId
  loan : Option ObjectId
  pages : Int
  isbn : Option String
  rating : Option EDouble
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class Periodical. -/
structure Periodical where
  name : String
  year : Option Int
  status : Status
  location : Option ObjectId
  loan : Option ObjectId
  issue : Int
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class ReferenceBook. -/
structure ReferenceBook where
  name : String
  year : Option Int
  status : Status
  location : Option ObjectId
  loan : Option ObjectId
  pages : Int
  isbn : Option String
  rating : Option EDouble
  minimumAge : Int
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class Member. -/
structure Member where
  name : String
  age : Int
  active : Bool
  loans : List ObjectId
  deriving DecidableEq, Repr

/-- The values of the features of an object of the class Loan. -/
structure Loan where
  item : ObjectId
  member : ObjectId
  due : Int
  deriving DecidableEq, Repr

/-- An object of a model: the values of its features, tagged with its class. -/
inductive Obj where
  | ofLibrary (value : Library)
  | ofBranch (value : Branch)
  | ofBook (value : Book)
  | ofPeriodical (value : Periodical)
  | ofReferenceBook (value : ReferenceBook)
  | ofMember (value : Member)
  | ofLoan (value : Loan)
  deriving DecidableEq, Repr

/-- Whether an object is an instance of the class Library, directly or through a subclass. -/
def Obj.isLibrary : Obj → Bool
  | .ofLibrary _ => true
  | _ => false

/-- Whether an object is an instance of the class Named, directly or through a subclass. -/
def Obj.isNamed : Obj → Bool
  | .ofBranch _ | .ofBook _ | .ofPeriodical _ | .ofReferenceBook _ | .ofMember _ => true
  | _ => false

/-- Whether an object is an instance of the class Branch, directly or through a subclass. -/
def Obj.isBranch : Obj → Bool
  | .ofBranch _ => true
  | _ => false

/-- Whether an object is an instance of the class Item, directly or through a subclass. -/
def Obj.isItem : Obj → Bool
  | .ofBook _ | .ofPeriodical _ | .ofReferenceBook _ => true
  | _ => false

/-- Whether an object is an instance of the class Book, directly or through a subclass. -/
def Obj.isBook : Obj → Bool
  | .ofBook _ | .ofReferenceBook _ => true
  | _ => false

/-- Whether an object is an instance of the class Periodical, directly or through a subclass. -/
def Obj.isPeriodical : Obj → Bool
  | .ofPeriodical _ => true
  | _ => false

/-- Whether an object is an instance of the class Restricted, directly or through a subclass. -/
def Obj.isRestricted : Obj → Bool
  | .ofReferenceBook _ => true
  | _ => false

/-- Whether an object is an instance of the class ReferenceBook, directly or through a subclass. -/
def Obj.isReferenceBook : Obj → Bool
  | .ofReferenceBook _ => true
  | _ => false

/-- Whether an object is an instance of the class Member, directly or through a subclass. -/
def Obj.isMember : Obj → Bool
  | .ofMember _ => true
  | _ => false

/-- Whether an object is an instance of the class Loan, directly or through a subclass. -/
def Obj.isLoan : Obj → Bool
  | .ofLoan _ => true
  | _ => false

/-- The value of the feature name of an object of the class Library. -/
def Obj.Library_name : Obj → Option String
  | .ofLibrary v => some v.name
  | _ => none

/-- The values of the feature branches of an object of the class Library. -/
def Obj.Library_branches : Obj → List ObjectId
  | .ofLibrary v => v.branches
  | _ => []

/-- The values of the feature members of an object of the class Library. -/
def Obj.Library_members : Obj → List ObjectId
  | .ofLibrary v => v.members
  | _ => []

/-- The values of the feature items of an object of the class Library. -/
def Obj.Library_items : Obj → List ObjectId
  | .ofLibrary v => v.items
  | _ => []

/-- The value of the feature name of an object of the class Named. -/
def Obj.Named_name : Obj → Option String
  | .ofBranch v => some v.name
  | .ofBook v => some v.name
  | .ofPeriodical v => some v.name
  | .ofReferenceBook v => some v.name
  | .ofMember v => some v.name
  | _ => none

/-- The value of the feature code of an object of the class Branch. -/
def Obj.Branch_code : Obj → Option Int
  | .ofBranch v => some v.code
  | _ => none

/-- The values of the feature holdings of an object of the class Branch. -/
def Obj.Branch_holdings : Obj → List ObjectId
  | .ofBranch v => v.holdings
  | _ => []

/-- The value of the feature year of an object of the class Item. -/
def Obj.Item_year : Obj → Option Int
  | .ofBook v => v.year
  | .ofPeriodical v => v.year
  | .ofReferenceBook v => v.year
  | _ => none

/-- The value of the feature status of an object of the class Item. -/
def Obj.Item_status : Obj → Option Status
  | .ofBook v => some v.status
  | .ofPeriodical v => some v.status
  | .ofReferenceBook v => some v.status
  | _ => none

/-- The value of the feature location of an object of the class Item. -/
def Obj.Item_location : Obj → Option ObjectId
  | .ofBook v => v.location
  | .ofPeriodical v => v.location
  | .ofReferenceBook v => v.location
  | _ => none

/-- The value of the feature loan of an object of the class Item. -/
def Obj.Item_loan : Obj → Option ObjectId
  | .ofBook v => v.loan
  | .ofPeriodical v => v.loan
  | .ofReferenceBook v => v.loan
  | _ => none

/-- The value of the feature pages of an object of the class Book. -/
def Obj.Book_pages : Obj → Option Int
  | .ofBook v => some v.pages
  | .ofReferenceBook v => some v.pages
  | _ => none

/-- The value of the feature isbn of an object of the class Book. -/
def Obj.Book_isbn : Obj → Option String
  | .ofBook v => v.isbn
  | .ofReferenceBook v => v.isbn
  | _ => none

/-- The value of the feature rating of an object of the class Book. -/
def Obj.Book_rating : Obj → Option EDouble
  | .ofBook v => v.rating
  | .ofReferenceBook v => v.rating
  | _ => none

/-- The value of the feature issue of an object of the class Periodical. -/
def Obj.Periodical_issue : Obj → Option Int
  | .ofPeriodical v => some v.issue
  | _ => none

/-- The value of the feature minimumAge of an object of the class Restricted. -/
def Obj.Restricted_minimumAge : Obj → Option Int
  | .ofReferenceBook v => some v.minimumAge
  | _ => none

/-- The value of the feature age of an object of the class Member. -/
def Obj.Member_age : Obj → Option Int
  | .ofMember v => some v.age
  | _ => none

/-- The value of the feature active of an object of the class Member. -/
def Obj.Member_active : Obj → Option Bool
  | .ofMember v => some v.active
  | _ => none

/-- The values of the feature loans of an object of the class Member. -/
def Obj.Member_loans : Obj → List ObjectId
  | .ofMember v => v.loans
  | _ => []

/-- The value of the feature item of an object of the class Loan. -/
def Obj.Loan_item : Obj → Option ObjectId
  | .ofLoan v => some v.item
  | _ => none

/-- The value of the feature member of an object of the class Loan. -/
def Obj.Loan_member : Obj → Option ObjectId
  | .ofLoan v => some v.member
  | _ => none

/-- The value of the feature due of an object of the class Loan. -/
def Obj.Loan_due : Obj → Option Int
  | .ofLoan v => some v.due
  | _ => none

/-- A model: its objects, each with its identifier. -/
structure Model where
  objects : List (ObjectId × Obj)

/-- The object of a model with an identifier, if there is one. -/
def Model.get? (m : Model) (o : ObjectId) : Option Obj :=
  m.objects.lookup o

/-- The value of a single-valued feature of an object, absent if the object or the value is absent. -/
def Model.one {α : Type} (m : Model) (f : Obj → Option α) (o : Option ObjectId) : Option α :=
  (o.bind m.get?).bind f

/-- The values of a many-valued feature of an object, empty if the object is absent. -/
def Model.many {α : Type} (m : Model) (f : Obj → List α) (o : Option ObjectId) : List α :=
  match o.bind m.get? with
  | some x => f x
  | none => []

/-- The values of a single-valued feature of several objects, skipping absent values. -/
def Model.oneAll {α : Type} (m : Model) (f : Obj → Option α) (os : List ObjectId) : List α :=
  os.filterMap fun o => m.one f (some o)

/-- The values of a many-valued feature of several objects, concatenated. -/
def Model.manyAll {α : Type} (m : Model) (f : Obj → List α) (os : List ObjectId) : List α :=
  os.flatMap fun o => m.many f (some o)

/-- Whether an object is present and passes a membership test. -/
def Model.isKindOf (m : Model) (p : Obj → Bool) (o : Option ObjectId) : Bool :=
  match o.bind m.get? with
  | some x => p x
  | none => false

/-- The identifiers of the objects of a model that pass a membership test, in model order. -/
def Model.instancesOf (m : Model) (p : Obj → Bool) : List ObjectId :=
  (m.objects.filter fun e => p e.2).map Prod.fst

/-- Whether two values are present and equal. -/
def optEq {α : Type} [BEq α] : Option α → Option α → Bool
  | some a, some b => a == b
  | _, _ => false

/-- Whether two values are present and different. -/
def optNe {α : Type} [BEq α] : Option α → Option α → Bool
  | some a, some b => a != b
  | _, _ => false

/-- Whether two integers are present and the first is less than the second. -/
def optLt : Option Int → Option Int → Bool
  | some a, some b => decide (a < b)
  | _, _ => false

/-- Whether two integers are present and the first is at most the second. -/
def optLe : Option Int → Option Int → Bool
  | some a, some b => decide (a ≤ b)
  | _, _ => false

/-- Whether two integers are present and the first is greater than the second. -/
def optGt : Option Int → Option Int → Bool
  | some a, some b => decide (a > b)
  | _, _ => false

/-- Whether two integers are present and the first is at least the second. -/
def optGe : Option Int → Option Int → Bool
  | some a, some b => decide (a ≥ b)
  | _, _ => false

/-- The sum of two integers, absent if either is absent. -/
def optAdd : Option Int → Option Int → Option Int
  | some a, some b => some (a + b)
  | _, _ => none

/-- The difference of two integers, absent if either is absent. -/
def optSub : Option Int → Option Int → Option Int
  | some a, some b => some (a - b)
  | _, _ => none

/-- The product of two integers, absent if either is absent. -/
def optMul : Option Int → Option Int → Option Int
  | some a, some b => some (a * b)
  | _, _ => none

/-- The quotient of two integers rounded towards zero, as OCL 'div' computes it; absent if either is absent or the
divisor is zero. -/
def optDiv : Option Int → Option Int → Option Int
  | some a, some b => if b = 0 then none else some (a.tdiv b)
  | _, _ => none

/-- The remainder of the division of two integers rounded towards zero, as OCL 'mod' computes it; absent if either is
absent or the divisor is zero. -/
def optMod : Option Int → Option Int → Option Int
  | some a, some b => if b = 0 then none else some (a.tmod b)
  | _, _ => none

/-- The negation of an integer, absent if it is absent. -/
def optNeg : Option Int → Option Int
  | some a => some (-a)
  | none => none

/-- Whether a value is present and in a list. -/
def optContains {α : Type} [BEq α] (l : List α) : Option α → Bool
  | some a => l.contains a
  | none => false

/-- Whether the values of a list are pairwise different. -/
def allDistinct {α : Type} [BEq α] : List α → Bool
  | [] => true
  | a :: rest => !rest.contains a && allDistinct rest

/-- Whether a number of values lies within a lower bound and an optional upper bound. -/
def withinBounds (n lower : Nat) (upper : Option Nat) : Bool :=
  decide (lower ≤ n) && upper.all fun u => decide (n ≤ u)

/-- Whether every object that passes the test of an owner class has at most one value of a single-valued reference,
which identifies an object of the target class, and has a value if the reference is required. -/
def Model.singleReferenceOk (m : Model) (owner target : Obj → Bool) (f : Obj → Option ObjectId) (required : Bool) :
    Bool :=
  m.objects.all fun e => !owner e.2 || match f e.2 with
    | some t => m.isKindOf target (some t)
    | none => !required

/-- Whether every object that passes the test of an owner class has values of a many-valued reference that identify
distinct objects of the target class, and as many as the bounds allow. -/
def Model.manyReferenceOk (m : Model) (owner target : Obj → Bool) (f : Obj → List ObjectId) (lower : Nat)
    (upper : Option Nat) : Bool :=
  m.objects.all fun e => !owner e.2 ||
    ((f e.2).all (fun t => m.isKindOf target (some t)) && allDistinct (f e.2) &&
      withinBounds (f e.2).length lower upper)

/-- Whether every object that passes the test of an owner class has as many values of a many-valued attribute as the
bounds allow. -/
def Model.manyAttributeOk {α : Type} (m : Model) (owner : Obj → Bool) (f : Obj → List α) (lower : Nat)
    (upper : Option Nat) : Bool :=
  m.objects.all fun e => !owner e.2 || withinBounds (f e.2).length lower upper

/-- Whether every object that a reference of an object identifies refers back to that object through the opposite
reference. -/
def Model.oppositeOk (m : Model) (f g : Obj → List ObjectId) : Bool :=
  m.objects.all fun e => (f e.2).all fun t => (m.many g (some t)).contains e.1

/-- The identifiers of the objects that an object contains. -/
def Obj.contents (o : Obj) : List ObjectId :=
  Obj.Library_branches o ++ Obj.Library_members o ++ Obj.Library_items o ++ Obj.Member_loans o

/-- The identifiers of the objects that are contained, directly or indirectly, in objects, up to a depth that the
fuel bounds. -/
def Model.descendants (m : Model) : Nat → List ObjectId → List ObjectId
  | 0, _ => []
  | n + 1, os =>
    let children := m.manyAll Obj.contents os
    children ++ m.descendants n children

/-- Whether every object has at most one container and does not contain itself; containment cycles are no longer
than the number of objects. -/
def Model.containmentOk (m : Model) : Bool :=
  allDistinct (m.objects.flatMap fun e => e.2.contents) &&
    m.objects.all fun e => !(m.descendants m.objects.length [e.1]).contains e.1

/-- Whether a model is well formed: its identifiers are distinct, its references identify objects of their classes
and respect the multiplicities and opposites of the metamodel, the many-valued attributes respect their bounds, and
its containment is a forest. -/
@[reducible] def WellFormed (m : Model) : Prop :=
  (m.objects.map Prod.fst).Nodup ∧
    m.manyReferenceOk Obj.isLibrary Obj.isBranch Obj.Library_branches 0 none = true ∧
    m.manyReferenceOk Obj.isLibrary Obj.isMember Obj.Library_members 0 none = true ∧
    m.manyReferenceOk Obj.isLibrary Obj.isItem Obj.Library_items 0 none = true ∧
    m.manyReferenceOk Obj.isBranch Obj.isItem Obj.Branch_holdings 0 none = true ∧
    m.oppositeOk Obj.Branch_holdings (fun o => (Obj.Item_location o).toList) = true ∧
    m.oppositeOk (fun o => (Obj.Item_location o).toList) Obj.Branch_holdings = true ∧
    m.singleReferenceOk Obj.isItem Obj.isBranch Obj.Item_location false = true ∧
    m.singleReferenceOk Obj.isItem Obj.isLoan Obj.Item_loan false = true ∧
    m.oppositeOk (fun o => (Obj.Item_loan o).toList) (fun o => (Obj.Loan_item o).toList) = true ∧
    m.oppositeOk (fun o => (Obj.Loan_item o).toList) (fun o => (Obj.Item_loan o).toList) = true ∧
    m.manyReferenceOk Obj.isMember Obj.isLoan Obj.Member_loans 0 (some 3) = true ∧
    m.singleReferenceOk Obj.isLoan Obj.isItem Obj.Loan_item true = true ∧
    m.singleReferenceOk Obj.isLoan Obj.isMember Obj.Loan_member true = true ∧
    m.oppositeOk (fun o => (Obj.Loan_member o).toList) Obj.Member_loans = true ∧
    m.oppositeOk Obj.Member_loans (fun o => (Obj.Loan_member o).toList) = true ∧
    m.containmentOk = true

/-- The invariant UniqueBranchCodes of Library: self.branches->isUnique(b | b.code) -/
@[reducible] def Library.UniqueBranchCodes (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isLibrary, allDistinct ((m.many Obj.Library_branches (some self)).map (fun b => m.one Obj.Branch_code (some b))) = true

/-- The invariant AvailableHasNoLoan of Item: self.status = Status::AVAILABLE implies self.loan->isEmpty() -/
@[reducible] def Item.AvailableHasNoLoan (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isItem, (!(optEq (m.one Obj.Item_status (some self)) (some Status.AVAILABLE)) || (m.one Obj.Item_loan (some self)).isNone) = true

/-- The invariant ReadingRoomOnly of ReferenceBook: self.status <> Status::ON_LOAN -/
@[reducible] def ReferenceBook.ReadingRoomOnly (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isReferenceBook, optNe (m.one Obj.Item_status (some self)) (some Status.ON_LOAN) = true

/-- The invariant NonNegativeAge of Member: self.age >= 0 -/
@[reducible] def Member.NonNegativeAge (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isMember, optGe (m.one Obj.Member_age (some self)) (some 0) = true

/-- The invariant AgeRestriction of Member: self.loans->forAll(l | l.item.oclIsKindOf(Restricted) implies self.age >= l.item.oclAsType(Restricted).minimumAge) -/
@[reducible] def Member.AgeRestriction (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isMember, (m.many Obj.Member_loans (some self)).all (fun l => (!(m.isKindOf Obj.isRestricted (m.one Obj.Loan_item (some l))) || optGe (m.one Obj.Member_age (some self)) (m.one Obj.Restricted_minimumAge (m.one Obj.Loan_item (some l))))) = true

/-- The invariant ActiveLoans of Member: self.active or self.loans->isEmpty() -/
@[reducible] def Member.ActiveLoans (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isMember, (optEq (m.one Obj.Member_active (some self)) (some true) || (m.many Obj.Member_loans (some self)).isEmpty) = true

/-- The invariant OnLoanStatus of Loan: self.item.status = Status::ON_LOAN -/
@[reducible] def Loan.OnLoanStatus (m : Model) : Prop :=
  ∀ self ∈ m.instancesOf Obj.isLoan, optEq (m.one Obj.Item_status (m.one Obj.Loan_item (some self))) (some Status.ON_LOAN) = true

/-- All translated invariants. -/
@[reducible] def Invariants (m : Model) : Prop :=
  Library.UniqueBranchCodes m ∧
    Item.AvailableHasNoLoan m ∧
    ReferenceBook.ReadingRoomOnly m ∧
    Member.NonNegativeAge m ∧
    Member.AgeRestriction m ∧
    Member.ActiveLoans m ∧
    Loan.OnLoanStatus m

end Lending
