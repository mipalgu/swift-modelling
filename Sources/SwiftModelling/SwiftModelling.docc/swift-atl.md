# swift-atl

Transform models with the Atlas Transformation Language.

## Overview

The `swift-atl` command-line tool executes ATL (Atlas Transformation Language) transformations to convert models from one metamodel to another. It provides a complete implementation of the ATL specification with support for declarative rules, imperative sections, helpers, and advanced features like lazy rules and called rules.

## Commands

### transform

Execute an ATL transformation to convert a source model into a target model.

```bash
swift-atl transform <transformation-file> [options]
```

**Options:**

- `--source <path>` - Source model file path (required)
- `--target <path>` - Target model file path (required)
- `--source-metamodel <path>` - Source metamodel file (auto-detected from transformation if not specified)
- `--target-metamodel <path>` - Target metamodel file (auto-detected from transformation if not specified)
- `--mode <normal|debug|trace>` - Execution mode (default: normal)
- `--verbose` - Enable verbose output
- `--suppress-warnings` - Suppress warning messages
- `--library <path>` - Additional ATL library to load
- `--property <key=value>` - Set transformation property

**Examples:**

```bash
# Basic transformation
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi

# Transformation with explicit metamodels
swift-atl transform MyTransformation.atl \
    --source input.xmi \
    --target output.xmi \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore

# Debug mode with verbose output
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi \
    --mode debug \
    --verbose

# Transformation with library and properties
swift-atl transform Complex.atl \
    --source input.xmi \
    --target output.xmi \
    --library MyHelpers.atl \
    --property "outputPath=/generated" \
    --property "encoding=UTF-8"
```

### validate

Validate an ATL transformation file for syntax and semantic correctness.

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

Execute an ATL refining transformation (in-place model modification).

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

## See Also

- <doc:Tutorials>
- <doc:01-first-transformation>
- <doc:swift-ecore>
- <doc:SwiftModelling>
