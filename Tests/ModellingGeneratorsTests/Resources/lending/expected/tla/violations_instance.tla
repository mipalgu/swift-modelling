---- MODULE violations_instance ----
\* TLA+ module of a model of the Ecore package lending (http://example.org/lending).
\*
\* The specification Spec has the model as its only state. The configuration of this module fixes the constants of the
\* module lending to the definitions below and lists the invariants for TLC to check: the structural invariants
\* (TypeOK, Multiplicities, Opposites, Containment) hold exactly if the model satisfies the structure of the
\* metamodel, and each translated invariant holds exactly if the model satisfies it. Every object is identified by the
\* name of its class and its position in the model, and values of uninterpreted data types are their text.
EXTENDS lending, TLC

\* The identifiers of the direct instances of each concrete class.
InstanceLibraryIds == {"Library1"}
InstanceBranchIds == {"Branch2", "Branch3"}
InstanceBookIds == {"Book7"}
InstancePeriodicalIds == {"Periodical8"}
InstanceReferenceBookIds == {"ReferenceBook9"}
InstanceMemberIds == {"Member4", "Member6"}
InstanceLoanIds == {"Loan5"}

\* The values of the data type EDouble in the model.
InstanceEDoubleValues == {}

\* The record of every object of the model.
InstanceObj ==
    ("Library1" :> [
        name |-> "Riverside Library",
        branches |-> {"Branch2", "Branch3"},
        members |-> {"Member4", "Member6"},
        items |-> {"Book7", "Periodical8", "ReferenceBook9"}
    ])
    @@ ("Branch2" :> [
        name |-> "Central",
        code |-> 1,
        holdings |-> {"Book7", "ReferenceBook9"}
    ])
    @@ ("Branch3" :> [
        name |-> "Northside",
        code |-> 1,
        holdings |-> {"Periodical8"}
    ])
    @@ ("Member4" :> [
        name |-> "Alex",
        age |-> 34,
        active |-> TRUE,
        loans |-> {"Loan5"}
    ])
    @@ ("Loan5" :> [
        item |-> "ReferenceBook9",
        member |-> "Member4",
        due |-> 14
    ])
    @@ ("Member6" :> [
        name |-> "Sam",
        age |-> 12,
        active |-> FALSE,
        loans |-> {}
    ])
    @@ ("Book7" :> [
        name |-> "A Field Guide to Birds",
        year |-> 2019,
        status |-> "ON_LOAN",
        location |-> "Branch2",
        loan |-> Null,
        pages |-> 320,
        isbn |-> "978-0-00-000000-2",
        rating |-> Null
    ])
    @@ ("Periodical8" :> [
        name |-> "Science Monthly",
        year |-> Null,
        status |-> "ON_LOAN",
        location |-> "Branch3",
        loan |-> Null,
        issue |-> 42
    ])
    @@ ("ReferenceBook9" :> [
        name |-> "Atlas of the World",
        year |-> 2021,
        status |-> "AVAILABLE",
        location |-> "Branch2",
        loan |-> "Loan5",
        pages |-> 200,
        isbn |-> Null,
        rating |-> Null,
        minimumAge |-> 16
    ])

\* The model is the only state.
Init == obj = InstanceObj
Next == UNCHANGED obj
Spec == Init /\ [][Next]_obj

====
