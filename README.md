# Swift Modelling

[![CI](https://github.com/mipalgu/swift-modelling/actions/workflows/ci.yml/badge.svg)](https://github.com/mipalgu/swift-modelling/actions/workflows/ci.yml)
[![Documentation](https://github.com/mipalgu/swift-modelling/actions/workflows/documentation.yml/badge.svg)](https://github.com/mipalgu/swift-modelling/actions/workflows/documentation.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmipalgu%2Fswift-modelling%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mipalgu/swift-modelling)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmipalgu%2Fswift-modelling%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mipalgu/swift-modelling)
[![License](https://img.shields.io/badge/License-BSD%204--Clause%20or%20GPL%202.0+-blue.svg)](https://github.com/mipalgu/swift-modelling/blob/main/LICENCE)

Command-line tools for the Swift Modelling Framework.

These tools aim to provide comprehensive support for the
[Eclipse Modelling Framework (EMF)](https://eclipse.dev/emf/),
[Atlas Transformation Language (ATL)](https://eclipse.dev/atl/),
and the [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/) standard.

## Aims / Features

### ECore Support
- **Pure Swift**: No Java/EMF dependencies, Swift 6.0+ with strict concurrency
- **Cross-Platform**: Full support for macOS, Linux, and Windows
- **Value Types**: Sendable structs and enums for thread safety
- **BigInt Support**: Full arbitrary-precision integer support via swift-numerics
- **Complete Metamodel**: EClass, EAttribute, EReference, EPackage, EEnum, EDataType
- **Resource Infrastructure**: EMF-compliant object management and ID-based reference resolution
- **JSON Serialisation**: Load and save JSON models with full round-trip support
- **Bidirectional References**: Automatic opposite reference management across resources
- **XMI Parsing**: Load .ecore metamodels and .xmi instance files
- **Dynamic Attribute Parsing**: Arbitrary XML attributes with automatic type inference (Int, Double, Bool, String)
- **XPath Reference Resolution**: Same-resource references with XPath-style navigation (//@feature.index)
- **XMI Serialisation**: Write models to XMI format with full round-trip support

### ATL Support
- **Eclipse ATL Compatibility**: Full syntax compatibility with Eclipse ATL transformations
- **Complete Parser**: Full ATL/OCL syntax support (96/96 tests passing)
- **XMI Serialisation**: Eclipse ATL XMI format support (134/134 round-trip tests passing)
- **Execution Engine**: Complete ATL virtual machine with expression evaluation
- **Advanced OCL**: Let expressions, tuple expressions, iterate operations, lambda expressions
- **Helper Functions**: Context and standalone helper functions

### MOFM2T Support
- **MTL Parser**: Parse MTL templates from text files following the OMG MOFM2T v1.0 specification
- **MTL Runtime**: Execute templates with high performance using Swift's concurrent execution model
- **Model Loading**: Load models from XMI and JSON formats for transformation
- **Expression Language**: Full AQL (Acceleo Query Language) integration for expressions
- **Advanced Features**: File blocks, protected areas, queries, macros, control flow
- **CLI Tool**: Generate, parse, and validate MTL templates from the command line
- **Standard Compliance**: Implements OMG MOFM2T v1.0 with compatibility for Acceleo-specific extensions

## Requirements

- Swift 6.0 or later
- macOS 15.0+, Linux, or Windows

## Installation

### Homebrew (macOS / Linux)

You can install the suite of modelling tools using [Homebrew](https://brew.sh)
on macOS or Linux:

```bash
brew tap mipalgu/tap
brew install swift-modelling
```

This will install `swift-ecore`, `swift-atl`, and `swift-mtl` to your system.

### Windows

Pre-built Windows binaries are available from the
[GitHub Releases](https://github.com/mipalgu/swift-modelling/releases) page.
Download `swift-modelling-vX.Y.Z-windows-x86_64.zip`, extract it, and add
the executables to your PATH.

## Building

```bash
# Build all CLI tools
swift build

# Run the ECore CLI
swift run swift-ecore --help

# Run the ATL CLI
swift run swift-atl --help

# Run the MTL CLI
swift run swift-mtl --help
```

## Usage

The `swift-ecore` command-line tool provides comprehensive Eclipse Modelling Framework functionality for Swift. All commands support the `--verbose` flag for detailed output and `--help` for usage information.

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

**Supported languages (planned):**
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

### MTL (Model-to-Text) Commands

Generate text from models using MTL templates following the OMG MOFM2T (MOF Model-to-Text Transformation) standard.

#### Generate Command

```bash
# Basic generation from template
swift run swift-mtl generate template.mtl --output generated/

# Generate with input models
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --output generated/

# Generate with multiple models
swift run swift-mtl generate template.mtl \
  --model families.xmi \
  --model departments.xmi \
  --output generated/

# Specify main template explicitly
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --template generateAll \
  --output generated/

# Verbose generation with statistics
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --output generated/ \
  --verbose
```

**Input formats:** MTL templates (`.mtl`), XMI models (`.xmi`), JSON models (`.json`)

#### Parse Command

Display MTL template structure for inspection and debugging.

```bash
# Parse and show template structure
swift run swift-mtl parse template.mtl

# Parse multiple templates
swift run swift-mtl parse template1.mtl template2.mtl

# Detailed template information
swift run swift-mtl parse template.mtl --detailed

# JSON output for programmatic use
swift run swift-mtl parse template.mtl --json
```

#### Validate Command

Validate MTL template syntax and structure.

```bash
# Validate single template
swift run swift-mtl validate template.mtl

# Validate multiple templates
swift run swift-mtl validate *.mtl

# Verbose validation with module details
swift run swift-mtl validate template.mtl --verbose
```

#### MTL Template Example

Create a file `hello.mtl`:

```mtl
[module HelloWorld('http://example.com')]

[template main()]
Hello, World!
This is a simple MTL template.
[/template]
```

Then generate:

```bash
swift run swift-mtl generate hello.mtl --output /tmp/output/
cat /tmp/output/stdout
```

#### Code Generation Example

```mtl
[module ClassGenerator('http://www.eclipse.org/emf/2002/Ecore')]

[template generateClass(c : EClass)]
[file (c.name + '.swift', 'overwrite', 'UTF-8')]
// Generated from [c.name/]
class [c.name/] {
[for (attr in c.eAttributes) separator('\n')]
    var [attr.name/]: [attr.eType.name/]
[/for]
}
[/file]
[/template]
```

Generate Swift code from an Ecore model:

```bash
swift run swift-mtl generate ClassGenerator.mtl \
  --model mymodel.ecore \
  --output generated-swift/
```

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

**Cross-platform:** All functionality works identically on macOS, Linux, and Windows.

**PyEcore compatibility:** JSON output is compatible with PyEcore for cross-language workflows.

## Project Status

### CLI Tools 🚧

- [x] Validate command - Validate models and metamodels for correctness
- [x] Convert command - Convert between XMI and JSON formats  
- [x] Query command - Query models with info, count, find, list-classes, and tree operations
- [ ] Generate command - Generate code in Swift, C++, C, and LLVM IR

## Architecture

**Swift Modelling** consists of:
- **ECore module**: Core library implementing the Ecore metamodel
- **ATL module**: Complete ATL parser and execution engine
- **MTL module**: MTL parser, runtime, and generation engine
- **swift-ecore executable**: Command-line tool for validation, conversion, and code generation
- **swift-atl executable**: Command-line tool for ATL transformation
- **swift-mtl executable**: Command-line tool for MTL text generation

All types are value types (structs) for thread safety, with ID-based reference resolution for bidirectional relationships.
Resources provide EMF-compliant object ownership and cross-reference resolution using actor-based concurrency.

## Licence

See the details in the LICENCE file.

## Compatibility

Swift Modelling aims for 100% round-trip compatibility with:
- [emf4cpp](https://github.com/catedrasaes-umu/emf4cpp) - C++ EMF implementation
- [pyecore](https://github.com/pyecore/pyecore) - Python EMF implementation

## References

This implementation is based on the following standards and technologies:

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/) - The reference EMF implementation
- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/) - The reference ATL implementation
- [Eclipse Acceleo](https://eclipse.dev/acceleo/) - The reference MTL implementation
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/) - The metamodelling standard
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/) - The XML serialisation format
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/) - The model transformation standard
- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/) - The model-to-text standard
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/) - The constraint and query language