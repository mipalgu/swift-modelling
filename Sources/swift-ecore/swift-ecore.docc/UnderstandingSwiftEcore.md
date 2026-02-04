# Understanding swift-ecore

Learn the key concepts behind the swift-ecore command-line tool.

## Overview

The swift-ecore CLI tool provides operations for working with
Ecore metamodels and model instances. Understanding the
distinction between metamodels and models, serialisation formats,
and validation strategies is essential for effective use.

## Metamodels vs Models

### Metamodels Define Structure

A metamodel (`.ecore` file) defines the structure of your domain:

```
Company.ecore (Metamodel)
├── Company (EClass)
│   ├── name: String
│   └── departments: Department[*]
├── Department (EClass)
│   ├── name: String
│   └── employees: Employee[*]
└── Employee (EClass)
    ├── name: String
    └── employeeId: Integer
```

Metamodels are like database schemas or class diagrams - they
specify what can exist but don't contain actual data.

### Models Contain Data

A model (`.xmi` or `.json` file) contains actual instances:

```xml
<company:Company name="Acme Corp">
  <departments name="Engineering">
    <employees name="Alice" employeeId="1001"/>
    <employees name="Bob" employeeId="1002"/>
  </departments>
</company:Company>
```

Models are like database records - concrete data conforming to
the structure defined by the metamodel.

### Relationship

```
Metamodel (M2)     →  defines structure for  →  Model (M1)
Company.ecore                                   company.xmi
```

Every model must conform to exactly one metamodel. The
`swift-ecore validate` command checks this conformance.

## Serialisation Formats

### XMI Format

