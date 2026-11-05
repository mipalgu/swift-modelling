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

## Commands

### convert

Convert models between XMI and JSON formats.

```bash
swift-ecore convert <input-file> <output-file> [options]
swift-ecore convert <input-file> --output <output-file> [options]
```

**Options:**

- `-o, --output <file>` - The output file, instead of the second argument
- `--validate` - Check the model as `validate` does, and write nothing if it has an error
- `--input-format <xmi|json>` - Input format (inferred from the extension if not specified)
- `--output-format <xmi|json>` - Output format (inferred from the extension if not specified)
- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
- `--reference-style <encoded|plain>` - How an XMI output spells references into itself
  (default `encoded`)
- `--force` - Overwrite the output file if it exists
- `-v, --verbose` - Show progress

JSON is written indented, with the keys of every object in alphabetical order.
With a metamodel, the model is read with the classes and data types the metamodel defines,
and JSON is written with package-qualified classes (`"eClass": "<nsURI>#//<Class>"`) and
non-containment references as `{"$ref": "<fragment>"}` entries. Without one, the classes are
inferred from the document.

Whatever the conversion cannot keep, such as a class that no metamodel defines or a reference
that cannot be written as a fragment, is reported once on standard error as a line starting
with `warning:`. Without `--metamodel`, the warnings are followed by a `hint:` line suggesting
it. Warnings do not change the exit status, and the completion message stays on standard
output.

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
```

### validate

Validate a metamodel, or a model against its metamodels.

```bash
swift-ecore validate <file>... [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
- `--check-abstract-classes` - For a metamodel, list every abstract class and interface with the
  concrete classes that extend it, and warn about one that none extends; for a model, confirm
  that no object is an instance of one
- `--strict` - Fail on warnings as well as on errors
- `--format <text|json>` - The format of the report (default `text`)
- `--report <file>` - Write the report to a file instead of standard output
- `-v, --verbose` - Show the root objects that were read, and every satisfied OCL invariant

A metamodel (`.ecore`) is checked against the constraints of Ecore, such as well-formed names,
consistent bounds and opposites, and acyclic inheritance. A model is checked for references into
other documents that name no object. With a metamodel, a model is also checked against it: every
class and feature must be defined by the metamodel, values must fit the types and bounds of their
features, references must lead to objects of the right class, no object may be an instance of an
abstract class or an interface, and every OCL invariant of the metamodel must hold. A JSON model is
rejected if a value cannot be read by the data type of its attribute, or if a class is not defined
by any of the metamodels.

Every problem is printed as a line starting with `error:`, `warning:` or `information:`, with the
element and its location in the model, such as `//@employees.0`. A violated OCL invariant is
printed as a line starting with `Checking constraint:`, followed by the number of satisfied
checks. The command prints `Validation completed successfully` and exits with status 0 if there
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
Expressions use the OCL that AQL shares, including implicit iterators such as
`self.accounts->isUnique(number)` and `String::indexOf`. Write an enumeration literal with its
package, as in `Bank::AccountType::SAVINGS`.

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
- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
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

- `-m, --metamodel <file.ecore>` - An Ecore metamodel of both models (can be given several times)
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
feature types, multiplicities, containment, opposites, the `id`, `derived`, `transient` and
`read-only` flags, default values, literal values, operation signatures and data type instance
classes.

Two models are compared object by object. Objects are matched by class and identity: the value of
the identifying attribute of their class, else the value that names them (such as `name`), else
their location; a weaker identity never matches two objects that both have a stronger one. Added
and removed objects are reported with their location, and for matched objects every changed
attribute value and non-containment reference, with referenced objects described by their labels.
Every given metamodel is registered for both models, so a legacy model and its migrated
counterpart can be compared with the metamodels of both.

Each difference is a line that starts with `+` (added), `-` (removed) or `~` (changed), such as
`~ attribute Order.status type: EString -> Status` or
`~ object Order 'A-1' (//@orders.0) status: "PAID" -> "SHIPPED"`, and a summary line such as
`6 differences: 1 added, 1 removed, 4 changed` or `No differences` ends the report. The command
exits with status 0 whether or not the files differ, unless `--exit-code` is given.

**Examples:**

```bash
# What changed between two versions of a metamodel
swift-ecore compare legacy.ecore improved.ecore

# Whether a migration kept every object: the objects of each class in both models
swift-ecore compare legacy.xmi migrated.xmi --metamodel legacy.ecore --metamodel improved.ecore --summary

# Fail a build if a regenerated model differs from the expected one
swift-ecore compare expected.xmi actual.xmi --metamodel schema.ecore --ignore modified --exit-code
```

### statistics

Measure the size and shape of a metamodel or a model.

```bash
swift-ecore statistics <file> [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
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
- `--output-format <xmi|json>` - The output format (inferred from the extension if not specified)
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

- `--base-package <name>` - Base package of the root packages
- `--prefix <name>` - Prefix of the root package, or `package=name` for one package (repeatable)
- `--model-project <name>` - Name of the model project
- `--model-plugin-id <id>` - Plug-in identifier of the model project
- `--model-directory <path>` - Source directory of the model project
- `--copyright <text>` - Copyright text
- `--jdk-level <level>` - Compliance level of the generated code (default: 17.0)
- `--defaults headless|wizard` - Preset of the settings that the Eclipse tools write differently for headless and interactive use (default: `headless`)
- `--root-extends-class <name>` - Class that generated root objects extend, overriding the preset
- `--operation-reflection` / `--no-operation-reflection` - Whether generated models include operation reflection, overriding the preset
- `--import-organizing` / `--no-import-organizing` - Whether generated code organises its imports, overriding the preset
- `--reload <path>` - Existing generator model whose settings are kept
- `--output <path>` - Generator model to write
- `--verbose` - Show progress and a summary

The model project is the `--model-project` option if given. Otherwise it is the parent directory of an Ecore model that lives in a directory named `model`, and the name of the root package in any other case.

Operation reflection, the root class and import organising follow the headless Eclipse generator by default: they keep the defaults of the generator metamodel and are not written. `--defaults wizard` gives the settings of the interactive Eclipse wizard (operation reflection and import organising on, `org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container` as the root class), and the individual options override the preset whatever their order.

When `--reload` names an existing generator model, its settings are kept for every element that still exists, matched by name. New Ecore elements get the defaults, removed ones are dropped, and options given on the command line override the existing settings. The three settings of the preset are kept too, unless `--defaults` or one of their own options is given.

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

Every language has a template set (`c`, `cpp`, `java` and `swift` are bundled) and is generated from a generator model (`.genmodel`); an Ecore model is imported into a temporary generator model first. A template set is a directory of templates and data files, so a new language needs no Swift code; see the `ModellingGenerators` documentation. The help (`swift-ecore generate --help`) lists the bundled template set languages; a language that `--template-path` adds is accepted but not listed there, and an unknown language is reported with every language that can be used, including those additions. `swift-atl generate` runs the same pipeline from the ATL tool.

**Options:**

- `-l, --language <name>` - the name of a template set, such as `swift`, `java`, `c` or `cpp` (default: `swift`)
- `-o, --output <path>` - Directory to write below (default: the current directory)
- `--template-path <path>` - Directory with template files that replace bundled templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new`
- `--model-directory` - Write below the model directory of the generator model
- `--code-style <style>` - The layout of the generated text, one of the styles of the template set (`java`: `eclipse`, the default, or `emf`); rejected for sets that offer none, such as `swift`, `c` and `cpp`
- `--defaults`, `--root-extends-class`, `--operation-reflection`, `--import-organizing` - The generator model defaults of an Ecore model that is imported for a template language, as for `genmodel`
- `--let-type-mismatches <error|skip>` - Whether a typed `let` in the templates whose value does not conform to the declared type stops the generation (`error`, the default) or is skipped with a warning on standard error (`skip`, as in Acceleo 3)
- `--block-line-breaks <acceleo|kept>`, `--collection-parameters <conforming|exact>`, `--check-let-types` / `--no-check-let-types`, `--cache-containers` / `--no-cache-containers`, `--collection-arguments <whole|first-element>`, `--collection-kinds <distinguished|sequences>`, `--single-value-collections <set|sequence>`, `--container-lookup <resources|registered-objects>` - The behaviours of the templates, as for `swift-mtl generate`; the first value is the default, and the second that of version 0.6
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`) for every behaviour option above; a behaviour option that is given overrides it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `-v, --verbose` - Show every progress report

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

The file is an XMI (`.xmi`), JSON (`.json`) or Ecore (`.ecore`) file, chosen by its extension.
Every query looks at the whole document: every object of a model, however deeply it is contained,
and every element of a metamodel.

**Options:**

- `-q, --query <query>` - The query to run (default: `info`)
- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times);
  without one, the classes of a model are inferred from the document
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

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable (`standard` or `legacy`) chooses the preset, and then the `semantics` key of a configuration file. The configuration file is the first `.swift-modelling.json` in the current directory or one of its parents, up to the directory that holds `.git`; `--config` names another file and `--no-config` reads none. Its keys are the names of the behaviour options without their leading `--`, with the spellings of the command line as JSON strings, or JSON booleans for `check-let-types` and `cache-containers`; a key that does not apply to a command is ignored. A behaviour option given on the command line overrides the file, an option in the file overrides the preset, `--semantics` overrides the environment variable, and the environment variable overrides `semantics` in the file. `--let-type-mismatches` and `--unset-features` do not depend on the preset: the command line overrides the file, which overrides their defaults. An invalid value of the variable, or an unknown key or an invalid value in the file, stops the command with an error that names it.

```json
{
  "semantics": "legacy",
  "block-line-breaks": "acceleo",
  "check-let-types": true,
  "container-scope": "any-resource"
}
```

## Common Workflows

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
