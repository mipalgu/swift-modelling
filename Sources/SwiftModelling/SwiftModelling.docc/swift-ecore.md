# swift-ecore

Work with Ecore metamodels and model instances.

## Overview

The `swift-ecore` command-line tool provides comprehensive utilities for working with Ecore metamodels and model instances in both XMI and JSON formats. It supports format conversion, model validation, metamodel inspection, and model manipulation operations.

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

## See Also

- <doc:Tutorials>
- <doc:swift-atl>
- ``SwiftModelling``
