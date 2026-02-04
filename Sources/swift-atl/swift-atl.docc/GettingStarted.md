# Getting Started with swift-atl

Learn how to use the swift-atl command-line tool to transform
models using ATL.

## Overview

The swift-atl CLI executes ATL (Atlas Transformation Language)
transformations that convert models from one metamodel to another.
This guide demonstrates common transformation patterns to help you
start transforming models quickly.

## Installation

The swift-atl tool is part of the swift-modelling package.

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mipalgu/swift-modelling.git",
             branch: "main"),
]
```

Build the tool:

```bash
swift build -c release
```

The executable will be available at:
`.build/release/swift-atl`

## Your First Transformation

### Validating the Transformation

Before running a transformation, validate its syntax:

```bash
swift-atl validate Families2Persons.atl \
    --source-metamodel Families.ecore \
    --target-metamodel Persons.ecore
```

This checks that:
- The transformation syntax is correct
- Referenced metamodel classes exist
- Helper signatures are valid
- Rule patterns are well-formed

### Running the Transformation

Execute the transformation:

```bash
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi
```

The tool:
1. Loads the source model
2. Applies transformation rules
3. Generates the target model
4. Writes output to the specified file

### Verifying the Output

Validate the generated model:

```bash
swift-ecore validate output-Persons.xmi \
    --metamodel Persons.ecore
```

This ensures the transformation produced valid output conforming
to the target metamodel.

## Basic Transformation Example

Here's a simple ATL transformation that converts family models to
person records:

```atl
module Families2Persons;
create OUT: Persons from IN: Families;

helper context Families!Member def: fullName: String =
    self.firstName + ' ' + self.familyName;

rule Member2Male {
    from
        s: Families!Member (not s.isFemale())
    to
        t: Persons!Male (
            fullName <- s.fullName
        )
}

rule Member2Female {
    from
        s: Families!Member (s.isFemale())
    to
        t: Persons!Female (
            fullName <- s.fullName
        )
}
```

Save this as `Families2Persons.atl` and run:

```bash
swift-atl transform Families2Persons.atl \
    --source families.xmi \
    --target persons.xmi
```

## Development Workflow

### Debug Mode

Run transformations in debug mode to trace execution:

```bash
swift-atl transform Families2Persons.atl \
    --source families.xmi \
    --target persons.xmi \
    --mode debug \
    --verbose
```

Debug output shows:
- Which rules matched which elements
- Helper evaluation results
- Binding assignments
- Warnings and potential issues

### Iterative Development

Use this workflow when developing transformations:

```bash
# 1. Edit transformation
vim MyTransformation.atl

# 2. Validate syntax
swift-atl validate MyTransformation.atl \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore

# 3. Test with sample data
swift-atl transform MyTransformation.atl \
    --source sample.xmi \
    --target output.xmi \
    --mode debug

# 4. Verify output
swift-ecore validate output.xmi \
    --metamodel Target.ecore
swift-ecore inspect output.xmi
```

## Advanced Features

### Using Helpers

Define reusable query operations:

```atl
-- Context helper (called on elements)
helper context Families!Family def: allMembers: Sequence(Member) =
    self.father->union(self.mother)->union(self.sons)->union(self.daughters);

-- Module helper (called on module)
helper def: isAdult(m: Families!Member): Boolean =
    m.age >= 18;
```

Use helpers in rules and other helpers:

```atl
rule Family2Household {
    from
        f: Families!Family
    to
        h: Persons!Household (
            members <- f.allMembers->select(m | thisModule.isAdult(m))
        )
}
```

### Lazy Rules

Call rules explicitly instead of auto-matching:

```atl
lazy rule CreateAddress {
    from
        m: Families!Member
    to
        a: Persons!Address (
            street <- m.street,
            city <- m.city,
            postcode <- m.postcode
        )
}

