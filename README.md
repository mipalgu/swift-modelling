# Swift Modelling

Command-Line interface for the Swift Modeling Framework.

## Features

- **Pure Swift**: No Java/EMF dependencies, Swift 6.2+ with strict concurrency
- **Cross-Platform**: Full support for macOS and Linux
- **Value Types**: Sendable structs and enums for thread safety
- **BigInt Support**: Full arbitrary-precision integer support via swift-numerics
- **Complete Metamodel**: EClass, EAttribute, EReference, EPackage, EEnum, EDataType
- **Resource Infrastructure**: EMF-compliant object management and ID-based reference resolution
- **JSON Serialization**: Load and save JSON models with full round-trip support
- **Bidirectional References**: Automatic opposite reference management across resources
- **XMI Parsing**: Load .ecore metamodels and .xmi instance files
- **Dynamic Attribute Parsing**: Arbitrary XML attributes with automatic type inference (Int, Double, Bool, String)
- **XPath Reference Resolution**: Same-resource references with XPath-style navigation (//@feature.index)
- **XMI Serialization**: Write models to XMI format with full round-trip support

## Requirements

- Swift 6.0 or later
- macOS 15.0+ or Linux (macOS 15.0+ required for SwiftXML dependency)

## Building

```bash
# Build the CLI tool
swift build --scratch-path /tmp/build-swift-ecore

# Run tests
swift test --scratch-path /tmp/build-swift-ecore

# Run the CLI
swift run --scratch-path /tmp/build-swift-ecore swift-ecore --help
```

## Usage

The `swift-ecore` command-line tool provides comprehensive Eclipse Modeling Framework functionality for Swift. All commands support the `--verbose` flag for detailed output and `--help` for usage information.

### Basic Information

```bash
# Show version and available commands
swift run swift-ecore info

# Get help for any command
swift run swift-ecore <command> --help
```

### Validate Command

Validate models and metamodels for structural correctness and compliance.

```bash
# Validate an XMI model file
swift run swift-ecore validate model.xmi

# Validate with verbose output
swift run swift-ecore validate model.xmi --verbose

# Validate a JSON model
swift run swift-ecore validate data.json --verbose

# Validate an Ecore metamodel
swift run swift-ecore validate metamodel.ecore

# Validate with optional metamodel reference
swift run swift-ecore validate instance.xmi --metamodel schema.ecore
```

**Supported formats:** XMI (`.xmi`), JSON (`.json`), Ecore (`.ecore`)

### Convert Command

Convert between XMI and JSON formats while preserving model structure and data integrity.

```bash
# Convert XMI to JSON
swift run swift-ecore convert model.xmi output.json

# Convert JSON to XMI
swift run swift-ecore convert data.json output.xmi

# Convert with verbose progress information
swift run swift-ecore convert input.xmi output.json --verbose

# Force overwrite existing output file
swift run swift-ecore convert input.json output.xmi --force

# Example: Convert team model from XMI to JSON
swift run swift-ecore convert Tests/ECoreTests/Resources/xmi/team.xmi team.json --verbose
```

**Round-trip compatibility:** XMI ↔ JSON conversions maintain full fidelity with cross-references, containment relationships, and all data types.

### Generate Command

Generate source code in multiple programming languages from Ecore metamodels or model instances.

```bash
# Generate Swift code (default language)
swift run swift-ecore generate metamodel.ecore --output generated/

# Generate C++ code
swift run swift-ecore generate model.xmi --language cpp --output cpp-code/

# Generate C code
swift run swift-ecore generate schema.ecore --language c --output c-src/ --verbose

# Generate LLVM IR
swift run swift-ecore generate model.json --language llvm --output ir/

# Example: Generate Swift classes from organisation metamodel
swift run swift-ecore generate Tests/ECoreTests/Resources/xmi/organisation.ecore \
  --output generated/ --language swift --verbose
```

**Supported languages:**
- 🚧 `swift` - Swift structs with properties and types
- 🚧 `cpp` - C++ classes with getters/setters and headers
- 🚧 `c` - C structs and function declarations
- 🚧 `llvm` - LLVM IR templates

**Input formats:** Ecore metamodels (`.ecore`), XMI models (`.xmi`), JSON models (`.json`)

### Query Command

Inspect and analyse models with powerful query operations.

```bash
# Show general model information (default query)
swift run swift-ecore query model.xmi

# Count total objects in model
swift run swift-ecore query model.xmi --query "count"

# List all available classes
swift run swift-ecore query model.xmi --query "list-classes"

# Find objects of specific class
swift run swift-ecore query model.xmi --query "find Person"

# Show object tree structure
swift run swift-ecore query model.xmi --query "tree"

# Query with verbose output
swift run swift-ecore query team.xmi --query "find Team" --verbose
```

**Available query types:**
- `info` - Model statistics and class distribution
- `count` - Total object count
- `list-classes` - Available classes in the model
- `find <ClassName>` - Objects matching class name with detailed properties
- `tree` - Hierarchical view of model structure

### Real-World Examples

**Complete workflow example:**
```bash
# 1. Validate a metamodel
swift run swift-ecore validate organisation.ecore --verbose

# 2. Validate an instance against metamodel
swift run swift-ecore validate company.xmi --metamodel organisation.ecore

# 3. Convert to JSON for web APIs
swift run swift-ecore convert company.xmi company.json --verbose

# 4. Query the model for analysis
swift run swift-ecore query company.xmi --query "find Employee" --verbose

# 5. Generate Swift code from metamodel
swift run swift-ecore generate organisation.ecore --output swift-gen/ --verbose

# 6. Convert back to XMI from JSON
swift run swift-ecore convert company.json company-copy.xmi --force
```

**Batch processing example:**
```bash
# Validate all XMI files in a directory
for file in models/*.xmi; do
  echo "Validating $file..."
  swift run swift-ecore validate "$file" --verbose
done

# Convert all XMI files to JSON
for file in models/*.xmi; do
  json_file="${file%.xmi}.json"
  swift run swift-ecore convert "$file" "$json_file" --force
done
```

### Integration Tips

**Scripting:** All commands return appropriate exit codes (0 for success, non-zero for errors) for use in scripts and CI/CD pipelines.

**Large files:** Use `--verbose` to monitor progress on large models.

**Cross-platform:** All functionality works identically on macOS and Linux.

**PyEcore compatibility:** JSON output is compatible with PyEcore for cross-language workflows.

## Project Status

### CLI Tool 🚧

- [x] Validate command - Validate models and metamodels for correctness
- [x] Convert command - Convert between XMI and JSON formats  
- [x] Query command - Query models with info, count, find, list-classes, and tree operations
- [ ] Generate command - Generate code in Swift, C++, C, and LLVM IR

## Architecture

**Swift Modelling** consists of:
- **ECore module**: Core library implementing the Ecore metamodel
- **swift-ecore executable**: Command-line tool for validation, conversion, and code generation

All types are value types (structs) for thread safety, with ID-based reference resolution for bidirectional relationships.
Resources provide EMF-compliant object ownership and cross-reference resolution using actor-based concurrency.

## Licence

See the details in the LICENCE file.

## Compatibility

Swift Modelling aims for 100% round-trip compatibility with:
- [emf4cpp](https://github.com/catedrasaes-umu/emf4cpp) - C++ EMF implementation
- [pyecore](https://github.com/pyecore/pyecore) - Python EMF implementation
