# swift-ecore

Work with Ecore metamodels and model instances.

## Overview

The `swift-ecore` command-line tool provides comprehensive
utilities for working with Ecore metamodels and model instances
in both XMI and JSON formats. It supports format conversion, model
validation, metamodel inspection, and model manipulation operations.

The tool is built on the swift-ecore package
(https://github.com/mipalgu/swift-ecore), which provides a pure
Swift implementation of the Eclipse Modeling Framework
([EMF](https://eclipse.dev/emf/)) Ecore metamodelling framework.

## Commands

### convert

Convert models between XMI and JSON formats.

```bash
swift-ecore convert <input-file> [options]
```

**Options:**

- `--output <path>` - Output file path (required)
- `--format <xmi|json>` - Output format (auto-detected from extension if not specified)
- `--pretty` - Pretty-print JSON output with indentation
- `--validate` - Validate model during conversion
- `--metamodel <path>` - Path to metamodel file for validation

**Examples:**

```bash
# Convert XMI to JSON
swift-ecore convert model.xmi --output model.json --pretty

# Convert JSON to XMI with validation
swift-ecore convert model.json --output model.xmi \
    --validate --metamodel MyMetamodel.ecore

# Convert with explicit format specification
swift-ecore convert data.txt --output result.xmi --format xmi
```

### validate

Validate that a model conforms to its metamodel.

```bash
swift-ecore validate <model-file> [options]
```

**Options:**

- `--metamodel <path>` - Path to metamodel file (required)
- `--strict` - Enable strict validation mode
- `--report <path>` - Write validation report to file
- `--format <text|json|xml>` - Report format (default: text)

**Examples:**

```bash
# Basic validation
swift-ecore validate model.xmi --metamodel MyMetamodel.ecore

# Strict validation with JSON report
swift-ecore validate model.xmi \
    --metamodel MyMetamodel.ecore \
    --strict \
    --report validation-report.json \
    --format json
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

Languages that have a template set, such as `java`, are generated from a generator model (`.genmodel`); an Ecore model is imported into a temporary generator model first. Swift, C++, C and LLVM are written by the built-in generator from Ecore, XMI or JSON models. A template set is a directory of templates and data files, so a new language needs no Swift code; see the `ModellingGenerators` documentation. The help (`swift-ecore generate --help`) lists the template set languages that exist, including those that `--template-path` adds, and an unknown language is reported with every language that can be used. `swift-atl generate` runs the same pipeline from the ATL tool.

**Options:**

- `-l, --language <name>` - `swift`, `cpp`, `c`, `llvm`, or the name of a template set such as `java` (default: `swift`)
- `-o, --output <path>` - Directory to write below (default: the current directory)
- `--template-path <path>` - Directory with template files that replace bundled templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new`
- `--model-directory` - Write below the model directory of the generator model
- `--defaults`, `--root-extends-class`, `--operation-reflection`, `--import-organizing` - The generator model defaults of an Ecore model that is imported for a template language, as for `genmodel`
- `-v, --verbose` - Show every progress report

Existing files are merged with the generated code: members tagged `@generated` are regenerated, members tagged `@generated NOT` and members without the tag are kept.

**Examples:**

```bash
# Generate Java from a generator model
swift-ecore generate --language java model/library.genmodel --output src-gen

# Customise one template and keep a copy of what would change in existing files
swift-ecore generate --language java model/library.genmodel -o src-gen \
    --template-path my-templates --diff
```

### inspect

Display information about a metamodel or model.

```bash
swift-ecore inspect <file> [options]
```

**Options:**

- `--detail <summary|full>` - Level of detail (default: summary)
- `--format <text|json>` - Output format (default: text)
- `--output <path>` - Write output to file instead of stdout
- `--show-references` - Include reference information
- `--show-attributes` - Include attribute details

**Examples:**

```bash
# Inspect metamodel summary
swift-ecore inspect MyMetamodel.ecore

# Full inspection with references
swift-ecore inspect MyMetamodel.ecore \
    --detail full \
    --show-references

# Export inspection as JSON
swift-ecore inspect model.xmi \
    --format json \
    --output inspection.json
```

### create

Create a new empty model conforming to a metamodel.

```bash
swift-ecore create [options]
```

**Options:**

- `--metamodel <path>` - Path to metamodel file (required)
- `--output <path>` - Output file path (required)
- `--format <xmi|json>` - Output format (default: xmi)
- `--root-class <name>` - Root element class name

**Examples:**

```bash
# Create empty XMI model
swift-ecore create \
    --metamodel MyMetamodel.ecore \
    --output new-model.xmi \
    --root-class MyRootClass

# Create empty JSON model
swift-ecore create \
    --metamodel MyMetamodel.ecore \
    --output new-model.json \
    --format json
```

### merge

Merge multiple model files into a single model.

```bash
swift-ecore merge <input-files...> [options]
```

**Options:**

- `--output <path>` - Output file path (required)
- `--strategy <append|replace|merge>` - Merge strategy (default: append)
- `--validate` - Validate result after merge
- `--metamodel <path>` - Path to metamodel for validation

**Examples:**

```bash
# Merge multiple models
swift-ecore merge model1.xmi model2.xmi model3.xmi \
    --output merged.xmi

# Merge with validation
swift-ecore merge model1.xmi model2.xmi \
    --output merged.xmi \
    --validate \
    --metamodel MyMetamodel.ecore \
    --strategy merge
```

## Common Workflows

### Converting Legacy XMI to JSON

```bash
# Convert with validation and pretty printing
swift-ecore convert legacy-model.xmi \
    --output modern-model.json \
    --pretty \
    --validate \
    --metamodel schema.ecore
```

### Validating Model Conformance

```bash
# Strict validation with detailed report
swift-ecore validate production-model.xmi \
    --metamodel schema.ecore \
    --strict \
    --report validation-report.json \
    --format json
```

### Inspecting Metamodel Structure

```bash
# Full inspection with all details
swift-ecore inspect MyMetamodel.ecore \
    --detail full \
    --show-references \
    --show-attributes \
    --output metamodel-structure.txt
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftEcore>

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
