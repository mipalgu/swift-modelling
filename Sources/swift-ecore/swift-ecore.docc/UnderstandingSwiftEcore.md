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
# XMI to JSON, with the metamodel so that classes keep their namespace
swift-ecore convert model.xmi --output model.json --metamodel Company.ecore

# JSON to XMI
swift-ecore convert model.json --output model.xmi --metamodel Company.ecore
```

The output file is the second argument or the value of `--output`
(`-o`). JSON is written indented, with the keys of every object in
alphabetical order, so two conversions of the same model compare
equal with `diff`. Every object, attribute value and reference is
kept; the `xmi:id` values of an XMI file are not, since JSON
locates objects by their position. Add `--validate` to check the
model as `swift-ecore validate` does before it is written: if it
has an error, no file is written.

## Validation

### Basic Validation

Validation checks that a model conforms to its metamodel:

```bash
swift-ecore validate company.xmi --metamodel Company.ecore
```

This verifies:
- All objects are instances of classes defined in the metamodel
- Every feature that an object sets is defined by its class
- Required features are present and no feature has too many values
- Attribute values match their types, including enumeration literals
- References point to existing objects of the right class, also in
  other documents
- No object is an instance of an abstract class or an interface
- Every OCL invariant of the metamodel holds

Without `--metamodel`, the command checks that the model can be read
and that its references into other documents can be resolved. A
metamodel (`.ecore`) is checked against the constraints of Ecore,
such as well-formed names, consistent bounds and opposites, and
acyclic inheritance.

### OCL Invariants

A class declares invariants as in the Eclipse Modeling Framework:
the `constraints` detail of its annotation with the source
`http://www.eclipse.org/emf/2002/Ecore` names them, and the detail
of the same name of its annotation with the source
`http://www.eclipse.org/emf/2002/Ecore/OCL` gives the expression:

```xml
<eAnnotations source="http://www.eclipse.org/emf/2002/Ecore">
  <details key="constraints" value="positiveBalance"/>
</eAnnotations>
<eAnnotations source="http://www.eclipse.org/emf/2002/Ecore/OCL">
  <details key="positiveBalance" value="self.balance >= 0"/>
</eAnnotations>
```

Every invariant is evaluated for every object whose class or
superclass declares it. Expressions use the OCL that AQL shares,
including collection operations with implicit iterators such as
`self.accounts->isUnique(number)` and the string operation
`indexOf`. Write an enumeration literal with its package, as in
`Bank::AccountType::SAVINGS`. A violated invariant is reported with
the object and its location; `--verbose` also lists the satisfied
ones.

### Abstract Classes

```bash
swift-ecore validate Company.ecore --check-abstract-classes
```

For a metamodel, the option lists every abstract class and
interface with the concrete classes that extend it, and warns about
one that no concrete class extends. For a model, it confirms that
no object is an instance of an abstract class or an interface.

### Strict Validation

Strict mode performs additional checks:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore \
    --strict
```

In strict mode, warnings fail validation as well as errors, for
example an abstract class that no concrete class extends or a
problem that the parser reported while reading the model.

### Validation Reports

Generate detailed reports for debugging:

```bash
swift-ecore validate company.xmi \
    --metamodel Company.ecore \
    --report validation-report.json \
    --format json
```

`--format` chooses `text` or `json`; without `--report`, the report
is written to standard output. JSON reports include:
- Whether the file is valid, and the numbers of errors and warnings
- Every finding with its severity, the identifier of the check,
  the location of the element as a fragment such as
  `//@employees.0`, a description of the element, and the message
- Every evaluation of an OCL invariant, with its outcome

## Inspection

### Summary Inspection

Quick overview of metamodel or model structure:

```bash
swift-ecore inspect Company.ecore
```

Shows the packages with their namespaces, and the names of their
classes, enumerations and data types. For a model (`.xmi` or
`.json`), it shows the number of objects of each class.

### Full Inspection

Detailed information about all elements:

```bash
swift-ecore inspect Company.ecore \
    --detail full \
    --show-references \
    --show-attributes
```

Displays:
- All attributes with types, bounds and default values
- All references with containment status and opposites, and the
  reference graph of the metamodel
- Operations with their parameters, and OCL invariants
- Enumeration literals with their values

`--show-supertypes` adds the inheritance: all supertypes, subclasses
and inherited features of every class, and the class hierarchy.
`--show-attributes` lists the attributes also in a summary. For a
model, `--detail full` shows every object with its values, nested
as the objects contain each other, and `--show-references` lists the
references between the objects.

### JSON Output

Export inspection results for programmatic processing:

```bash
swift-ecore inspect Company.ecore \
    --detail full \
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
or programmatic population. The class must be a concrete class of
the metamodel; an abstract class or an interface is rejected.

### Format Selection

The format follows from the extension of the output file, or from
`--output-format`:

```bash
# Create JSON model
swift-ecore create \
    --metamodel Company.ecore \
    --output skeleton.json \
    --root-class Company
```

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
        --validate \
        --metamodel schema.ecore
done
```

## Best Practices

### Always Validate

Validate models after any modification:
- After conversion between formats
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
- `1` - Validation failed, or a file cannot be found, read or
  parsed
- `64` - Invalid arguments, such as an unknown option

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

Each problem is reported with its severity, the element and its
location in the model, followed by a summary on standard error:

```
error: Employee (//@departments.0/@employees.0): Feature 'name' needs at least 1 value(s) but has 0
Error: Validation failed: 1 error(s), 0 warning(s)
```

## Next Steps

- <doc:GettingStarted> - Practical examples
- **swift-atl** - Transform models
- **swift-mtl** - Generate code from models

## See Also

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/)
