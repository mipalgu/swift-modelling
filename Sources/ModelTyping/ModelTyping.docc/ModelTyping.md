# ``ModelTyping``

Decide whether ATL, MTL and AQL modules written against one metamodel can be reused with another.

## Overview

``ModelTyping`` applies structural model typing to the modules of the modelling toolchain. A transformation, a template module or a query is written against particular metamodels; when a metamodel evolves, or a module is to be reused with a related metamodel, the question is whether the module still runs on models of the new metamodel. The library answers it statically, without running the module, by checking whether the new metamodel is a subtype of the one the module was written against.

A metamodel is seen as a ``ModelType``: its classes as object types with their properties, its enumerations and its data types. The ``ReuseChecker`` parses nothing itself; it takes a parsed ATL module, MTL module or AQL expression, extracts its ``Footprint``, the classes, features and enumeration literals that it reads, writes or instantiates, and runs a ``ModelTypeChecker`` that compares the required model types with the provided ones. The result is a ``CompatibilityReport``.

```swift
let module = try await ATLParser(options: .standard).parseContent(source, filename: "Families2Persons.atl")
let required = ["Families": ModelType(packages: [families]), "Persons": ModelType(packages: [persons])]
let provided = ["Families": ModelType(packages: [revisedFamilies]), "Persons": ModelType(packages: [persons])]
let report = ReuseChecker.check(atl: module, required: required, provided: provided)
print(report.formatted())
if !report.compatible {
    let retry = ReuseChecker.check(
        atl: module, required: required, provided: provided,
        options: CheckOptions(renaming: report.suggestedRenaming))
    print(retry.formatted())
}
```

ATL modules are keyed by the metamodel names of their header, such as `Families` in `create OUT : Persons from IN : Families`; the metamodels of source models are checked for what the module reads, those of target models for what it creates and writes. MTL modules and AQL expressions are checked against one metamodel, under a name of the caller's choice, conventionally the package name that qualifies their types; an AQL expression also needs the written types of its free variables, such as `["self": "library::Library"]`.

The same checks are available on the command line as the `check-compat` command of `swift-atl`, `swift-mtl` and `swift-aql`.

### Subtyping modes

A ``SubtypingMode`` chooses the relation that is decided, after [Guy et al. (2012)](https://doi.org/10.1007/978-3-642-31491-9_30):

- ``SubtypingMode/partial`` (the default) considers only the part of the required model type that the module needs, and admits the renamings of the options;
- ``SubtypingMode/partialIsomorphic`` considers the same part, but requires equal names;
- ``SubtypingMode/totalNonIsomorphic`` considers the whole required model type, after renaming;
- ``SubtypingMode/totalIsomorphic`` considers the whole required model type, with equal names.

In every mode the provided metamodel may add classes, optional features and enumerations.

### Matching semantics

The ``MatchingSemantics`` of the ``CheckOptions`` chooses how classes and properties are matched:

- ``MatchingSemantics/accessRefined``, the default, matches each element by how the module uses it: property types and multiplicities are covariant when read, contravariant when written and invariant when both, abstractness matters only for instantiated classes and changeability only for written features. It is an extension of the published definitions, which assume every possible use and would reject provided metamodels that are safe for the uses the footprint records.
- ``MatchingSemantics/objectTypeMatching`` is object type matching as defined by [Steel and Jézéquel (2007)](https://doi.org/10.1007/s10270-006-0036-6).
- ``MatchingSemantics/mofClassMatching`` is MOF class matching as defined by Guy et al. (2012).

### Tuning a check

``CheckOptions`` hold a ``Renaming`` from required to provided names, which applies in the non-isomorphic modes and is written as `Writer=Author` for a classifier or `Book.isbn=ISBN` for a feature or literal (see ``Renaming/init(parsing:)``); whether numeric data types may widen in the direction of use; and whether lower bounds that do not conform are reported as warnings. Widening and lenient lower bounds are extensions of the access-refined semantics. The published definitions do not apply them, even to a feature that a module only reads: they match a property type only by the same type or, for classes, by a subclass, so `EInt` does not match `ELong`, and they assume every possible use of a property. A finding that widening would have resolved under the access-refined semantics says so.

A ``CompatibilityReport`` is `Codable`. In the JSON of a ``MetamodelFootprint``, the classes are an object indexed by class name, the features and literals are arrays of objects that hold the names of the reference beside its ``Usage``, and an ``AccessMode`` is an array of the names of its uses, such as `["read", "write"]`.

### Reading a report

A ``CompatibilityReport`` lists its findings as ``TypingDiagnostic`` values, each with a ``TypingSeverity``, a ``TypingDiagnosticCode``, the ``ElementPath`` of the element concerned and the ``SubtypingRule`` that it follows, whose ``SubtypingRule/citation`` names the definition in the literature or marks the rule as an extension. ``CompatibilityReport/compatible`` is `true` when there is no error. ``CompatibilityReport/isConclusive`` is `false` when the types of some expressions could not be inferred: uses that were guessed for them are checked too, but only reported as warnings, and the footprint lists the ``FootprintUncertainty`` values. A ``RenamingHint`` suggests a renaming for a missing element where a similar provided element exists, and ``CompatibilityReport/suggestedRenaming`` combines the closest hints. ``CompatibilityReport/formatted(includesNotes:)`` renders the report as text, and the report is `Codable`.

### References

- Steel and Jézéquel, [On model typing](https://doi.org/10.1007/s10270-006-0036-6), Software and Systems Modeling 6(4), pp. 401-413, 2007.
- Guy, Combemale, Derrien, Steel and Jézéquel, [On model subtyping](https://doi.org/10.1007/978-3-642-31491-9_30), ECMFA 2012, LNCS 7349, pp. 400-415.
- Jeanneret, Glinz and Baudry, [Estimating footprints of model operations](https://doi.org/10.1145/1985793.1985875), ICSE 2011, pp. 601-610.
- Degueule, Combemale, Blouin, Barais and Jézéquel, [Melange: a meta-language for modular and reusable development of DSLs](https://doi.org/10.1145/2814251.2814252), SLE 2015, pp. 25-36.

## Topics

### Checking Reuse

- ``ReuseChecker``
- ``ModelTypeChecker``
- ``CheckOptions``
- ``SubtypingMode``
- ``MatchingSemantics``
- ``Renaming``
- ``RenamingError``

### Model Types

- ``ModelType``
- ``ObjectType``
- ``PropertyType``
- ``PropertyKind``
- ``PropertyTypeKind``
- ``EnumerationType``
- ``DataTypeDescriptor``
- ``CanonicalDataType``

### Footprints

- ``Footprint``
- ``MetamodelFootprint``
- ``MetamodelBinding``
- ``MetamodelRole``
- ``Usage``
- ``AccessMode``
- ``FeatureReference``
- ``LiteralReference``
- ``FootprintUncertainty``
- ``FootprintUncertaintyKind``
- ``ATLFootprintExtractor``
- ``MTLFootprintExtractor``
- ``AQLFootprintExtractor``
- ``FootprintExtractionError``
- ``WrittenTypeName``

### Reports

- ``CompatibilityReport``
- ``TypingDiagnostic``
- ``TypingDiagnosticCode``
- ``TypingSeverity``
- ``SubtypingRule``
- ``ElementPath``
- ``RenamingHint``
- ``RenamingHintKind``
- ``RenamingHintReason``
- ``NameSimilarity``

### Vocabulary

- ``ModelTypingVocabulary``
