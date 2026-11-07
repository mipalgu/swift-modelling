---- MODULE lending ----
\* TLA+ module of the Ecore package lending (http://example.org/lending).
\*
\* The variable obj is the object store: it maps the identifier of every object to a record of the values of its
\* features. Each concrete class has a constant set of identifiers for its direct instances, and each class is the set
\* of the identifiers of all its instances. TypeOK, Multiplicities, Opposites and Containment state the structure of
\* the metamodel, and WellFormed combines them; each translated invariant is a definition, and Invariants combines them.
\*
\* SANY parses the module, but TLC cannot check it by itself: its sets of identifiers are constants, and Int and STRING
\* are infinite. The module of a model extends it and has the model as its only state, and its configuration fixes the
\* constants, so that TLC checks the model. The export is structural: the store never changes, and behavioural models
\* such as state machines are outside its scope.
\*
\* Not exported:
\*  - operations: Member.canBorrow
\*  - derived and volatile features: Member.loanCount
\*  - the order and repetition of the values of many-valued features: fields are sets
\*  - the structure of values of the data types EDouble: they are uninterpreted constants
\*  - invariants outside the translatable subset of OCL:
\*    - Named.NonEmptyName: string operations are not supported
\*
\* An absent single value is Null. Integers are unbounded, and strings only support equality. An invariant that
\* navigates through an absent value does not hold, as in OCL.
EXTENDS Integers, FiniteSets

\* The identifiers of the direct instances of each concrete class.
CONSTANTS
    LibraryIds,
    BranchIds,
    BookIds,
    PeriodicalIds,
    ReferenceBookIds,
    MemberIds,
    LoanIds

\* The value of a single-valued feature that is absent; it identifies no object.
CONSTANT Null

\* The values of the data type EDouble, which the export does not interpret.
CONSTANT EDoubleValues

\* The object store: the record of the values of the features of every object, by identifier.
VARIABLE obj

\* Each class is the set of the identifiers of its instances, including the instances of its subclasses.
Library == LibraryIds
Named == BranchIds \cup BookIds \cup PeriodicalIds \cup ReferenceBookIds \cup MemberIds
Branch == BranchIds
Item == BookIds \cup PeriodicalIds \cup ReferenceBookIds
Book == BookIds \cup ReferenceBookIds
Periodical == PeriodicalIds
Restricted == ReferenceBookIds
ReferenceBook == ReferenceBookIds
Member == MemberIds
Loan == LoanIds

\* The identifiers of all objects.
Object == LibraryIds \cup BranchIds \cup BookIds \cup PeriodicalIds \cup ReferenceBookIds \cup MemberIds \cup LoanIds

\* The literals of the enumeration Status.
Status == {"AVAILABLE", "ON_LOAN", "WITHDRAWN"}

\* Objects of different classes have different identifiers, and Null identifies no object.
ASSUME LET ids == <<LibraryIds, BranchIds, BookIds, PeriodicalIds, ReferenceBookIds, MemberIds, LoanIds>>
       IN \A i, j \in DOMAIN ids : i # j => ids[i] \cap ids[j] = {}
ASSUME Null \notin Object

\* The records of the direct instances of Library, with a field for each feature.
LibraryRecord == [
    name: STRING,
    branches: SUBSET Branch,
    members: SUBSET Member,
    items: SUBSET Item
]

\* The records of the direct instances of Branch, with a field for each feature.
BranchRecord == [
    name: STRING,
    code: Int,
    holdings: SUBSET Item
]

\* The records of the direct instances of Book, with a field for each feature.
BookRecord == [
    name: STRING,
    year: Int \cup {Null},
    status: Status,
    location: Branch \cup {Null},
    loan: Loan \cup {Null},
    pages: Int,
    isbn: STRING \cup {Null},
    rating: EDoubleValues \cup {Null}
]

\* The records of the direct instances of Periodical, with a field for each feature.
PeriodicalRecord == [
    name: STRING,
    year: Int \cup {Null},
    status: Status,
    location: Branch \cup {Null},
    loan: Loan \cup {Null},
    issue: Int
]

\* The records of the direct instances of ReferenceBook, with a field for each feature.
ReferenceBookRecord == [
    name: STRING,
    year: Int \cup {Null},
    status: Status,
    location: Branch \cup {Null},
    loan: Loan \cup {Null},
    pages: Int,
    isbn: STRING \cup {Null},
    rating: EDoubleValues \cup {Null},
    minimumAge: Int
]

\* The records of the direct instances of Member, with a field for each feature.
MemberRecord == [
    name: STRING,
    age: Int,
    active: BOOLEAN,
    loans: SUBSET Loan
]

\* The records of the direct instances of Loan, with a field for each feature.
LoanRecord == [
    item: Item,
    member: Member,
    due: Int
]

\* Every object is a record of the values of the features of its class.
TypeOK ==
    /\ DOMAIN obj = Object
    /\ \A o \in LibraryIds : obj[o] \in LibraryRecord
    /\ \A o \in BranchIds : obj[o] \in BranchRecord
    /\ \A o \in BookIds : obj[o] \in BookRecord
    /\ \A o \in PeriodicalIds : obj[o] \in PeriodicalRecord
    /\ \A o \in ReferenceBookIds : obj[o] \in ReferenceBookRecord
    /\ \A o \in MemberIds : obj[o] \in MemberRecord
    /\ \A o \in LoanIds : obj[o] \in LoanRecord

\* The bounds of the number of values of many-valued features.
Multiplicities ==
    /\ \A o \in Member : Cardinality(obj[o].loans) =< 3

\* Opposite references relate the same objects in both directions.
Opposites ==
    /\ \A a \in Branch, b \in Item : (b \in obj[a].holdings) <=> (obj[b].location = a)
    /\ \A a \in Item, b \in Loan : (obj[a].loan = b) <=> (obj[b].item = a)
    /\ \A a \in Loan, b \in Member : (obj[a].member = b) <=> (a \in obj[b].loans)

\* The objects that an object contains directly.
Contents(o) ==
    UNION {
        IF o \in Library THEN obj[o].branches ELSE {},
        IF o \in Library THEN obj[o].members ELSE {},
        IF o \in Library THEN obj[o].items ELSE {},
        IF o \in Member THEN obj[o].loans ELSE {}
    }

\* Every object has at most one container and does not contain itself, directly or not. Below(o, seen) is the set of
\* the objects that o contains, directly or not, apart from those in seen.
Containment ==
    LET RECURSIVE Below(_, _)
        Below(o, seen) ==
            LET next == Contents(o) \ seen
            IN next \cup UNION {Below(x, seen \cup next) : x \in next}
    IN /\ \A o \in Object : Cardinality({c \in Object : o \in Contents(c)}) =< 1
       /\ \A o \in Object : o \notin Below(o, {})

\* The invariant UniqueBranchCodes of Library: self.branches->isUnique(b | b.code)
Inv_Library_UniqueBranchCodes ==
    \A self \in Library : \A b_1, b_2 \in obj[self].branches : (b_1 # b_2) => (obj[b_1].code # obj[b_2].code)

\* The invariant AvailableHasNoLoan of Item: self.status = Status::AVAILABLE implies self.loan->isEmpty()
Inv_Item_AvailableHasNoLoan ==
    \A self \in Item : (obj[self].status = "AVAILABLE") => (obj[self].loan = Null)

\* The invariant ReadingRoomOnly of ReferenceBook: self.status <> Status::ON_LOAN
Inv_ReferenceBook_ReadingRoomOnly ==
    \A self \in ReferenceBook : obj[self].status # "ON_LOAN"

\* The invariant NonNegativeAge of Member: self.age >= 0
Inv_Member_NonNegativeAge ==
    \A self \in Member : obj[self].age >= 0

\* The invariant AgeRestriction of Member: self.loans->forAll(l | l.item.oclIsKindOf(Restricted) implies self.age >= l.item.oclAsType(Restricted).minimumAge)
Inv_Member_AgeRestriction ==
    \A self \in Member : \A l \in obj[self].loans : (obj[l].item \in Restricted) => (obj[self].age >= obj[obj[l].item].minimumAge)

\* The invariant ActiveLoans of Member: self.active or self.loans->isEmpty()
Inv_Member_ActiveLoans ==
    \A self \in Member : (obj[self].active) \/ (obj[self].loans = {})

\* The invariant OnLoanStatus of Loan: self.item.status = Status::ON_LOAN
Inv_Loan_OnLoanStatus ==
    \A self \in Loan : obj[obj[self].item].status = "ON_LOAN"

\* All translated invariants.
Invariants ==
    /\ Inv_Library_UniqueBranchCodes
    /\ Inv_Item_AvailableHasNoLoan
    /\ Inv_ReferenceBook_ReadingRoomOnly
    /\ Inv_Member_NonNegativeAge
    /\ Inv_Member_AgeRestriction
    /\ Inv_Member_ActiveLoans
    /\ Inv_Loan_OnLoanStatus

\* The structure of the metamodel.
WellFormed == TypeOK /\ Multiplicities /\ Opposites /\ Containment

====
