# swift-ecore

Work with Ecore metamodels and model instances.

## Overview

The `swift-ecore` command-line tool provides comprehensive
utilities for working with Ecore metamodels and model instances
in both XMI and JSON formats. It supports format conversion, the
validation of models against their metamodels and OCL invariants,
the inspection, comparison, measurement and querying of models and
metamodels, the creation
of new models, and the creation of generator models and source code
from Ecore models.

The tool is built on the swift-ecore package
(https://github.com/mipalgu/swift-ecore), which provides a pure
Swift implementation of the Eclipse Modeling Framework
([EMF](https://eclipse.dev/emf/)) Ecore metamodelling framework.

### Features

- **Pure Swift**: No Java or EMF dependencies, Swift 6.0 or later with strict concurrency
- **Cross-Platform**: Full support for macOS, Linux and Windows
- **Value Types**: Sendable structs and enumerations for thread safety
- **BigInt Support**: Arbitrary-precision integers via swift-numerics
- **Complete Metamodel**: `EClass`, `EAttribute`, `EReference`, `EPackage`, `EEnum` and `EDataType`
- **Resource Infrastructure**: Object management and identifier-based reference resolution as in
  the Eclipse Modeling Framework
- **Bidirectional References**: Automatic management of opposite references across resources
- **XMI**: Load `.ecore` metamodels and `.xmi` instance files, and write models to XMI, with full
  round-trip support
- **Dynamic Attribute Parsing**: Arbitrary XML attributes with automatic type inference (integer,
  real, Boolean and string)
- **XPath Reference Resolution**: References within a resource with XPath-style navigation
  (`//@feature.index`)
- **JSON Serialisation**: Load and save JSON models with full round-trip support
- **Generator Models**: Eclipse-compatible `.genmodel` files from Ecore models with `genmodel`,
  driven by a bundled ATL transformation
- **Code Generation**: Java, Swift, C11 and C++20 model code from a generator model or an Ecore
  model with `generate`, driven by the bundled template sets, which follow the Eclipse code
  generator for Java
- **Template Sets**: Languages are directories of templates and data files, so a new language
  needs no Swift code

### Files and Metamodels

`inspect`, `validate`, `compare`, `statistics` and `query` read every format of the format
registry of swift-ecore: models in XMI (`.xmi`), JSON (`.json`) and UML (`.uml`), and metamodels
in Ecore (`.ecore`), JSON, KM3 (`.km3`), EMOF (`.emof`), Emfatic (`.emf`), Xcore (`.xcore`),
OCLinEcore (`.oclinecore`), and the grammar notations ASDL (`.asdl`), Langium (`.langium`), Xtext
(`.xtext`) and SDF3 (`.sdf3`), from which a metamodel is imported. The registry chooses the format
from the extension and the contents of a file: a format that recognises its documents, such as
EMOF or UML, takes precedence over XMI, so an EMOF metamodel saved as `shop.xmi` is read as a
metamodel and a model in an OMG UML namespace as a UML model. A file with any other extension, or
none, is read in the format of its contents, so a model saved as `shop.model` is read as XMI if it
holds XML and as JSON if it holds JSON. A file whose contents are in no format is rejected with an
error that lists the supported formats, such as
`Unsupported format: txt (supported: xmi, json, ecore, ...)`.

A metamodel file may hold several root packages, and may be in any metamodel format, such as an
Ecore, a JSON, a KM3 or an EMOF file, or a grammar.
`--metamodel` registers every root package of the file under its namespace URI, so a model may hold instances of the classes of any of them. As in the
Eclipse Modeling Framework, a root package need not declare a namespace URI or prefix: it is then
loaded with an empty one, so that the other packages of the file can refer to its classifiers, but it
is not registered, and a warning on standard error names the file and the package:

```
warning: Library.ecore: The package 'Types' has no 'nsURI' and is not registered under a namespace
```

The same warning appears when such a metamodel is the file that a command reads. It does not
change the exit status; `validate` reports the missing namespace URI as an error of the constraint
`WellFormedNsURI`, as before.

KM3, the textual metamodel notation of the ATL tool chain, has no namespace URIs. Each root package
of a KM3 metamodel is therefore registered under its name, with a warning, and a model refers to it
by a namespace declaration with that name, such as `xmlns:Library="Library"`. A syntax error in a
KM3 file is reported on standard error as a line that starts with `error:`, with its line and
column, as are the syntax errors of the other textual formats and grammars. When the file with
such an error is the one that `inspect`, `validate`, `compare`, `statistics`, `query` or `convert`
reads, the command then stops with exit status 1 and a final line such as
`Error: Failed to read Arith.asdl: 1 error(s)`; warnings do not change the exit status.
`--km3-primitives <ecore|declared>`, which every command that reads metamodels accepts,
chooses how the data types that a KM3 metamodel declares are read: as the built-in Ecore data types
of the same meaning, such as `EString` for `String` (`ecore`, the default), or as data types of
their own package, as the KM32EMF transformation makes them (`declared`).

Documents in text formats, such as KM3, Emfatic, Xcore, OCLinEcore, Complete OCL, ASDL, Langium,
Xtext, SDF3 and MetaDepth, are read as UTF-8, and a file that is not valid UTF-8 is read as
ISO-8859-1 with a warning on standard error. `--encoding <name>`, which `inspect`, `validate`,
`compare`, `statistics`, `query` and `convert` accept, names the encoding of the file they read, of
the metamodels given with `--metamodel` and of the Complete OCL documents given with `--ocl`, such
as `ISO-8859-1` (alias `latin1`) or `windows-1252`. They are then read in that encoding alone,
without a warning, and a file that is not valid in it is an error. XMI, Ecore, EMOF, UML and JSON
documents are decoded as their own rules prescribe. These commands read no configuration file, so
the option is given on the command line.

A UML class model (`.uml`, or an `.xmi` file in an OMG UML namespace) is also accepted as a
metamodel: `--metamodel garden.uml` registers the Ecore metamodel that it describes, converted as
the Eclipse UML2 tools convert it, and `swift-ecore convert garden.uml garden.ecore` writes that
metamodel. Given as the file that a command reads, a `.uml` file is a UML model.

### Grammar Imports

A metamodel imported from an ASDL, Langium, Xtext or SDF3 grammar is named after the grammar, or
after the file if the grammar declares no name, and receives a namespace URI and prefix derived from
that name. Every command that reads metamodels accepts these options for the import:

- `--package-name <name>` - The name of the package of a grammar that declares no name
- `--ns-uri <uri>` and `--ns-prefix <prefix>` - The namespace URI and prefix of the package
- `--asdl-enumerations <all-nullary|never>` - Whether an ASDL sum type whose constructors all have
  no fields becomes an enumeration (`all-nullary`, the default) or, like every other sum type, an
  abstract class with a subclass for each constructor (`never`)
- `--langium-types <normal|strict>` - Whether the classes of a Langium grammar are inferred from its
  rules (`normal`, the default) or come only from the types and interfaces that it declares
  (`strict`)
- `--sdf3-labels`, `--no-sdf3-labels` - Whether the argument labels of an SDF3 grammar, such as
  `lhs` in `<lhs:Exp>`, name the features of the metamodel (off by default: features are named
  after their sorts, such as `exp1` and `exp2`)

The options do not change metamodels in other formats. Langium, Xtext and SDF3 are only read: a
metamodel imported from them can be written in any other metamodel format.

### Complete OCL

`inspect`, `validate`, `convert`, `compare`, `statistics` and `query` accept `--ocl <file.ocl>`,
which can be given several times. A Complete OCL document adds invariants, pre- and postconditions,
definitions and derivations to classes that a metamodel defines elsewhere. The documents apply,
in command line order, to the metamodels given with `--metamodel` after they are loaded or, without
`--metamodel`, to the metamodel that the command reads. The constraints become OCL annotations of
the metamodel, so `validate` checks the invariants of a document for every object of a model, and
`convert` writes them into a converted metamodel:

```bash
swift-ecore validate shop.xmi --metamodel shop.ecore --ocl pricing.ocl
swift-ecore convert shop.ecore shop-constrained.ecore --ocl pricing.ocl
```

What a document cannot apply, such as a context that no metamodel declares, is reported on standard
error as a line starting with `error:` or `warning:`, and does not change the exit status. A model
without a metamodel to constrain, and a document that does not exist, are errors.

### Multi-level Models

A multi-level model in the MetaDepth notation (`.mdepth`) is a chain of levels, each an instance
of the one above, whose clabjects are at once types and instances, and whose potencies say over
how many levels an element can still be instantiated. `inspect` lists its levels and clabjects,
`validate` checks its structure, its potencies and its constraints, which are written in AQL and
evaluated on the deep instances of the levels that their potencies select, and `convert` writes it
losslessly as XMI or JSON instances of the linguistic metamodel of multi-level models, from which
it converts back to MetaDepth. A JSON or XMI document of such instances is read as the multi-level
model it holds.

`--level-crossing <strict|declared|non-strict>` chooses which references may connect clabjects at
different levels. With `declared`, the default, a reference stays within its level unless it is a
deep reference (`T@0`), a clabject has a leap potency (`@(2)`) or the reference declares its target
level (`{level=1}`). With `strict`, those declared crossings are errors too, and with `non-strict`,
any reference may cross levels:

```bash
swift-ecore validate products.mdepth --level-crossing non-strict
swift-ecore convert products.mdepth products.xmi
swift-ecore convert products.mdepth bookstore.ecore --level 1
```

`convert --level <level>` writes, in any metamodel format, the Ecore metamodel whose instances live
at that level: with `--level 0`, for example, its classes are the types of level 1, with the
features that they and the levels above give them, annotated with their levels and potencies. The
export is one-way, as Ecore cannot hold instances of instances. Without `--level`, a multi-level model
cannot be written in a metamodel format, and the error lists its levels.

`swift-aql` and `swift-mtl generate` present a multi-level model as the deep view of one level with
`--deep-view <level>`, so that queries and templates written for Ecore find the deep instances of
a type at that level.

## Commands

Every command except `info` accepts `-v, --verbose` for detailed output, and every command
accepts `--help`; `swift-ecore <command> --help` describes the options of a command.

### convert

Convert models between XMI, JSON and UML, and metamodels between the metamodel formats.

```bash
swift-ecore convert <input-file> <output-file> [options]
swift-ecore convert <input-file> --output <output-file> [options]
```

**Options:**

- `-o, --output <file>` - The output file, instead of the second argument
- `--validate` - Check the model or metamodel as `validate` does, and write nothing if it has an
  error
- `--input-format <format>` - Input format, such as `xmi`, `json`, `ecore`, `km3`, `emof` or
  `asdl` (chosen from the extension and the contents of the file, as for the other commands, if
  not specified, so a Stratego signature in a `.str` file is recognised by its contents)
- `--output-format <format>` - Output format, one of the formats that can be written (inferred
  from the extension if not specified)
- `-m, --metamodel <file.ecore>` - A metamodel of the model, in any metamodel format (can be given
  several times)
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--km3-primitives <ecore|declared>` - How the data types of a KM3 metamodel are read (default
  `ecore`; see Files and Metamodels above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (default: UTF-8, and ISO-8859-1 with a warning for a file that is not valid UTF-8;
  see Files and Metamodels above)
- `--package-name`, `--ns-uri`, `--ns-prefix`, `--asdl-enumerations`, `--langium-types`,
  `--sdf3-labels` - How a metamodel is imported from a grammar (see Grammar Imports above)
- `--level <level>` - Write the Ecore metamodel whose instances live at this level of a
  multi-level model (see Multi-level Models above)
- `--level-crossing <strict|declared|non-strict>` - Which references of a multi-level model may cross
  levels when `--validate` checks it (default `declared`)
- `--reference-style <encoded|plain>` - How an XMI output spells references into itself
  (default `encoded`)
- `--force` - Overwrite the output file if it exists
- `-v, --verbose` - Show progress

JSON is written indented, with the keys of every object in alphabetical order.
With a metamodel, the model is read with the classes and data types the metamodel defines,
and JSON is written with package-qualified classes (`"eClass": "<nsURI>#//<Class>"`) and
non-containment references as `{"$ref": "<fragment>"}` entries. Without one, the classes are
inferred from the document. With the metamodel of the model, conversions between XMI and JSON
keep cross-references, containment relationships and all data types. When JSON is loaded, classes
and references are resolved against the metamodels in use, here as well as in
`swift-mtl generate --model model.json`.

Whatever the conversion cannot keep, such as a class that no metamodel defines or a reference
that cannot be written as a fragment, is reported once on standard error as a line starting
with `warning:`. Without `--metamodel`, the warnings of converting a model are followed by a
`hint:` line suggesting it. Warnings do not change the exit status, and the completion message
stays on standard output. An error of reading the input, such as a syntax error of a grammar, is
reported as a line starting with `error:` and stops the conversion with exit status 1, and
nothing is written.

A metamodel (`.ecore`) is written as a JSON metamodel, in which every object names its Ecore
metaclass in `eClass`, contained elements are nested, and references are `{"$ref": ...}` objects
with the name-based fragments of Ecore (`//Book/author`). A JSON file whose roots are Ecore
packages is read as a metamodel, whatever its name, and can be written as `.ecore`. Enumerations,
opposites, supertypes, annotations and every other construct of the metamodel are kept. A
metamodel can also be read from and written as KM3 (`.km3`); what KM3 cannot express, such as
annotations and default values, is reported on standard error as a warning when a metamodel is
written as KM3, and namespace URIs are not written. A metamodel can be written in every metamodel
format that swift-ecore writes: Ecore, JSON, KM3, EMOF, Emfatic, Xcore, OCLinEcore and ASDL. A model
is written as XMI, JSON or UML; a `.uml` output is written in the layout of Eclipse UML2. A metamodel
cannot be written as an XMI model, nor a model as `.ecore` or `.km3`, and no document can be written
as Langium, Xtext or SDF3, which are only read: the command fails with an error that lists the
formats that suit the input, such as
`convert it to one of: ecore, json, km3, emof, emf (Emfatic), xcore, oclinecore, asdl`, and writes
nothing.

References to other metamodel files keep their file names. A `shop.json` converted from a
`shop.ecore` whose classes extend classes of `base.ecore` still refers to `base.ecore#//Named`,
and `shop.ecore` converted back from it does too; `swift-ecore` reads such references in either
format, so the converted file works as long as the file it refers to stays beside it. To convert
a set of metamodels that refer to each other, convert every file into the same directory, then
replace the extension in the references of the converted files, as in the last example below.

With `--reference-style encoded`, the default, an XMI output keeps its usual layout, and a
reference to an object of the same document keeps the leading `#` of its fragment
(`#//@classifiers.0`). With `plain`, the output is written in the layout of the Eclipse Modeling
Framework, with references as attribute values holding the fragment alone
(`type="cls:DataType //@classifiers.0"`), as Eclipse writes XMI model files. Both styles load
again.

**Examples:**

```bash
# Convert XMI to JSON
swift-ecore convert model.xmi model.json

# Convert with the metamodel, so classes and references are typed
swift-ecore convert model.xmi model.json --metamodel MyMetamodel.ecore

# Convert with explicit formats
swift-ecore convert data.txt result.xmi --input-format json --output-format xmi

# Write XMI whose same-document references match the files Eclipse writes
swift-ecore convert model.json model.xmi --metamodel MyMetamodel.ecore --reference-style plain

# Convert a metamodel to JSON and back
swift-ecore convert shop.ecore shop.json
swift-ecore convert shop.json shop-copy.ecore

# Convert a set of metamodels, then make shop.json refer to base.json instead of base.ecore
swift-ecore convert base.ecore base.json
swift-ecore convert shop.ecore shop.json
sed -i.bak 's/base\.ecore#/base.json#/g' shop.json
```

### validate

Validate a metamodel, or a model against its metamodels.

```bash
swift-ecore validate <file>... [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - A metamodel of the model, in any metamodel format (can be given
  several times)
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (see Files and Metamodels above)
- `--level-crossing <strict|declared|non-strict>` - Which references of a multi-level model may cross
  levels (default `declared`; see Multi-level Models above)
- `--check-abstract-classes` - For a metamodel, list every abstract class and interface with the
  concrete classes that extend it, and warn about one that none extends; for a model, confirm
  that no object is an instance of one
- `--strict` - Fail on warnings as well as on errors
- `--require-explicit-values` - Report every required single-valued feature that the model
  leaves unset, even when it reads as a default; unlike the Eclipse Modeling Framework, and
  unrelated to `--strict`
- `--strict-aql` - Evaluate the OCL invariants as strictly as Eclipse AQL: a union of a sequence with
  a set, or a single value passed to `concat`, `sub` or `union`, is a type error instead of being
  accepted; unrelated to `--strict`. `validate` reads no configuration file, so only this flag
  turns it on
- `--format <text|json>` - The format of the report (default `text`)
- `--report <file>` - Write the report to a file instead of standard output
- `-v, --verbose` - Show the root objects that were read, and every satisfied OCL invariant

The supported formats are XMI (`.xmi`), JSON (`.json`) and Ecore (`.ecore`); a file with another
extension is read in the format of its contents. A metamodel (`.ecore`)
is checked against the constraints of Ecore, such as well-formed names,
consistent bounds and opposites, and acyclic inheritance. A model is checked for references into
other documents that name no object. A reference into a document of the Eclipse platform, written
with a `pathmap:` URI, such as a UML profile that is not available, is reported as a warning
instead, as it cannot be checked; the UML primitive types of Eclipse UML2 are available, so
references to them are checked. With a metamodel, a model is also checked against it: every
class and feature must be defined by the metamodel, values must fit the types and bounds of their
features, references must lead to objects of the right class, no object may be an instance of an
abstract class or an interface, and every OCL invariant of the metamodel must hold. A JSON model is
rejected if a value cannot be read by the data type of its attribute, or if a class is not defined
by any of the metamodels.

Multiplicities are checked as the Eclipse Modeling Framework checks them. Each element of a
many-valued feature counts as one value, and so does a single value that a many-valued feature
holds without a list. A required single-valued feature that the model leaves unset is accepted
when it reads as a default: the first literal of an enumeration, `false`, zero, or the default
value of the feature. It is an error when the feature has no default, such as a string or a
reference, or when it is unsettable, which distinguishes being unset from holding its default.
Only the values that a model sets are checked against the types of their features.

`--require-explicit-values` is stricter than the Eclipse Modeling Framework: every required
single-valued feature that the model leaves unset is an error, whatever its type. This suits
models written by hand or migrated from another format, where an omitted value is more likely a
mistake than a deliberate default. Models that the Eclipse Modeling Framework saves leave out
values that equal the default of a feature, so they may fail this check although Eclipse accepts
them.

```bash
# Report the status of an order that the model leaves unset, although it reads as the first literal
swift-ecore validate orders.xmi -m Orders.ecore --require-explicit-values
```

Every problem is printed as a line starting with `error:`, `warning:` or `information:`, with the
element and its location in the model, such as `//@employees.0`. A violated OCL invariant is
printed as a line starting with `Checking constraint:`, followed by the number of satisfied
checks. An invariant declared with a message, such as
`invariant PositiveCapacity('Course ' + code + ' needs places'): capacity > 0` in OCLinEcore or
the same form after `inv` in Complete OCL, is checked by its status, and the line of a violation
ends with the message, evaluated for the object that violates it, as in
`Checking constraint: PositiveCapacity (Course 'Painting', //@courses.1) ... violated: Course ART101 needs places`.
The command prints `Validation completed successfully` and exits with status 0 if there
is no error (and, with `--strict`, no warning); otherwise it fails with status 1 and a summary on
standard error.

Several files are validated one after the other with the same metamodels and options. The
findings of each file follow a line `Validating: <file>` and precede a line with its result, such
as `second.xmi: valid` or `third.xmi: invalid (2 error(s), 0 warning(s))`; a file that cannot be
read counts as invalid, with the reason as its error. A final line such as
`Validated 3 files: 2 valid, 1 invalid` counts the results, and the command fails with status 1 if
any file is invalid, naming the invalid files on standard error. With `--format json`, the report
is an array with one report per file.

OCL invariants are declared as in the Eclipse Modeling Framework: the `constraints` detail of the
annotation with the source `http://www.eclipse.org/emf/2002/Ecore` names them, and the details of
the annotation with the source `http://www.eclipse.org/emf/2002/Ecore/OCL` give their expressions.
Each invariant, whether the metamodel declares it or a Complete OCL document adds it, is translated
from OCL into AQL and then evaluated, so that the constructs whose meaning differs between the two
languages keep their OCL meaning: an explicit `self` inside an iteration still names the object
being checked, the division of two integers is a real division (`7 / 2` is `3.5`), an enumeration
literal may be written as `AccountType::SAVINGS` without its package, and `->forAll` and
`->exists` may declare several iterators. Implicit iterators such as
`self.accounts->isUnique(number)` and `String::indexOf` work as before. An invariant that uses a
construct without a counterpart in AQL, such as `iterate`, tuples or `@pre`, is not evaluated: it
is reported as `untranslated`, with the construct, and counts as a warning, so it fails validation
only with `--strict`. Text that is not OCL is evaluated as AQL, as before.

**Examples:**

```bash
# Check that a model can be read
swift-ecore validate model.xmi

# Validate a model against its metamodel and its OCL invariants
swift-ecore validate model.json --metamodel MyMetamodel.ecore

# Check the abstract classes of a metamodel, failing on warnings
swift-ecore validate MyMetamodel.ecore --check-abstract-classes --strict

# Keep a JSON report for a build server
swift-ecore validate model.xmi --metamodel MyMetamodel.ecore --format json --report report.json

# Validate every model of a directory against the same metamodel
swift-ecore validate models/*.xmi --metamodel MyMetamodel.ecore
```

### inspect

Show the structure of a metamodel or a model.

```bash
swift-ecore inspect <file> [options]
```

**Options:**

- `--detail <summary|full>` - How much to show (default `summary`)
- `--show-supertypes` - Show all supertypes, subclasses and inherited features of every class, and
  the class hierarchy
- `--show-references` - Show the references of every class and the reference graph; for a model,
  every reference between its objects
- `--show-attributes` - Show the attributes of every class, also in a summary
- `--format <text|json>` - The format of the report (default `text`)
- `-o, --output <file>` - Write the report to a file instead of standard output
- `-m, --metamodel <file.ecore>` - A metamodel of the model, in any metamodel format (can be given
  several times)
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (see Files and Metamodels above)
- `--level-crossing <strict|declared|non-strict>` - Which references of a multi-level model may cross
  levels (default `declared`; see Multi-level Models above)
- `-v, --verbose` - Show progress

A metamodel is shown package by package. The summary lists the classes (with their supertypes and
whether they are abstract or interfaces), enumerations and data types; in full detail, every class
lists its attributes and references with their types, multiplicities, default values, containment
and opposites, its operations and its OCL invariants, and every enumeration its literals. A model is
shown with the number of objects of each class; in full detail, every object is shown with its
values and its location, nested as the objects contain each other.

**Examples:**

```bash
# Every class with its features, the inheritance and the references
swift-ecore inspect Company.ecore --detail full --show-supertypes --show-references

# Every object of a model
swift-ecore inspect company.json --metamodel Company.ecore --detail full

# The structure of a metamodel as JSON
swift-ecore inspect Company.ecore --detail full --format json --output structure.json
```

### compare

Compare two metamodels or two models and report their differences.

```bash
swift-ecore compare <original> <revised> [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - A metamodel of both models, in any metamodel format (can be given
  several times)
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (see Files and Metamodels above)
- `--summary` - Show the numbers of objects of each class, or of metamodel elements, in both files
  instead of every difference
- `--ignore <name>` - Leave out a feature, metamodel element or property of that name, or one
  feature of one class as `Class.feature` (can be given several times)
- `--format <text|json>` - The format of the report (default `text`)
- `-o, --output <file>` - Write the report to a file and print only its summary line
- `--exit-code` - Exit with status 1 if the files differ
- `-v, --verbose` - Show the files and how many objects were matched

Both files must be metamodels, or both models. Two metamodels are compared package by package:
packages, classifiers, features, operations and enumeration literals are matched by name, and a
metamodel with a single root package is compared with the single root package of the other even if
it was renamed. Added and removed elements are reported, as are changes of namespace URIs and
prefixes, of the kind of a classifier or feature, of abstract and interface flags, supertypes,
feature types, multiplicities, containment, opposites, the `id`, `derived`, `transient`,
`read-only`, `ordered`, `unique`, `volatile` and `unsettable` flags of features, the
`resolve proxies` flag of references, default values, literal values, operation signatures and
data type instance classes.

Two models are compared object by object. Objects are matched by class and identity: the value of
the identifying attribute of their class, else the value that names them (such as `name`), else
their location; a weaker identity never matches two objects that both have a stronger one. Added
and removed objects are reported with their location, and for matched objects every changed
attribute value and non-containment reference, with referenced objects described by their labels.
Every given metamodel is registered for both models, so a legacy model and its migrated
counterpart can be compared with the metamodels of both. Without a metamodel, an XMI model and a
JSON model name the classes of their objects differently, so the same objects may be reported as
removed and added; a warning on standard error then suggests giving the metamodel with
`--metamodel`.

Each difference is a line that starts with `+` (added), `-` (removed) or `~` (changed), such as
`~ attribute Order.status type: EString -> Status` or
`~ object Order 'A-1' (//@orders.0) status: "PAID" -> "SHIPPED"`, and a summary line such as
`6 differences: 1 added, 1 removed, 4 changed` or `No differences` ends the report. The command
exits with status 0 whether or not the files differ, unless `--exit-code` is given.

For two versions of a small shop model, the report reads:

```text
Comparing models: shop-v1.xmi -> shop-v1-revised.xmi
~ object Customer 'Grace' (//@customers.1) email: "grace@example.org" -> "grace@example.com"
~ object Customer 'Grace' (//@customers.1) orders: [] -> [Order 'A-3']
~ object Order 'A-1' (//@orders.0) status: "PAID" -> "SHIPPED"
~ object Item 'Milk' (//@orders.0/@items.1) quantity: 1 -> 3
- object Order 'A-2' (//@orders.1)
+ object Order 'A-3' (//@orders.1)
6 differences: 1 added, 1 removed, 4 changed
```

Metamodel differences read the same way, for example `+ class Product: extends NamedElement`.

**Examples:**

```bash
# What changed between two versions of a metamodel
swift-ecore compare legacy.ecore improved.ecore

# Whether a migration kept every object: the objects of each class in both models
swift-ecore compare legacy.xmi migrated.xmi --metamodel legacy.ecore --metamodel improved.ecore --summary

# Leave out one feature everywhere, and one feature of one class
swift-ecore compare before.xmi after.xmi --metamodel schema.ecore --ignore modified --ignore Order.note

# Fail a build if a regenerated model differs from the expected one
swift-ecore compare expected.xmi actual.xmi --metamodel schema.ecore --ignore modified --exit-code
```

### statistics

Measure the size and shape of a metamodel or a model.

```bash
swift-ecore statistics <file> [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - A metamodel of the model, in any metamodel format (can be given
  several times)
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (see Files and Metamodels above)
- `--format <text|json>` - The format of the report (default `text`)
- `-o, --output <file>` - Write the report to a file instead of standard output
- `-v, --verbose` - Show progress

A metamodel is measured by the numbers of its packages, classes (abstract ones and interfaces
counted separately), enumerations and literals, data types, attributes, references (containment
references, and bidirectional pairs counted once), operations and OCL invariants, its deepest
inheritance, the largest number of direct subclasses of a class, and the average and largest
number of features per class, declared and with the inherited ones. The classes are then listed by
their number of features, the most first.

A model is measured by the numbers of its objects, root objects and instantiated classes, the
objects of each class, its deepest containment, and the numbers of attribute values, containment
links and cross-references, including those into other documents and those that cannot be
resolved. With a metamodel, the concrete classes that have no objects are listed too.

**Examples:**

```bash
# The measurements of a metamodel
swift-ecore statistics Company.ecore

# The measurements of a model as JSON
swift-ecore statistics company.xmi --metamodel Company.ecore --format json --output statistics.json
```

### create

Create a model with one root object of a class of a metamodel.

```bash
swift-ecore create --metamodel <file.ecore> --root-class <class> --output <file> [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - The metamodel that defines the class (can be given several times)
- `--root-class <class>` - The class of the root object; it must not be abstract or an interface
- `-o, --output <file>` - The model file to write
- `--output-format <xmi|json|uml>` - The output format (inferred from the extension if not
  specified); a metamodel format is rejected
- `--force` - Overwrite the output file if it exists
- `-v, --verbose` - Show progress

**Example:**

```bash
swift-ecore create --metamodel Company.ecore --root-class Company --output company.xmi
```

### genmodel

Create a generator model from Ecore models.

```bash
swift-ecore genmodel <model.ecore>... [options]
```

The generator model is written in the layout that the Eclipse Modeling Framework uses and carries the settings that the Ecore importer gives a freshly imported model. It is written beside the first Ecore model, named after it, unless `--output` says otherwise.

**Options:**

- `--base-package <name>` - Base package of the root packages; optional, but best practice for
  languages such as Java that organise their packages hierarchically
- `--prefix <name>` - Prefix of the root package, or `package=name` for one package (repeatable)
- `--model-project <name>` - Name of the model project
- `--model-plugin-id <id>` - Plug-in identifier of the model project
- `--model-directory <path>` - Source directory of the model project
- `--copyright <text>` - Copyright text
- `--jdk-level <level>` - Compliance level of the generated code (default: 17.0; any level the generator model supports)
- `--defaults headless|wizard` - Preset of the settings that the Eclipse tools write differently for headless and interactive use (default: `headless`)
- `--root-extends-class <name>` - Class that generated root objects extend, overriding the preset
- `--operation-reflection` / `--no-operation-reflection` - Whether generated models include operation reflection, overriding the preset
- `--import-organizing` / `--no-import-organizing` - Whether generated code organises its imports, overriding the preset
- `--unset-features <defaults|undefined>` - How the import transformation reads features that the Ecore model does not set, as for `swift-atl transform`
- `--reload <path>` - Existing generator model whose settings are kept
- `-o, --output <path>` - Generator model to write (default: beside the first Ecore model, named after it)
- `-v, --verbose` - Show progress and a summary

A new generator model gets the settings of the Ecore importer: the importer identifier, compliance level `17.0`, model directory `/<project>/src`, a model plug-in identifier derived from the project, the model name taken from the generator model file, and no copyright fields. Each package gets a prefix (its name with the first letter in upper case unless given), disposable provider factories, the XML resource kind when it uses extended metadata, and the load-initialisation settings that suit its size. Classes, features, enumerations, data types, operations and parameters get the settings that the importer derives from the Ecore model. References to the Ecore model are written in the layout Eclipse uses, for example `ecoreFeature="ecore:EAttribute library.ecore#//Book/title"`.

Several Ecore models can be given; each contributes its root packages to one generator model, which refers to the models by relative paths.

The model project is the `--model-project` option if given. Otherwise it is the parent directory of an Ecore model that lives in a directory named `model`, and the name of the root package in any other case.

Operation reflection, the root class and import organising follow the headless generator of the Eclipse tools (`org.eclipse.emf.codegen.ecore.Generator -ecore2GenModel`) by default: they keep the defaults of the generator metamodel (no operation reflection, `org.eclipse.emf.ecore.impl.EObjectImpl` as the root class, no import organising), so none of the three is written. `--defaults wizard` gives the settings that the interactive New EMF Generator Model wizard writes: `operationReflection="true"`, `rootExtendsClass="org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"` and `importOrganizing="true"`. `--root-extends-class`, `--operation-reflection` and `--import-organizing` (or their `--no-` forms) override single settings of either preset, whatever their order on the command line. The presets are defined in the bundled transformation `Ecore2GenModel.atl` (its `defaults` parameter and its `...Override` parameters), so a replacement transformation can define its own. The same options exist on `generate` (for an Ecore model given for a template language) and on `swift-atl generate`; they do not apply to a generator model that is generated from directly.

When `--reload` names an existing generator model, its settings are kept for every element that still exists, matched by name. New Ecore elements get the defaults, removed ones are dropped, and options given on the command line override the existing settings. The compliance level is kept unless `--jdk-level` is given, and the three settings of the preset are kept too, unless `--defaults` or one of their own options is given.

**Examples:**

```bash
# Write library.genmodel beside the Ecore model
swift-ecore genmodel model/library.ecore --base-package org.example

# Set the prefix of one nested package and the compliance level
swift-ecore genmodel model/company.ecore --prefix projects=Proj --jdk-level 21.0

# Follow changes to the Ecore model but keep the existing settings
swift-ecore genmodel model/library.ecore --reload model/library.genmodel
```

### generate

Generate source code from models.

```bash
swift-ecore generate <model> [options]
```

Every language has a template set (`c`, `cpp`, `java` and `swift` are bundled, and so are the verification targets `alloy`, `tla`, `eventb` and `lean`) and is generated from a generator model (`.genmodel`); an Ecore model is imported into a temporary generator model first. A template set is a directory of templates and data files, so a new language needs no Swift code; see the `ModellingGenerators` documentation. The help (`swift-ecore generate --help`) lists the bundled template set languages, and the verification targets apart from them; a language that `--template-path` adds is accepted but not listed there, and an unknown language is reported with every language that can be used, the languages of code first, including those additions. `swift-atl generate` runs the same pipeline from the ATL tool.

**Options:**

- `-l, --language <name>` - the name of a template set, such as `swift`, `java`, `c` or `cpp`, or a verification target, `alloy`, `tla`, `eventb` or `lean` (default: `swift`)
- `--model <file.xmi>` - A model of the input metamodel to export as well, named after the model file (repeatable); only for template sets that export models, such as the verification targets, and checked before anything is written
- `-o, --output <path>` - Directory to write below (default: the current directory)
- `--template-path <path>` - Directory with template files that replace bundled templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new`
- `--model-directory` - Write below the model directory of the generator model
- `--code-style <style>` - The layout of the generated text, one of the styles of the template set (`java`: `eclipse`, the default, or `emf`); rejected for sets that offer none, such as `swift`, `c` and `cpp`
- `--defaults`, `--root-extends-class`, `--operation-reflection`, `--import-organizing` - The generator model defaults of an Ecore model that is imported for a template language, as for `genmodel`
- `--unset-features <defaults|undefined>` - How the import transformation and the templates read features that a model does not set, as for `swift-mtl generate`
- `--let-type-mismatches <error|skip>` - Whether a typed `let` in the templates whose value does not conform to the declared type stops the generation (`error`, the default) or is skipped with a warning on standard error (`skip`, as in Acceleo 3)
- `--block-line-breaks <acceleo|kept>`, `--collection-parameters <conforming|exact>`, `--check-let-types` / `--no-check-let-types`, `--cache-containers` / `--no-cache-containers`, `--collection-arguments <whole|first-element>`, `--collection-kinds <distinguished|sequences>`, `--single-value-collections <set|sequence>`, `--container-lookup <resources|registered-objects>`, `--sequence-union <concatenation|distinct>`, `--null-addition <empty-text|null>`, `--text-form <joined|bracketed>`, `--dot-calls <each-element|collection>` - The behaviours of the templates, as for `swift-mtl generate`; the first value is the default, and the second that of version 0.6
- `--strict-aql` / `--no-strict-aql` - Whether the expressions of the templates reject what Eclipse AQL rejects, as for `swift-mtl generate`; neither preset sets it
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`) for every behaviour option above; a behaviour option that is given overrides it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the templates and the modules they import, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8, naming the template by its path within the template set); the `encoding` key of the configuration file names it too, and a template that is not valid in the encoding given is an error
- `-v, --verbose` - Show every progress report; without it a progress bar appears on an interactive terminal

**Languages.** The bundled template sets write:

- `swift` - Swift model code for the ECore runtime: one file for every class, enumeration and data type, and a package description and a factory for every package, below a directory for each package. A class that is abstract, an interface or extended by other classes is a protocol; a class with instances is a `final class` that keeps its values under a lock, so that it is sendable without `@unchecked`. Names that are Swift keywords, such as `guard`, `Type` or `default`, are quoted with backticks. Generated files import `ECore` and `EMFBase` and compile against the `ECore` product of swift-ecore.
- `java` - Java model code for the Eclipse Modeling Framework runtime, following the output of the Eclipse code generator for the default options, including its `@generated` tags, so that files can be merged with hand-written code and, where the Eclipse tooling is in use, with Eclipse's own output.
- `c` - A C11 model API: a header and a source file for each package, a `struct` for each class that has instances, with `Class_create` and `Class_destroy` and typed accessors, an `enum` for each enumeration, descriptors with the class and feature names for reflection, and the support header `EObject.h`. Containment references own their targets. Compile the output with `cc -std=c11 -I c-src`, with the output directory as the include path.
- `cpp` - A header-only C++20 model API: a class for each class that has instances (an abstract base class for each abstract class or interface), an `enum class` for each enumeration, `std::vector` for many-valued features, `std::shared_ptr` for containment and `std::weak_ptr` for other references, a factory and a package description for each package, and the support header `EObject.hpp`. Compile with `c++ -std=c++20 -I cpp-src`.

**Verification targets.** The verification sets write the metamodel, with the OCL invariants of its classes, in the notation of a formal method, and each model given with `--model` as a file that the tools of the method check against it:

- `alloy` - An Alloy 6 module for each package, with a command that finds an instance and a check for each invariant, and a module for each model with a command `conforms` and a check for each invariant.
- `tla` - A TLA+ module for each package with `TypeOK`, the structural invariants and the translated invariants, and for each model a module and a TLC configuration that check the model as the only state.
- `eventb` - A CamilleX context and machine for each package and for each model, for import into Rodin, where the proof obligations of the instance machine state that the model conforms.
- `lean` - A Lean 4 file for each package with decidable propositions for well-formedness and each invariant, and a file for each model whose theorems are proved `by decide`.

A model export reads features that the model does not set as undefined, whatever `--unset-features` says, so that an unset optional value is absent from the export. The Verification Exports article of the [ModellingGenerators documentation](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/index.html) describes the mappings, the translatable subset of OCL and how to run the tools.

In the `c` and `cpp` sets, names that are keywords of the language, or that would hide a standard type or a generated name, get a trailing underscore, and documentation comes from the model as Doxygen comments. The Swift Generation, Java Generation, C Generation and C++ Generation articles of the [ModellingGenerators documentation](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/index.html) describe each set in detail, and [Converting Ecore to GenModel and Java](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/convertingecoretojava/index.html) walks through the Java route.

**Java coverage.** The Java template set writes the package interface and implementation (with loaded initialisation, the literals interface, operation reflection, nested packages and annotations; no generic metamodels), the factory interface and implementation, the XML processor and the resource factory and resource of packages that ask for them, the validator (for packages with constraints), the interface (unless the class names an existing Java interface) and implementation class (unless the class is an interface) of every class, one file for every enumeration (the full `EnumClass` template for compliance level 5.0 and higher, with `typeSafeEnumCompatible` honoured), the switch and adapter factory, and, when the output location includes the source directory, the plugin class, plugin properties, build properties, bundle manifest and plugin descriptor of the model project. The `Class` template covers fields, default value constants, accessors with notification, containment and bidirectional references with their inverse methods, many-valued features with the list classes the Eclipse generator chooses, unsettable features, Boolean flags (`booleanFlagsField`), group delegation to feature maps, map features and map entry classes, operations with bodies from the `body` annotation, `eGet`, `eSet`, `eUnset` and `eIsSet`, `eBaseStructuralFeatureID`, `eInvoke` (`operationReflection`), minimal or complete reflective methods, and `toString`. It does not cover generic type parameters, compliance levels below 5.0, reflective, dynamic or virtual feature delegation, array accessors, packed enumeration flags, setting delegates, invariant operations with validation delegates, `suppressInterfaces` and the Google Web Toolkit platform. [Matching Eclipse](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/matchingeclipse/index.html) describes the code styles, the imports and every difference from the Eclipse generator.

**Checking the Java output.** Two optional checks of the test suite of the swift-modelling repository run when their environment variable is set. `EMF_REFERENCE_ROOT` names a checkout of the Eclipse Modeling Framework; the generated enumeration, interfaces and implementation classes of its extended library example are then compared with the committed sources (`EMFJavaClassParityTests` lists the differences caused by manual edits of those sources). `EMF_RUNTIME_CLASSPATH` names the EMF runtime jars; the generated Java is then compiled with `javac`. `Scripts/fetch-emf-runtime.sh [directory]` downloads the jars from Maven Central and prints the class path:

```bash
export EMF_RUNTIME_CLASSPATH="$(Scripts/fetch-emf-runtime.sh)"
swift test --filter JavaCompileTests
```

**Template sets.** A template set is a directory named after a language, containing a descriptor (`templateset.json`), Model-to-Text modules and optional data models. The bundled sets live in `Sources/ModellingGenerators/Templates/<language>/` of the swift-modelling repository. The descriptor names the main module and template, and can declare progress totals, output layout and code styles. Language rules live in the templates and data; the Swift libraries provide the engines, generator model, services and pipeline. To try another language, put its directory below `my-templates` and pass that directory to the generator:

```text
my-templates/
    outline/
        templateset.json
        main.mtl
```

```bash
swift-ecore generate --language outline model/library.genmodel -o out --template-path my-templates
```

A file in a template path replaces the bundled file of the same relative name, and later paths take precedence, so individual modules can be customised without copying the whole set. A set can share modules with other sets: the optional `imports` list of its descriptor names directories relative to the set, such as `"imports": ["../expressions"]`, and a module of the set then imports `expressions/c.mtl` as `[import expressions::c/]`. `swift-mtl generate --template-set <directory|language>` runs any template set on the models given with `--model`. The [Template Sets article](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/templatesets/index.html) is the reference for descriptors, code styles, merge declarations, data models and services.

Existing files are merged with the generated code: members tagged `@generated` are regenerated, members tagged `@generated NOT` and members without the tag are kept. The tag stands in a comment of its own above the member, `// @generated` in Swift files.

**Examples:**

```bash
# Generate Swift from an Ecore model (the default language)
swift-ecore generate model/library.ecore --output Sources/Library

# Generate Java from a generator model
swift-ecore generate --language java model/library.genmodel --output src-gen

# Customise one template and keep a copy of what would change in existing files
swift-ecore generate --language java model/library.genmodel -o src-gen \
    --template-path my-templates --diff

# Export a metamodel and two of its models to Alloy, for the Alloy Analyzer
swift-ecore generate model/library.ecore --language alloy \
    --model model/branch.xmi --model model/archive.xmi -o verification
```

### info

Show the version of the tool and its main commands.

```bash
swift-ecore info
```

The command takes no options. `swift-ecore --version` prints the version alone.

### query

Query the whole of a model or a metamodel.

```bash
swift-ecore query <file> [options]
```

The file is an XMI (`.xmi`), JSON (`.json`) or Ecore (`.ecore`) file, chosen by its extension or,
for any other extension, by its contents.
Every query looks at the whole document: every object of a model, however deeply it is contained,
and every element of a metamodel.

**Options:**

- `-q, --query <query>` - The query to run (default: `info`)
- `-m, --metamodel <file.ecore>` - A metamodel of the model, in any metamodel format (can be given
  several times); without one, the classes of a model are inferred from the document
- `--ocl <file.ocl>` - A Complete OCL document that constrains the metamodels (can be given several
  times; see Complete OCL above)
- `--encoding <name>` - The character encoding of the documents in text formats, such as
  `ISO-8859-1` (see Files and Metamodels above)
- `-v, --verbose` - Show the file and the query before the result

**Queries:**

- `info` - The number of root objects and of all objects, and the number of objects of each class;
  for a metamodel, its packages with the numbers of their classifiers, and its elements by kind
- `count` - The number of objects
- `list-classes` (or `classes`) - For a model, the class of every object with its number of
  instances and its supertypes; for a metamodel, every class it defines with its supertypes and
  whether it is abstract or an interface
- `hierarchy` - The inheritance hierarchy of the classes of a metamodel, or of the metamodels of a
  model
- `find <class>` - The objects of a class or of one of its subclasses, with their attribute values
  and references; for a metamodel, the elements of a metaclass such as `EClass`
- `tree` - The containment tree, with the class, name and location of every object, or every
  package, classifier, feature and literal of a metamodel

Query names and class names are matched without regard to case. Objects are named by the value of
a feature such as `name`, and located by a fragment in the syntax of the Eclipse Modeling Framework,
such as `//@employees.0` (the first object of the `employees` of the single root object) or
`/1/@classifiers.0` (in the second root object). A reference into another document is resolved and
shown with that document.

**Examples:**

```bash
# Count the objects of each class
swift-ecore query model.xmi

# List every class of a metamodel with its supertypes
swift-ecore query Company.ecore --query classes

# List the employees, including managers if Manager extends Employee
swift-ecore query company.xmi --metamodel Company.ecore --query "find Employee"

# Show the containment tree
swift-ecore query model.json -q tree
```

## Environment and Configuration File

The Compatibility with 0.6 section of the [SwiftModelling documentation](https://mipalgu.github.io/swift-modelling/documentation/swiftmodelling/swiftmodelling/index.html) lists every behaviour option with its default and its version 0.6 behaviour, and describes the environment variable and the configuration file in full.

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable (`standard` or `legacy`) chooses the preset, and then the `semantics` key of a configuration file. The configuration file is the first `.swift-modelling.json` in the current directory or one of its parents, up to the directory that holds `.git`; `--config` names another file and `--no-config` reads none. Its keys are the names of the behaviour options without their leading `--`, with the spellings of the command line as JSON strings, or JSON booleans for `check-let-types`, `cache-containers` and `strict-aql`; a key that does not apply to a command is ignored. A behaviour option given on the command line overrides the file, an option in the file overrides the preset, `--semantics` overrides the environment variable, and the environment variable overrides `semantics` in the file. `--let-type-mismatches` and `--unset-features` do not depend on the preset: the command line overrides the file, which overrides their defaults. An invalid value of the variable, or an unknown key or an invalid value in the file, stops the command with an error that names it.

```json
{
  "semantics": "legacy",
  "block-line-breaks": "acceleo",
  "check-let-types": true,
  "container-scope": "any-resource"
}
```

## Common Workflows

### From Metamodel to Code

```bash
# 1. Validate a metamodel
swift-ecore validate organisation.ecore --verbose

# 2. Validate an instance against the metamodel
swift-ecore validate company.xmi --metamodel organisation.ecore

# 3. Convert to JSON, for example for web APIs
swift-ecore convert company.xmi company.json --verbose

# 4. Query the model for analysis
swift-ecore query company.xmi --query "find Employee" --verbose

# 5. Generate Swift code from the metamodel
swift-ecore generate organisation.ecore --output swift-gen/ --verbose

# 6. Convert back to XMI from JSON
swift-ecore convert company.json company-copy.xmi --force
```

### Converting Legacy XMI to JSON

```bash
# Check that the model reads with its metamodel, then convert it
swift-ecore validate legacy-model.xmi --metamodel schema.ecore
swift-ecore convert legacy-model.xmi modern-model.json --metamodel schema.ecore
```

### Validating Model Conformance

```bash
# Validate against the metamodel, with details of what was read
swift-ecore validate production-model.xmi --metamodel schema.ecore --verbose
```

### Checking a Migration

```bash
# What changed in the metamodel, and whether the migrated model kept every object
swift-ecore compare legacy.ecore improved.ecore
swift-ecore validate migrated.xmi --metamodel improved.ecore
swift-ecore compare legacy.xmi migrated.xmi --metamodel legacy.ecore --metamodel improved.ecore --summary
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftEcore>

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
