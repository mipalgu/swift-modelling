# swift-atl

Transform models with the Atlas Transformation Language.

## Overview

The `swift-atl` command-line tool executes ATL (Atlas
Transformation Language) transformations to convert models from
one metamodel to another. It also parses, validates, tests,
analyses and compiles ATL files, and generates generator models and
source code from Ecore models.

The tool is built on the swift-atl package
(https://github.com/mipalgu/swift-atl), which provides a pure
Swift implementation of the Eclipse ATL
([Eclipse ATL](https://eclipse.dev/atl/)) transformation language.

## Commands

### transform

Execute an ATL transformation to convert source models into target models.

```bash
swift-atl transform <transformation-file> [options]
```

**Options:**

- `--source <[ALIAS=]path>` - Source model file; repeat for several models, matched to the aliases of the `create` statement by order or by alias
- `--target <[ALIAS=]path>` - Target model file, matched in the same way
- `--param <name=value>` - Value for a module parameter declared with `-- @param` (repeatable)
- `--input-format <xmi|json>` - Format of the source models (default: from the file extension)
- `--output-format <xmi|json>` - Format of the target models (default: from the file extension)
- `--metamodel-path <directory>` - Directory searched for metamodels named by `-- @path` directives (repeatable)
- `--verbose` - Enable verbose output
- `--debug` - Trace the execution
- `--continue-after-errors` - Continue after metamodel loading errors

**Module parameters.** A transformation declares a parameter in a header comment, `-- @param name : Type` or `-- @param name : Type = default`, with the types `String`, `Integer`, `Real` and `Boolean`, and reads it as `thisModule.name`. `--param name=value` supplies the value; it is converted to the declared type. A name that the module does not declare, a value of the wrong type, a required parameter without a value, and an argument that is not `name=value` are errors.

**Built-in metamodels.** The Ecore metamodel (`http://www.eclipse.org/emf/2002/Ecore`) and the generator metamodel (`http://www.eclipse.org/emf/2002/GenModel`) are built in, so directives such as `-- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore` need no metamodel file. A target that is an instance of a built-in metamodel is written in the layout of the Eclipse Modeling Framework, with references to other models as `uri#fragment` attribute values; other targets keep the usual layout.

**Examples:**

```bash
# Basic transformation
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi

# Explicit aliases and a metamodel directory
swift-atl transform MyTransformation.atl \
    --source IN=input.xmi \
    --target OUT=output.xmi \
    --metamodel-path metamodels/

# Parameters for a transformation that declares them with -- @param
swift-atl transform Library2Report.atl \
    --source IN=library.xmi \
    --target OUT=report.xmi \
    --param title=Catalogue --param limit=10
```

### generate

Generate generator models and source code from Ecore models.

```bash
swift-atl generate <model.ecore | model.genmodel> [options]
```

The command is the ATL entry to the shared generation pipeline. An Ecore model is transformed into a generator model with the bundled `Ecore2GenModel.atl`; the pseudo-language `genmodel` stops there, and the name of a template set, such as `java`, continues to source files. A generator model is generated from directly.

**Options:**

- `-l, --language <name>` - `genmodel` (default), or the name of a template set; the help lists those that exist, including the ones that `--template-path` adds
- `-o, --output <path>` - Output directory (default: `Generated`); for `genmodel`, the directory or `.genmodel` file to write (default: beside the Ecore model)
- `--transformations <path>` - A transformation file, or a directory holding `Ecore2GenModel.atl`, that replaces the bundled transformation
- `--base-package <name>`, `--prefix <[package=]name>` (repeatable), `--model-project <name>`, `--model-plugin-id <id>`, `--copyright <text>`, `--jdk-level <level>` - Settings of the generator model, as for `swift-ecore genmodel`
- `--defaults headless|wizard`, `--root-extends-class <name>`, `--operation-reflection` / `--no-operation-reflection`, `--import-organizing` / `--no-import-organizing` - The preset of the generator model defaults and its overrides, as for `swift-ecore genmodel`; they only apply to an Ecore model
- `--template-path <directory>` - Directory with template files that replace bundled templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new`
- `--model-directory` - Write below the model directory of the generator model
- `--verbose` - One line for every file; without it a progress bar with counts appears on an interactive terminal

**Examples:**

```bash
# Create library.genmodel beside library.ecore
swift-atl generate model/library.ecore --language genmodel --base-package org.example

# Generate Java in one step
swift-atl generate model/library.ecore --language java --base-package org.example -o src-gen

# Replace the transformation, customise the templates
swift-atl generate model/library.ecore --language java --transformations my-atl/ \
    --template-path my-templates -o src-gen
```

### parse

Parse ATL transformation files and report their structure.

```bash
swift-atl parse [<atl-files> ...] [options]
```

**Options:**

- `-f, --format <text|json|xml>` - Output format (default: `text`)
- `-o, --output <file>` - Write the results to a file
- `--metamodel-path <directory>` - Metamodel search path (repeatable)
- `-v, --verbose` - Enable verbose output
- `--show-structure`, `--show-rules`, `--show-helpers` - Show the module structure, the rule details, or the helper details
- `--enable-stop-after-errors`, `--disable-stop-after-errors` - Stop after metamodel loading errors (default: disabled)

**Examples:**

```bash
swift-atl parse Families2Persons.atl --verbose
swift-atl parse *.atl --output parsing-report.txt
swift-atl parse transformation.atl --format json
```

### validate

Validate ATL transformation files for syntax and semantic
correctness.

```bash
swift-atl validate [<atl-files> ...] [options]
```

**Options:**

- `-o, --output <file>` - Write the validation results to a file
- `--metamodel-path <directory>` - Metamodel search path (repeatable)
- `-v, --verbose` - Enable verbose output
- `--strict` - Enable strict validation mode
- `--check-metamodels` - Check metamodel compatibility
- `--check-rules` - Validate rule completeness
- `--enable-stop-after-errors`, `--disable-stop-after-errors` - Stop after metamodel loading errors (default: disabled)

**Examples:**

```bash
# Basic validation
swift-atl validate Families2Persons.atl

# Strict validation of several files, with a log
swift-atl validate *.atl --strict --output validation.log

# Check metamodel compatibility
swift-atl validate transformation.atl --check-metamodels \
    --metamodel-path metamodels/
```

### test

Run parsing, validation and transformation execution tests on ATL
files, or on a directory of them.

```bash
swift-atl test [<atl-files> ...] [options]
```

**Options:**

- `-d, --directory <directory>` - Directory containing ATL test files
- `-t, --timeout <seconds>` - Test timeout in seconds (default: 60)
- `-o, --output <file>` - Write the test results to a file
- `-v, --verbose` - Enable verbose output
- `--fail-fast` - Stop on the first test failure

**Examples:**

```bash
swift-atl test Families2Persons.atl
swift-atl test --directory Tests/ATLTests/Resources
swift-atl test *.atl --timeout 30 --verbose
```

### analyze

Report complexity metrics, rule and helper analysis, and
transformation patterns for ATL files.

```bash
swift-atl analyze [<atl-files> ...] [options]
```

**Options:**

- `--metrics <list>` - Comma-separated metrics to compute from `complexity`, `rules`, `helpers` and `patterns` (default: all)
- `-o, --output <file>` - Write the results to a file
- `-f, --format <text|json>` - Output format (default: `text`)
- `-v, --verbose` - Enable verbose output

**Examples:**

```bash
swift-atl analyze Families2Persons.atl
swift-atl analyze *.atl --metrics complexity,rules,helpers
swift-atl analyze transformation.atl --output analysis.json
```

### compile

Compile an ATL transformation file.

```bash
swift-atl compile <atl-file> [options]
```

The command parses the transformation and names the compiled module, which defaults to the input file name with a `.atlc` extension. Run transformations with `swift-atl transform` on the `.atl` source file.

**Options:**

- `-o, --output <file>` - Output file for the compiled transformation
- `-v, --verbose` - Enable verbose output
- `--optimise` - Optimise the transformation code

**Example:**

```bash
swift-atl compile Families2Persons.atl --output families2persons.atlc
```

## Common Workflows

### Developing and Testing Transformations

```bash
# 1. Validate transformation syntax
swift-atl validate Families2Persons.atl --verbose

# 2. Run the transformation with execution tracing
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi \
    --debug

# 3. Validate output model
swift-ecore validate output-Persons.xmi \
    --metamodel Persons.ecore
```

### Batch Processing Multiple Models

```bash
# Process multiple models with the same transformation
for input in models/*.xmi; do
    output="output/$(basename "$input")"
    swift-atl transform Families2Persons.atl \
        --source "$input" \
        --target "$output" \
        --verbose
done
```

## Transformation Syntax Reference

### Module Declaration

```atl
module Families2Persons;
create OUT: Persons from IN: Families;
```

### Helpers

```atl
-- Context helper
helper context Families!Member def: fullName: String =
    self.firstName + ' ' + self.lastName;

-- Module helper
helper def: isMale(m: Families!Member): Boolean =
    not m.isFemale();
```

### Matched Rules

```atl
rule Member2Male {
    from
        s: Families!Member (not s.isFemale())
    to
        t: Persons!Male (
            fullName <- s.firstName + ' ' + s.familyName
        )
}
```

### Lazy Rules

```atl
lazy rule CreateAddress {
    from
        s: Families!Member
    to
        t: Persons!Address (
            street <- s.street,
            city <- s.city
        )
}
```

### Called Rules

```atl
rule ProcessFamily {
    from
        s: Families!Family
    to
        t: Persons!Group (
            members <- s.members->collect(m | thisModule.CreatePerson(m))
        )
}

called rule CreatePerson(member: Families!Member) {
    to
        p: Persons!Person (
            name <- member.firstName
        )
    do {
        p;
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftATL>

## See Also

- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