XMI (XML Metadata Interchange) ([OMG
XMI](https://www.omg.org/spec/XMI/)) is the standard format for
EMF models:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<company:Company xmi:version="2.0"
                 xmlns:xmi="http://www.omg.org/XMI"
                 xmlns:company="http://example.com/company"
                 name="Acme Corp">
  <departments name="Engineering"/>
</company:Company>
```

**Advantages:**
- Standard format, widely supported
- Preserves all XMI metadata
- Compatible with Eclipse EMF tools

**Disadvantages:**
- Verbose
- Difficult to read and edit manually

### JSON Format

JSON provides a more readable alternative:

```json
{
  "eClass": "http://example.com/company#//Company",
  "name": "Acme Corp",
  "departments": [
    {
      "eClass": "http://example.com/company#//Department",
      "name": "Engineering"
    }
  ]
}
```

**Advantages:**
- Human-readable
- Easier to generate and parse
- Works well with web APIs

**Disadvantages:**
- Less metadata than XMI
- Not universally supported by EMF tools

### Format Conversion

Use `swift-ecore convert` to move between formats:

```bash
# XMI to JSON (with pretty printing)
swift-ecore convert model.xmi --output model.json --pretty

# JSON to XMI
swift-ecore convert model.json --output model.xmi
```

Format conversion is lossless - all model data is preserved.
Add `--validate` to ensure the converted model is valid.

## Validation

### Basic Validation

Validation checks that a model conforms to its metamodel:

```bash
swift-ecore validate company.xmi --metamodel Company.ecore
```

This verifies:
- All objects are instances of classes defined in the metamodel
- Required attributes are present
- Attribute types match their declarations
- References point to valid objects
- Cardinality constraints are satisfied

### Strict Validation

Strict mode performs additional checks:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore \
    --strict
```

Additional checks include:
- No unknown attributes or references
- All containment relationships are valid
- No circular containment
- All cross-references are resolvable

### Validation Reports

Generate detailed reports for debugging:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore \
    --report validation-report.json \
    --format json
```

JSON reports include:
- Error locations (file, line, column)
- Error types and messages
- Affected model elements
- Suggested fixes

## Inspection

### Summary Inspection

Quick overview of metamodel or model structure:

```bash
swift-ecore inspect Company.ecore
```

Shows package structure, class count, and top-level organisation.

### Full Inspection

Detailed information about all elements:

```bash
swift-ecore inspect Company.ecore \
    --detail full \
    --show-references \
    --show-attributes
```

Displays:
- Complete class hierarchy
- All attributes with types and bounds
- All references with containment status
- Inheritance relationships
- Operations and parameters

### JSON Output

Export inspection results for programmatic processing:

```bash
swift-ecore inspect Company.ecore \
    --format json \
    --output structure.json
```

Useful for building tools that analyse metamodels or generate
documentation.

## Model Creation

### Empty Models

Create a skeleton model to populate later:

```bash
swift-ecore create \
    --metamodel Company.ecore \
    --output skeleton.xmi \
    --root-class Company
```

The created model contains a single root element with no
attributes set. Use this as a starting point for manual editing
or programmatic population.

### Format Selection

Choose the output format:

```bash
# Create JSON model
swift-ecore create \
    --metamodel Company.ecore \
    --output skeleton.json \
    --format json \
    --root-class Company
```

## Model Merging

### Merge Strategies

Three strategies control how models are combined:

**Append Strategy**

```bash
swift-ecore merge model1.xmi model2.xmi \
    --output merged.xmi \
    --strategy append
```

Adds all elements from all models. Elements with the same
identifier appear multiple times.

**Replace Strategy**

```bash
swift-ecore merge model1.xmi model2.xmi \
    --output merged.xmi \
    --strategy replace
```

Later files override elements from earlier files when identifiers
match.

**Merge Strategy**

```bash
swift-ecore merge model1.xmi model2.xmi \
    --output merged.xmi \
    --strategy merge
```

Intelligently combines elements:
- Matching elements are unified
- Attributes from later files override earlier ones
- Collections are merged

### Merge with Validation

Ensure the merged result is valid:

```bash
swift-ecore merge model1.xmi model2.xmi \
    --output merged.xmi \
    --validate \
    --metamodel Company.ecore
```

Validation runs after merging. If the result is invalid, the
output file is not written.

## Integration Patterns

### Validation Before Processing

Always validate models before expensive operations:

```bash
#!/bin/bash
if swift-ecore validate input.xmi --metamodel schema.ecore; then
    swift-atl transform process.atl \
        --source input.xmi \
        --target output.xmi
else
    echo "Validation failed, aborting transformation"
    exit 1
fi
```

### Pipeline Validation

Validate at each stage of a processing pipeline:

```bash
# Stage 1: Transform
swift-atl transform stage1.atl \
    --source input.xmi \
    --target intermediate.xmi

# Validate intermediate result
swift-ecore validate intermediate.xmi \
    --metamodel Intermediate.ecore

# Stage 2: Transform again
swift-atl transform stage2.atl \
    --source intermediate.xmi \
    --target output.xmi

# Validate final result
swift-ecore validate output.xmi \
    --metamodel Output.ecore
```

### Format Normalisation

Convert all inputs to a standard format:

```bash
# Normalise to JSON
for file in inputs/*; do
    output="normalised/$(basename "$file" .xmi).json"
    swift-ecore convert "$file" \
        --output "$output" \
        --format json \
        --pretty \
        --validate \
        --metamodel schema.ecore
done
```

## Best Practices

### Always Validate

Validate models after any modification:
- After conversion between formats
- After merging multiple models
- Before expensive operations (transformations, code generation)
- In production pipelines

### Use Strict Mode in Production

Enable strict validation for production systems:

```bash
swift-ecore validate production.xmi \
    --metamodel schema.ecore \
    --strict \
    --report validation.json \
    --format json
```

Review validation reports regularly to catch issues early.

### Prefer JSON for Human Editing

Use JSON format for models that humans edit:
- More readable structure
- Easier to version control
- Better diff/merge support
- Simpler to generate from scripts

Use XMI for tool-generated models or when Eclipse EMF
compatibility is required.

### Inspect Before Transforming

Understand metamodel structure before writing transformations:

```bash
swift-ecore inspect Source.ecore --detail full > source-structure.txt
swift-ecore inspect Target.ecore --detail full > target-structure.txt
```

Review the structure files to plan your transformation rules.

### Automate Validation

Integrate validation into your build process:

```makefile
validate:
    @echo "Validating models..."
    @for model in models/*.xmi; do \
        swift-ecore validate $$model \
            --metamodel schema.ecore \
            --strict || exit 1; \
    done
    @echo "All models valid"
```

## Error Handling

### Exit Codes

The swift-ecore tool uses standard exit codes:
- `0` - Success
- `1` - Validation failed or invalid arguments
- `2` - File not found or IO error
- `3` - Parse error (malformed XMI/JSON)

Use in scripts:

```bash
swift-ecore validate model.xmi --metamodel schema.ecore
if [ $? -eq 0 ]; then
    echo "Valid"
else
    echo "Invalid"
fi
```

### Error Messages

Error messages indicate the problem and location:

```
Error: Validation failed
  File: company.xmi:15:8
  Element: Employee[employeeId=1001]
  Issue: Required attribute 'name' is missing
```

## Next Steps

- <doc:GettingStarted> - Practical examples
- **swift-atl** - Transform models
- **swift-mtl** - Generate code from models

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
