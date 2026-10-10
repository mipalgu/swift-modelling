# Swift Generation

Generate Swift model code for the ECore runtime from a generator model.

## Overview

The bundled `swift` template set writes Swift that compiles against the `ECore` product of swift-ecore. Every class of the model becomes a type that conforms to `EObject`, so the objects take part in the reflective methods, resources and queries of the runtime.

```swift
let result = try await GenerationPipeline.generate(
    inputURL: URL(fileURLWithPath: "model/library.ecore"),
    language: "swift",
    outputDirectory: URL(fileURLWithPath: "Sources/Library"))
```

From the command line, `swift-ecore generate model/library.ecore --output Sources/Library` (Swift is the default language of that command) and `swift-atl generate model/library.ecore --language swift --output Sources/Library` do the same. A generator model works as the input as well; an Ecore model is imported into a temporary generator model first. Add `--model-directory` to write below the model directory of the generator model.

### What is generated

For every package the set writes, below a directory named after the package (nested packages get nested directories):

- one file for each class: a protocol if the class is abstract, an interface or extended by other classes, and a `final class` if it has instances. A class that has both gets its protocol in the file of the class and a final class named with the suffix `Impl`.
- one file for each enumeration, an `enum` with integer raw values that conforms to `Sendable`, `Codable`, `CaseIterable` and `EcoreValue`, so that every literal can be listed through `allCases` and encoded and decoded as its integer value. An enumeration without literals has no raw type and writes its own `Codable` methods, because the compiler cannot synthesise them; decoding always fails. Literals that repeat a value become static constants, and `literalText` and `init?(literalText:)` convert to and from the text of the literals.
- one file for each data type of the model, a type alias of the Swift type that its instance class maps to.
- the package description (`LibraryPackage`), a structure with a shared instance that builds the Ecore package of the model and offers the metaclass of every class as a property (`eBook`), and the factory (`LibraryFactory`) with a creation method for every class that has instances and `create(_:)` for a metaclass.

The names of the description and the factory come from the package prefix of the generator model, as in Java.

### Classes

A class that has instances is a `final class`. The runtime requires model objects to be `Sendable`, which a class can only be when it is final and its stored properties are immutable. The class therefore keeps the values of its features in a private structure that a `Mutex` guards, and every feature is a computed property that reads and writes under the lock. Nothing is `@unchecked`. Because final classes cannot inherit, a class implements the features of its supertypes itself and conforms to their protocols, and the protocols carry the inheritance: `Book: EObject, Named, Lendable`. A reference to a class that is a protocol is written as an existential type, `(any Named)?`.

Models that use inheritance among concrete classes therefore see the protocol where they would see the superclass: a class that other classes extend is declared as a protocol with a final class named `<Name>Impl`, and its factory method returns that class.

### Features

| Model | Swift |
| --- | --- |
| Attribute of a primitive type, or of an enumeration that has literals | A property that always has a value: the default of the model, otherwise zero, `false` or the first literal. |
| Other single-valued attribute | An optional property, `nil` unless the model gives a default. |
| Many-valued feature | An array, empty at first. |
| Reference | An optional property of the class or protocol it points to. A single reference that does not contain its target is held weakly. |
| Opposite references | Setting a single-valued reference updates the opposite: the old target forgets the object and the new target learns of it. The many-valued end of a pair is a plain array. |

Derived, volatile and transient features are stored like all other features, and operations are not generated. The model data types come from the type table of the set: `EString` is `String`, `EInt` is `Int`, `ELong` is `Int64`, `EDate` is `Date`, and a data type that the table does not know is an `any EcoreValue`.

### Names

Names that are Swift keywords (`guard`, `class`, `default`, `in`, `operator`, `repeat`, `where`, and also `Type` and `Protocol`) are written between backticks wherever they name a type, property or case. A feature named `id`, `eClass`, `hash` or another member that `EObject` or the generated code claims gets a trailing underscore (`id_`), and so does a class that would hide a type of the standard library or the runtime (`Date_`, `String_`). Both lists are data in `swift-types.xmi`. All generated types share the module of the generated code, so classes with the same name in different packages of one model need different names.

### Existing files

A Swift file that exists is merged with the generated text. A member whose comment is followed by a `// @generated` line is regenerated, a member marked `// @generated NOT` is kept, and members without the tag are kept, so a hand-written extension of the file stays. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new`. The set offers one layout and so no code styles.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the files of each package.
- `Class.mtl` writes the file of a class, with `ClassQueries.mtl` (supertypes, features, opposites), `ClassFeature.mtl` (protocol requirements and properties) and `ClassReflection.mtl` (the reflective methods).
- `EnumClass.mtl` and `DataTypeFile.mtl` write the files of enumerations and data types.
- `PackageClass.mtl` writes the package description and `FactoryClass.mtl` the factory.
- `SwiftNames.mtl`, `SwiftTypes.mtl`, `SwiftImports.mtl` and `SwiftDocumentation.mtl` hold the naming rules, the mapping of types and default values, the import statements, and documentation comments with string literals. `Header.mtl` writes the comment that opens a file, with the copyright text.
- `TypeMapping.ecore` and `swift-types.xmi` are the data model with the type table and the reserved words.

### Checking the output

The tests compile the generated Swift of every fixture against the `ECore` product with `swift build`, and run a small program that exercises the generated library and keyword models. They run when `swift` is on the search path and a checkout of swift-ecore is available (`SWIFT_ECORE_PACKAGE` names one).
