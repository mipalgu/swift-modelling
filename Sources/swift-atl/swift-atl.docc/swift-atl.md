# swift-atl

Transform models with the Atlas Transformation Language.

## Overview

The `swift-atl` command-line tool executes ATL (Atlas
Transformation Language) transformations to convert models from
one metamodel to another. It provides a complete implementation of
the ATL specification with support for declarative rules,
imperative sections, helpers, and advanced features like lazy
rules and called rules.

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

### validate

Validate an ATL transformation file for syntax and semantic
correctness.

```bash
swift-atl validate <transformation-file> [options]
```

**Options:**

- `--source-metamodel <path>` - Source metamodel for validation
- `--target-metamodel <path>` - Target metamodel for validation
- `--strict` - Enable strict validation mode
- `--report <path>` - Write validation report to file
- `--format <text|json>` - Report format (default: text)

**Examples:**

```bash
# Basic validation
swift-atl validate Families2Persons.atl

# Validation with metamodels
swift-atl validate MyTransformation.atl \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore

# Strict validation with JSON report
swift-atl validate MyTransformation.atl \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore \
    --strict \
    --report validation-report.json \
    --format json
```

### compile

Compile an ATL transformation to bytecode for faster execution.

```bash
swift-atl compile <transformation-file> [options]
```

**Options:**

- `--output <path>` - Output bytecode file path (default: same name with .asm extension)
- `--optimise` - Enable optimisation passes
- `--source-metamodel <path>` - Source metamodel for type checking
- `--target-metamodel <path>` - Target metamodel for type checking

**Examples:**

```bash
# Compile transformation
swift-atl compile Families2Persons.atl

# Compile with optimisation
swift-atl compile MyTransformation.atl \
    --output MyTransformation.asm \
    --optimise \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore
```

### query

Execute an ATL query to extract information from a model.

```bash
swift-atl query <query-file> [options]
```

**Options:**

- `--source <path>` - Source model file path (required)
- `--output <path>` - Output file for query results
- `--format <text|json|xml>` - Output format (default: text)

**Examples:**

```bash
# Execute query
swift-atl query FindAllClasses.atl --source model.xmi

# Execute query with JSON output
swift-atl query ExtractStatistics.atl \
    --source model.xmi \
    --output statistics.json \
    --format json
```

### refine

Execute an ATL refining transformation (in-place model
modification).

```bash
swift-atl refine <transformation-file> [options]
```

**Options:**

- `--model <path>` - Model file to refine (required)
- `--backup` - Create backup before refining
- `--verbose` - Enable verbose output

**Examples:**

```bash
# Refine model in-place
swift-atl refine NormaliseModel.atl --model mymodel.xmi

# Refine with backup
swift-atl refine UpdateReferences.atl \
    --model mymodel.xmi \
    --backup \
    --verbose
```

## Common Workflows

### Developing and Testing Transformations

```bash
# 1. Validate transformation syntax
swift-atl validate Families2Persons.atl \
    --source-metamodel Families.ecore \
    --target-metamodel Persons.ecore

# 2. Run transformation in debug mode
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi \
    --mode debug \
    --verbose

# 3. Validate output model
swift-ecore validate output-Persons.xmi \
    --metamodel Persons.ecore
```

### Production Transformation Pipeline

```bash
# 1. Compile transformation with optimisation
swift-atl compile Families2Persons.atl --optimise

# 2. Execute compiled transformation
swift-atl transform Families2Persons.asm \
    --source production-input.xmi \
    --target production-output.xmi \
    --suppress-warnings

# 3. Validate result
swift-ecore validate production-output.xmi \
    --metamodel Persons.ecore \
    --strict
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
