# Getting Started with swift-ecore

Learn how to use the swift-ecore command-line tool for working
with Ecore metamodels and models.

## Overview

The swift-ecore CLI provides essential operations for Ecore
metamodel and model management: validation, format conversion,
queries, and the creation of generator models and code. This guide walks through common
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

### Validating Models

Check that a model can be read, against the metamodel that defines
its classes:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore
```

The command reports an error if the model cannot be read, or if one
of its classes is not defined by any of the metamodels. `--verbose`
shows what was read.

### Converting Between Formats

Convert an XMI model to JSON, with the formats inferred from the
file extensions:

```bash
swift-ecore convert company.xmi company.json \
    --metamodel Company.ecore
```

Convert JSON back to XMI:

```bash
swift-ecore convert company.json company.xmi \
    --metamodel Company.ecore
```

With the metamodel, the model is read with the classes and data
types it defines, and written with package-qualified classes and
typed references. `--force` overwrites an existing output file, and
`--input-format` and `--output-format` override the file extensions.

### Querying Models

Show the classes and root objects of a model:

```bash
swift-ecore query company.xmi
swift-ecore query company.xmi --query "find Company"
```

## Common Operations

### Converting Without a Metamodel

Without `--metamodel`, the classes of a model are inferred from the
document. Whatever the conversion cannot keep, such as a class that
no metamodel defines, is reported on standard error as a line
starting with `warning:`, followed by a `hint:` line suggesting
`--metamodel`. The warnings do not change the exit status.

### Writing XMI for Eclipse

Eclipse writes a reference to an object of the same XMI model file
as the fragment alone, such as `//@departments.0`. With
`--reference-style plain`, `swift-ecore convert` writes XMI in that
layout:

```bash
swift-ecore convert company.json company.xmi \
    --metamodel Company.ecore \
    --reference-style plain
```

The default, `encoded`, keeps the leading `#` of such fragments.
Both styles load again.

### Creating Generator Models and Code

Create an Eclipse-compatible generator model beside an Ecore model,
then generate code from it:

```bash
swift-ecore genmodel Company.ecore
swift-ecore generate Company.genmodel --language java \
    --output src/
```

## Integration with Other Tools

### Using with swift-atl

Transform a model, then validate the result:

```bash
# Transform using ATL
swift-atl transform Company2Database.atl \
    --source company.xmi \
    --target database.xmi

# Validate the transformation result
swift-ecore validate database.xmi \
    --metamodel Database.ecore
```

### Using with swift-mtl

Validate a model before generating text from it:

```bash
# Validate model first
swift-ecore validate company.xmi \
    --metamodel Company.ecore

# Generate text if valid
swift-mtl generate GenerateSwift.mtl \
    --metamodel Company.ecore \
    --model company.xmi \
    --output generated/
```

## Batch Processing

Process multiple files with shell scripts:

```bash
# Convert all XMI files to JSON
for file in models/*.xmi; do
    output="json/$(basename "$file" .xmi).json"
    swift-ecore convert "$file" "$output" \
        --metamodel schema.ecore
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
