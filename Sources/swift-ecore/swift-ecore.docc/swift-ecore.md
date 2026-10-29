# swift-ecore

Work with Ecore metamodels and model instances.

## Overview

The `swift-ecore` command-line tool provides comprehensive
utilities for working with Ecore metamodels and model instances
in both XMI and JSON formats. It supports format conversion, model
validation, queries of models, and the creation of generator models
and source code from Ecore models.

The tool is built on the swift-ecore package
(https://github.com/mipalgu/swift-ecore), which provides a pure
Swift implementation of the Eclipse Modeling Framework
([EMF](https://eclipse.dev/emf/)) Ecore metamodelling framework.

## Commands

### convert

Convert models between XMI and JSON formats.

```bash
swift-ecore convert <input-file> <output-file> [options]
```

**Options:**

- `--input-format <xmi|json>` - Input format (inferred from the extension if not specified)
- `--output-format <xmi|json>` - Output format (inferred from the extension if not specified)
- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
- `--reference-style <encoded|plain>` - How an XMI output spells references into itself
  (default `encoded`)
- `--force` - Overwrite the output file if it exists
- `-v, --verbose` - Show progress

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

Validate that a model can be read, optionally against its metamodel.

```bash
swift-ecore validate <model-file> [options]
```

**Options:**

- `-m, --metamodel <file.ecore>` - An Ecore metamodel of the model (can be given several times)
- `-v, --verbose` - Show the root objects that were read

With a metamodel, the model is read with the classes and data types the metamodel defines. A
JSON model is rejected if a value cannot be read by the data type of its attribute, or if a
class is not defined by any of the metamodels.

**Examples:**

```bash
# Check that a model can be read
swift-ecore validate model.xmi

# Validate a JSON model against its metamodel
swift-ecore validate model.json --metamodel MyMetamodel.ecore
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

Query the root objects of a model.

```bash
swift-ecore query <model> [options]
```

The model is an XMI (`.xmi`), JSON (`.json`) or Ecore (`.ecore`) file, chosen by its extension.
Its classes are inferred from the document, and each query looks at the root objects of the model.

**Options:**

- `-q, --query <query>` - The query to run (default: `info`)
- `-v, --verbose` - Show the file and the query before the result

**Queries:**

- `info` - The number of root objects, and the number of root objects of each class
- `count` - The number of root objects
- `list-classes` - The classes of the root objects
- `find <class>` - The root objects of a class, with up to three of their features each
- `tree` - The root objects as a list of tree branches

Queries and class names are matched without regard to case.

**Examples:**

```bash
# Count the root objects of each class
swift-ecore query model.xmi

# List the root objects that are companies
swift-ecore query company.xmi --query "find Company"

# Show the root objects as a tree
swift-ecore query model.json -q tree
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

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftEcore>

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