rule Member2Person {
    from
        m: Families!Member
    to
        p: Persons!Person (
            name <- m.firstName,
            address <- thisModule.CreateAddress(m)
        )
}
```

Lazy rules only execute when explicitly called, useful for
on-demand element creation.

### Called Rules

Define parameterised transformation steps:

```atl
called rule CreateChild(firstName: String, family: Families!Family) {
    to
        c: Persons!Child (
            name <- firstName,
            familyName <- family.name
        )
    do {
        c;
    }
}

rule Family2Household {
    from
        f: Families!Family
    to
        h: Persons!Household (
            children <- f.children->collect(child |
                thisModule.CreateChild(child.firstName, f))
        )
}
```

### Using Libraries

Share helpers across transformations:

```bash
# helpers.atl - shared helper library
module helpers;
helper def: normalise(s: String): String =
    s.toLower().replaceAll(' ', '_');
```

Import and use in transformations:

```bash
swift-atl transform MyTransformation.atl \
    --source input.xmi \
    --target output.xmi \
    --library helpers.atl
```

Reference library helpers:

```atl
to
    t: Target!Element (
        name <- thisModule.helpers.normalise(s.name)
    )
```

## Production Use

### Compilation

Compile transformations to bytecode for faster execution:

```bash
swift-atl compile Families2Persons.atl --optimise
```

This creates `Families2Persons.asm`. Run compiled transformations:

```bash
swift-atl transform Families2Persons.asm \
    --source input.xmi \
    --target output.xmi
```

Compiled transformations execute significantly faster, ideal for
processing large models or batch operations.

### Batch Processing

Transform multiple models efficiently:

```bash
#!/bin/bash
# Compile once
swift-atl compile Transform.atl --optimise

# Process many models
for input in models/*.xmi; do
    output="output/$(basename "$input")"
    swift-atl transform Transform.asm \
        --source "$input" \
        --target "$output" \
        --suppress-warnings
done
```

### Error Handling

Check exit codes in scripts:

```bash
#!/bin/bash
swift-atl transform Process.atl \
    --source input.xmi \
    --target output.xmi

if [ $? -eq 0 ]; then
    echo "Transformation succeeded"
    swift-ecore validate output.xmi --metamodel Target.ecore
else
    echo "Transformation failed"
    exit 1
fi
```

## Integration with Other Tools

### Pre-validation

Validate source models before transformation:

```bash
# Validate input
swift-ecore validate families.xmi \
    --metamodel Families.ecore

# Transform only if valid
if [ $? -eq 0 ]; then
    swift-atl transform Families2Persons.atl \
        --source families.xmi \
        --target persons.xmi
fi
```

### Post-processing

Generate code from transformed models:

```bash
# Transform model
swift-atl transform UML2Database.atl \
    --source design.xmi \
    --target schema.xmi

# Generate SQL from schema
swift-mtl generate GenerateSQL.mtl \
    --model schema.xmi \
    --output generated/
```

## Troubleshooting

### Transformation Doesn't Match Elements

**Problem**: Rules don't execute, output is empty

**Solution**: Add debug output to check patterns:

```bash
swift-atl transform MyTransformation.atl \
    --source input.xmi \
    --target output.xmi \
    --mode debug \
    --verbose
```

Check rule guards - they might be too restrictive.

### Type Errors

**Problem**: "Type mismatch" or "Unknown feature" errors

**Solution**: Validate with metamodels:

```bash
swift-atl validate MyTransformation.atl \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore \
    --strict
```

Ensure referenced classes, attributes, and references exist in
the metamodels.

### Slow Execution

**Problem**: Transformation takes too long

**Solution**: Compile with optimisation:

```bash
swift-atl compile MyTransformation.atl --optimise
swift-atl transform MyTransformation.asm \
    --source large-model.xmi \
    --target output.xmi
```

Also review helper efficiency - avoid expensive operations in
frequently-called helpers.

## Next Steps

- <doc:UnderstandingSwiftATL> - Learn ATL concepts
- **swift-ecore** - Validate models
- **swift-mtl** - Generate code from transformed models

## See Also

- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
