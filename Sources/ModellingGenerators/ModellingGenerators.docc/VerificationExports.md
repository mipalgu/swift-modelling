# Verification Exports

Export metamodels and their models to Alloy 6, TLA+, Event-B and Lean 4.

## Overview

The verification exports turn the structure of a metamodel (classes, inheritance, attributes, references with their multiplicities, containment, opposite references and enumerations) and the invariants that its classes state in OCL into the notation of a formal method, so that the metamodel can be analysed for consistency and a model can be checked for conformance.

Each target is a bundled template set of the same name: `alloy`, `tla`, `eventb` and `lean` (see ``VerificationTarget``). A metamodel is exported like any other language, from an Ecore model or a generator model:

```swift
let result = try await GenerationPipeline.generate(
    inputURL: URL(fileURLWithPath: "model/library.ecore"),
    language: "alloy",
    outputDirectory: URL(fileURLWithPath: "verification"))
```

A model of the metamodel is exported by ``GenerationPipeline/generate(modelURL:metamodelURL:language:outputDirectory:options:progress:)``, which writes files named after the model file:

```swift
let model = try await GenerationPipeline.generate(
    modelURL: URL(fileURLWithPath: "model/branch.xmi"),
    metamodelURL: URL(fileURLWithPath: "model/library.ecore"),
    language: "alloy",
    outputDirectory: URL(fileURLWithPath: "verification"))
```

From the command line, `swift-ecore generate model/library.ecore --language alloy --model model/branch.xmi -o verification` writes both; `--model` can be repeated, and a generator model works as the input as well. A model export reads every feature that the model does not set as undefined, whatever ``GenerationOptions/unsetFeatureReads`` (`--unset-features`) says, so that an unset optional value is absent from the export rather than replaced by its default.

The sets share the queries of the directory `verification`, which has no descriptor and is therefore not a language. Single modules can be replaced with ``GenerationOptions/templatePaths`` (`--template-path`), as for the code generators.

### Template sets and services

MTL handles everything that follows the structure of the metamodel. Two things need Swift, and ``VerificationServices`` offers them to the templates; the generation pipeline registers the services for every template set, and their names all start with `verification`, so they cannot shadow the services of other sets:

- OCL invariants are text inside annotations. Translating them needs a parser, a type checker that resolves navigations against the metamodel, and a printer for each target. The services parse OCL with the AQL parser, check it against the metamodel and print it for a ``VerificationTarget``. Invariants outside the translatable subset are listed, with the reason, in the header of every export.
- Identifiers must agree between the declarations that the templates write and the formulas that the translator prints. ``VerificationTarget`` is the single authority for reserved words, qualification and string literals, and the templates call it through the services that ``VerificationServiceName`` lists.

The main template of a set receives the generator model, as for every other language. A model is exported by the template that the descriptor names in ``TemplateSetDescriptor/modelTemplate``; it receives the root package of the metamodel and the root object of the model, and reads the name of the model file from the global variable `modelName`. ``TemplateSetDescriptor/fileCountTemplate`` and ``TemplateSetDescriptor/modelFileCountTemplate`` count the files of each kind of export, so that progress is reported with a bar.

### The translatable subset of OCL

| OCL | Supported |
| --- | --- |
| `self`, iterator and `let` variables | yes (`let` is inlined) |
| navigation of attributes and references, including through collections | yes |
| Boolean, Integer and String literals, enumeration literals (`Status::ON_LOAN`) | yes (no strings in Event-B) |
| `and`, `or`, `xor`, `implies`, `not`, `=`, `<>`, `<`, `<=`, `>`, `>=` | yes |
| `+`, `-`, `*`, `div`, `mod`, unary `-` | yes |
| `if then else endif` | truth values and integers (truth values only in Event-B) |
| `size`, `isEmpty`, `notEmpty`, `includes`, `excludes` | yes |
| `forAll`, `exists`, `one`, `select`, `reject`, `isUnique` | with one iterator over objects |
| `collect` | of a reference navigation |
| `oclIsKindOf`, `oclAsType`, `oclIsUndefined`, `= null`, `<> null`, `allInstances` | yes |
| Real numbers, `/`, String operations, `oclIsTypeOf`, `sum`, `closure`, `sortedBy`, `iterate`, tuples, ordered collection operations (`first`, `at`), operation calls, `@pre` | no |

