# Getting Started with swift-ecore

Learn how to use the swift-ecore command-line tool for working
with Ecore metamodels and models.

## Overview

The swift-ecore CLI provides essential operations for Ecore
metamodel and model management: format conversion, validation,
inspection, creation, and merging. This guide walks through common
use cases to get you started quickly.

## Installation

The swift-ecore tool is part of the swift-modelling package.

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
`.build/release/swift-ecore`

## First Steps

### Inspecting a Metamodel

Start by examining an Ecore metamodel:

```bash
swift-ecore inspect Company.ecore
```

Output:
```
Metamodel: Company
Package URI: http://example.com/company
Classes: 3
  - Company
  - Department  - Employee
Attributes: 5
References: 3
```

For detailed information:

```bash
swift-ecore inspect Company.ecore --detail full \
    --show-references --show-attributes
```

### Converting Between Formats

Convert XMI models to JSON:

```bash
swift-ecore convert company.xmi --output company.json --pretty
```

Convert JSON back to XMI:

```bash
swift-ecore convert company.json --output company.xmi
```

### Validating Models

Ensure a model conforms to its metamodel:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore
```

For detailed validation reports:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore \
    --strict \
    --report validation-results.json \
    --format json
```

## Common Operations

### Creating Empty Models

Create a new model instance:

```bash
swift-ecore create \
    --metamodel Company.ecore \
    --output new-company.xmi \
    --root-class Company
```

This creates an empty model with a Company root element that
you can populate programmatically or with other tools.

### Merging Multiple Models

Combine several models into one:

```bash
swift-ecore merge dept1.xmi dept2.xmi dept3.xmi \
    --output all-departments.xmi \
    --strategy merge \
    --validate \
    --metamodel Company.ecore
```

The `--strategy` option controls how conflicts are resolved:
- `append` - Add all elements
- `replace` - Later files override earlier ones
- `merge` - Intelligent merging based on identifiers

### Converting with Validation

Ensure data integrity during format conversion:

```bash
swift-ecore convert legacy-data.xmi \
    --output validated-data.json \
    --pretty \
    --validate \
    --metamodel Company.ecore
```

The conversion stops with an error if validation fails,
preventing corrupted data from being written.

## Integration with Other Tools

### Using with swift-atl

Transform a model then validate the output:

```bash
# Transform using ATL
swift-atl transform Company2Database.atl \
    --source company.xmi \
    --target database.xmi

# Validate the transformation result
swift-ecore validate database.xmi \
    --metamodel Database.ecore \
    --strict
```

### Using with swift-mtl

Validate a model before code generation:

```bash
# Validate model first
swift-ecore validate company.xmi \
    --metamodel Company.ecore

# Generate code if valid
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --output generated/
```

## Batch Processing

Process multiple files with shell scripts:

```bash
# Convert all XMI files to JSON
for file in models/*.xmi; do
    output="json/$(basename "$file" .xmi).json"
    swift-ecore convert "$file" --output "$output" --pretty
done
```

Validate all models in a directory:

```bash
# Validate all models
for file in models/*.xmi; do
    echo "Validating $file..."
    swift-ecore validate "$file" --metamodel schema.ecore \
        || echo "FAILED: $file"
done
```

## Next Steps

- <doc:UnderstandingSwiftEcore> - Learn about metamodel concepts
- **swift-atl** - Transform models with ATL
- **swift-mtl** - Generate code with MTL templates

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