Collections are treated as sets in every target. A comparison over an absent value is false in TLA+, Event-B and Lean, as an invariant over an invalid value is not satisfied in OCL; in Alloy an absent integer counts as zero.

Operations and their bodies, derived and volatile features, the order and repetition of the values of many-valued features, the structure of values of data types other than integers, truth values and strings (they become uninterpreted values), generic types, nested packages and references to classes of other packages are never exported. Each export lists what it leaves out of the package in its header.

### Alloy

The `alloy` set writes an Alloy 6 module for each package (`library.als`) and a module for each model (`branch_instance.als`). The mapping follows the relational reading of class diagrams by Jackson (*Software Abstractions*, MIT Press, revised edition 2012), UML2Alloy (Anastasakis, Bordbar, Georg and Ray, MODELS 2007) and Echo (Macedo and Cunha, FASE 2013).

| Ecore | Alloy 6 |
| --- | --- |
| package | `module`, opening `util/boolean` |
| all objects | `abstract sig EObject {}` |
| class | `sig`, `abstract sig` for abstract classes and interfaces |
| first supertype | `extends` |
| further supertypes | fact `C in S`; a class that is a further supertype becomes a subset signature `sig S in EObject`, constrained by a fact to its subclasses if it is abstract |
| attribute of type integer, truth value, string | field of `Int`, `Bool` (`util/boolean`), `String` |
| attribute of an enumeration or another data type | field of the enumeration signature, or of an uninterpreted signature named after the data type |
| reference | field of the target signature |
| multiplicity `1`, `0..1`, `1..*`, `0..*` | `one`, `lone`, `some`, `set`; other bounds become facts |
| containment | function `contents` and facts: at most one container, no object contains itself |
| opposite references | fact `C <: f = ~(D <: g)`, once per pair |
| enumeration | `abstract sig` with a `one sig` per literal (`Status_ON_LOAN`) |
| OCL invariant | `pred` quantified over the class, and an `assert` that states it |
| model object and values | `one sig` atom extending its class, and a fact `Model` that fixes every signature and field |

The metamodel module has a command `instance`, which finds an instance that satisfies all invariants, and a `check` for each invariant, which looks for an instance of the structure that violates it. The model module has a command `conforms`, which has an instance exactly if the model satisfies the multiplicities, opposite references and containment, and a `check` for each invariant, which reports no counterexample exactly if the model satisfies it. Run the commands headless, for example `java -Djava.awt.headless=true -jar org.alloytools.alloy.dist.jar exec -f -t none -o out branch_instance.als`.

Fields are sets, integers are bounded by the bit width and wrap around on overflow, strings are atoms that only support equality, and the values of uninterpreted data types are not fixed by model exports.

### TLA+

The `tla` set writes a TLA+ module for each package (`library.tla`), and a module with a TLC configuration for each model (`branch_instance.tla` and `branch_instance.cfg`). It follows the TLA+ idiom of an object store, a function from identifiers to records (Lamport, *Specifying Systems*, Addison-Wesley 2002), with a type invariant `TypeOK` that states the structure of the metamodel.

| Ecore | TLA+ |
| --- | --- |
| concrete class `C` | `CONSTANTS CIds`, the identifiers of its direct instances |
| any class | `C ==` the union of the identifiers of its concrete conforming classes |
| object state | `VARIABLE obj`, from identifier to record, with `CONSTANT Null` for an absent value |
| enumeration | set of literal strings, such as `Status == {"AVAILABLE", "ON_LOAN"}` |
| data type other than integer, truth value or string | `CONSTANT <Type>Values` |
| features of a concrete class | `CRecord == [f: T, ...]`; `T \cup {Null}` for an optional value and `SUBSET T` for many values |
| structure | `TypeOK`, `Multiplicities`, `Opposites` and `Containment`, combined in `WellFormed` |
| OCL invariant | `Inv_<Class>_<Name>`, combined in `Invariants` |
| model | a module that extends the package module and has the model as its only state, and a configuration that replaces the constants and checks every invariant |

SANY parses the metamodel module; TLC checks a model with its configuration, for example `java -Djava.awt.headless=true -cp tla2tools.jar tlc2.TLC -workers 1 -deadlock -continue -config branch_instance.cfg branch_instance.tla`. With `-continue`, TLC reports every violated invariant.

The export is structural: the store never changes. A behavioural specification, such as one that the TLA+ generation of swift-fsmlib writes for logic-labelled finite state machines, can extend the module of its metamodel and use `TypeOK` and `WellFormed` as invariants of its own variables.

### Event-B

The `eventb` set writes CamilleX text files: a context (`library_ctx.bucx`) and a machine (`library_machine.bumx`) for each package, and an instance context and machine for each model, in the Unicode notation of Rodin. The mapping follows the class-diagram translation of UML-B and iUML-B (Snook and Butler, ACM TOSEM 15(1), 2006; Said, Butler and Snook, SoSyM 14(4), 2015) on Event-B as defined by Abrial (*Modeling in Event-B*, Cambridge University Press, 2010).

| Ecore | Event-B |
| --- | --- |
| all objects | carrier set `OBJECT` in the context |
| enumeration | carrier set with constants `<Enum>_<LITERAL>` and `partition` |
| integer, truth value, string, other data type | `ℤ`, `BOOL`, carrier set `STRING`, carrier set named after the data type |
| class | machine variable, the population of the class, contained in the intersection of its supertypes |
| abstract class or interface | invariant `C =` the union of its direct subclasses |
| required single, optional, many-valued feature | machine variable `C_f ∈ C → T`, `C ⇸ T`, `C ↔ T`, with `card` bounds |
| opposite references and containment | the converse relation, and an acyclic partial function to the container |
| OCL invariant | invariant `@<Class>_<Name>`, with the OCL text as its comment |
| model | an instance context with the objects and strings as constants, and an instance machine whose initialisation fixes every population and value |

The populations of the classes are machine variables, as objects are created and deleted, and so are the features, whose domain is the population of their class. The feasibility proof obligation of the initialisation of a package machine states that the metamodel is consistent, and the invariant preservation obligations of an instance machine together state that the model conforms. To import the files, install CamilleX in Rodin, add the files to an Event-B project and choose "Batch Generation from CamilleX" on the project.

Event-B has no strings, so string literals in invariants are not translated, and features that cannot change are only initialised: the events of a refinement must keep their values.

### Lean

The `lean` set writes a Lean 4 file for each package (`Library.lean`) and a file for each model (`BranchInstance.lean`), using the core library only. Objects are identified by numbers, and every proposition is built from decidable parts, so `decide` checks a model.

| Ecore | Lean 4 |
| --- | --- |
| package | file with `namespace <Package>` |
| enumeration | `inductive` with one constructor per literal, deriving `DecidableEq` and `Repr` |
| concrete class | `structure` with every feature, inherited first |
| required single, optional, many-valued feature | `T`, `Option T`, `List T`, with `ObjectId` for references |
| all objects and class membership | `inductive Obj` with a constructor per concrete class, and `Obj.is<Class> : Obj → Bool` |
| structure | `WellFormed`: multiplicities, reference targets, opposites and acyclic containment |
| OCL invariant | `def <Class>.<Name> (m : Model) : Prop`, combined in `Invariants` |
| model | a file that imports the package file, defines `model` and states a theorem for `WellFormed` and for each invariant, each proved `by decide` |

Compile the package file and check the model file against it, for example `lean -o build/Library.olean Library.lean` and `LEAN_PATH=build lean BranchInstance.lean`. A violated invariant is reported as a theorem that `decide` cannot prove. Integer division and remainder follow Lean, which differs from OCL for negative numbers, and large models may need `decide +kernel` or `native_decide`.

### Checking with the tools

The tests of this package compare every export of a neutral lending metamodel and two of its models with reviewed files. They also run the tools themselves when environment variables name them, so that continuous integration runs these checks only where the tools are installed: `ALLOY_JAR` (the Alloy 6 distribution jar), `TLA2TOOLS_JAR` (SANY and TLC), `EVENTB_AST_JAR` (the Rodin formula library `org.eventb.core.ast`, with `javac`) and `LEAN` (the `lean` executable). Java runs headless.
