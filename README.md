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
- **Generator Models**: Create Eclipse-compatible `.genmodel` files from Ecore models with `swift-ecore genmodel`, driven by a bundled ATL transformation
- **Java Generation**: Generate Java model code from a generator model with `swift-ecore generate --language java`, driven by bundled MTL templates that follow the Eclipse code generator (enumerations so far)
- **Template Sets**: Languages are directories of templates and data files; a new language needs no Swift code

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

Languages that have a template set, such as `java`, are generated from a generator model; see [Generating Java from a Generator Model](#generating-java-from-a-generator-model).

### GenModel Command

Create a generator model (`.genmodel`) from one or more Ecore models, as the Eclipse Ecore importer does. The result is the starting point for generating model code, and it opens unchanged in the Eclipse tooling.

```bash
# Write library.genmodel beside library.ecore
swift run swift-ecore genmodel model/library.ecore --base-package org.example

# Choose the output, project, plug-in identifier, copyright and compliance level
swift run swift-ecore genmodel model/library.ecore --output gen/library.genmodel \
  --model-project org.example.library --model-plugin-id org.example.library \
  --copyright "Copyright 2026 Example Pty Ltd" --jdk-level 17.0 --verbose

# Set the prefix of the root package, or of one named package
swift run swift-ecore genmodel model/company.ecore --prefix Company --prefix projects=Proj

# Keep the settings of an existing generator model while following changes to the Ecore model
swift run swift-ecore genmodel model/library.ecore --reload model/library.genmodel
```

**Options:**
- `--base-package` - the base package of the root packages
- `--prefix` - a package prefix: `Name` for the root package, or `package=Name` for one package (repeatable)
- `--model-project` - the name of the model project
- `--model-plugin-id` - the plug-in identifier of the model project
- `--model-directory` - the source directory of the model project
- `--copyright` - the copyright text
- `--jdk-level` - the compliance level of the generated code (default `17.0`; any level the generator model supports)
- `--reload` - an existing generator model whose settings are kept
- `-o, --output` - the generator model to write (default: beside the first Ecore model, named after it)
- `-v, --verbose` - show progress and a summary

**Defaults.** A new generator model gets the settings of the Ecore importer: importer identifier, compliance level `17.0`, model directory `/<project>/src`, model plug-in identifier derived from the project, model name taken from the generator model file, no copyright fields, operation reflection, `MinimalEObjectImpl$Container` as the root class, and import organising. Each package gets a prefix (its name with the first letter in upper case unless given), disposable provider factories, the XML resource kind when it uses extended metadata, and the load-initialisation settings that suit its size. Classes, features, enumerations, data types, operations and parameters get the settings that the importer derives from the Ecore model. References to the Ecore model are written in the layout Eclipse uses, for example `ecoreFeature="ecore:EAttribute library.ecore#//Book/title"`.

**Project name.** The project is the `--model-project` option if given. Otherwise, when the Ecore model lives in a directory named `model`, the project is the name of that directory's parent (the Eclipse layout `<project>/model/<name>.ecore`); in any other case it is the name of the root package.

**Reloading.** With `--reload`, every setting of the existing generator model is kept for the elements that still exist, matched by name, while new Ecore elements get the defaults and removed ones are dropped. Options given on the command line override the existing settings. The compliance level of the existing model is kept unless `--jdk-level` is given.

**Several models.** Several Ecore models can be given; each contributes its root packages to one generator model, which refers to the models by relative paths.

### Generating Java from a Generator Model

Generate Java model code from a generator model (`.genmodel`), with the templates of the bundled `java` template set. The generated code follows the output of the Eclipse Modeling Framework code generator for the default options, including its `@generated` tags, so that files can be merged with hand-written code and, where the Eclipse tooling is in use, with Eclipse's own output.

```bash
# Write the packages of the model below the output directory
swift run swift-ecore generate --language java model/library.genmodel --output src-gen/

# Start from an Ecore model; a temporary generator model with the importer defaults is used
swift run swift-ecore generate --language java model/library.ecore --output src-gen/

# Write below the model directory of the generator model (src-gen/library/src/org/example/...)
swift run swift-ecore generate --language java model/library.genmodel -o src-gen --model-directory

# Replace bundled templates, keep a copy of what would change, or replace everything
swift run swift-ecore generate --language java model/library.genmodel -o src-gen --template-path my-templates
swift run swift-ecore generate --language java model/library.genmodel -o src-gen --diff
swift run swift-ecore generate --language java model/library.genmodel -o src-gen --force-overwrite
```

**Options:**
- `-l, --language` - `java`, or the name of any other template set
- `-o, --output` - the directory to write below (default: the current directory)
- `--template-path` - a directory whose template files replace bundled files of the same name (repeatable; later directories win)
- `--force-overwrite` - replace existing files without merging
- `--diff` - write the generated text of an existing file beside it as `.<name>.new` and leave the file alone
- `--model-directory` - write below the model directory of the generator model
- `-v, --verbose` - show every progress report; without it a progress bar appears on an interactive terminal

**Existing files.** A file that exists is treated in this order: `--force-overwrite` replaces it; otherwise `--diff` writes the new text beside it; otherwise the generated members are merged with the file. In a merge, a member whose documentation comment carries `@generated` is regenerated, a member marked `@generated NOT` is kept as it is, and members without the tag (your own) are kept. Imports that you added stay.

**Current coverage.** The Java template set writes the switch, adapter factory and (for packages with constraints) validator of every package, and one file for every enumeration of every package (the full `EnumClass` template for compliance level 5.0 and higher, `typeSafeEnumCompatible` honoured). The package interface and implementation, factory, classes (interface and implementation), XML processor, resource factory and project files are listed as `TODO` comments in `generate.mtl` and follow.

**Checking the output.** Two optional checks run when their environment variable is set. `EMF_REFERENCE_ROOT` names a checkout of the Eclipse Modeling Framework; the generated `BookCategory.java` of its extended library example is then compared with the committed source. `EMF_RUNTIME_CLASSPATH` names the EMF runtime jars; the generated Java is then compiled with `javac`. `Scripts/fetch-emf-runtime.sh [directory]` downloads the jars from Maven Central and prints the class path:

```bash
export EMF_RUNTIME_CLASSPATH="$(Scripts/fetch-emf-runtime.sh)"
swift test --filter JavaCompileTests
```

### Template Sets

A template set generates code for one language. It is a directory named after the language that holds a descriptor, template modules and, optionally, data models. The bundled sets live in `Sources/ModellingGenerators/Templates/<language>/`. Nothing about a language is written in Swift: the Swift side provides the engines, the generator model, a set of language-neutral services and the pipeline.

```text
Templates/java/
    templateset.json     descriptor
    generate.mtl         main module: for each package, which files to write
    Header.mtl           file header comment
    JavaNames.mtl        names of packages, classes, accessors and constants
    JavaTypes.mtl        type mapping and container types
    JavaImports.mtl      imports and simple-name conflicts
    JavaDocumentation.mtl  documentation tags, literals and escapes
    EnumClass.mtl        the file of an enumeration
    SwitchClass.mtl, AdapterFactoryClass.mtl, ValidatorClass.mtl, JavaUtilities.mtl  the utility classes of a package
    TypeMapping.ecore    a small metamodel for the language data
    java-types.xmi       type table, reserved words and implicit types, an instance of it
```

**Descriptor (`templateset.json`).** Only `name`, `mainModule` and `mainTemplate` are required.

```json
{
  "name": "java",
  "summary": "Java model code for the Eclipse Modeling Framework runtime",
  "mainModule": "generate",
  "mainTemplate": "generate",
  "fileCountTemplate": "fileCount",
  "dataModels": [
    { "name": "types", "metamodel": "TypeMapping.ecore", "model": "java-types.xmi" }
  ],
  "layout": { "sourceRootSetting": "modelDirectory", "includeSourceRoot": false },
  "options": { "lineDelimiter": "\n" }
}
```

- `mainModule` and `mainTemplate` name the template that runs with the generator model (`GenModel`) as its only argument. It writes files with `[file (...)]` blocks; file names are relative to the output directory.
- `fileCountTemplate` (optional) names a template of the main module that writes the number of files the main template will write as the only content of one file. The pipeline runs it first, without touching the disk, so that progress reports can carry a total for a progress bar.
- `dataModels` lists models that the templates read: the metamodel (`.ecore`) and an instance (`.xmi`) in the set. Templates reach the root objects with `templateData('name')`. The Java set keeps its type table, reserved words and implicit types this way, so they change without touching code.
- `layout` says where files go by default. `sourceRootSetting` names a generator model setting that holds a source directory, such as `modelDirectory`; `includeSourceRoot` states whether it is part of the output location unless `--model-directory` decides otherwise.
- `options.lineDelimiter` is the line delimiter written to files.

**Modules.** Modules are written in the Acceleo dialect of MTL that swift-mtl implements. The module header names the metamodels that the templates use (the generator metamodel `http://www.eclipse.org/emf/2002/GenModel` and the namespaces of the data models). Modules import each other by name (`[import JavaNames/]`); imports are not transitive, so every module imports what it uses. Each module can be replaced by a file of the same name in a `--template-path` directory.

**Merge declaration.** A module declares how existing files are merged, for example the Java set declares `[merge ('/**', '*/', '@generated', '@generated NOT', 'braces')/]` in its main module: the comment delimiters of the leading comments, the tag of generated members, the tag of members to keep, and how blocks end. This is how a language states what a hand edit is; the engine knows no language.

**Imports.** `[collect ('imports', ...)/]` records names while a file is written and `[emit ('imports') once]...[/emit]` marks where the collected names are written. Language rules (which names need an import, simple-name conflicts, sorting and grouping) are queries in the set. `JavaImports.mtl` shows the pattern: the unit that is written is collected first, `importedName(qualified)` collects an import and returns the name to write.

**Services.** Templates reach the generator model with the structural features of the generator metamodel (`genPackage.genEnums`, `genClass.genFeatures`, `ecoreEnum`, ...) and with language-neutral services: `allGenFeatures()`, `implementedGenFeatures()`, `featureID(f)`, `featureCount()`, `operationID(o)`, `classifierID()`, `genClassifiers()`, `orderedGenClasses()`, `genPackage()`, `genModel()`, `isMapEntry()`, `labelFeature()`, shortcuts to the Ecore feature (`isContainment()`, `isListType()`, `lowerBound()`, ...), `capName()`, `uncapName()`, `upperName()`, `formatName(separator, prefix, includePrefix)`, `setting('name')` (a setting with the default of the generator metamodel), `documentation()`, `lines()`, `indentLines(prefix)`, `join(separator)` and a few more. Derived navigation is written with parentheses (`element.genPackage()`), because the same name is also a stored reference of the generator metamodel. The DocC article *Template Sets* in the `ModellingGenerators` documentation lists them all.

**Adding a language.** Create `Templates/<language>/` with a `templateset.json`, a main module that writes the files, and whatever query modules and data you need; nothing in Swift changes. To try a set without bundling it, put the directory (with the language name) in a directory and pass that with `--template-path`:

```text
my-templates/
    outline/
        templateset.json
        main.mtl
```

```bash
swift run swift-ecore generate --language outline model/library.genmodel -o out --template-path my-templates
```

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

# Ecore model: registered as a metamodel, and its EPackage is passed to the template
swift run swift-mtl generate ecore2dot.mtl \
  --model library.ecore \
  --output generated/

# Register a metamodel only, and pass just the instance model to the template
swift run swift-mtl generate template.mtl \
  --metamodel library.ecore \
  --model books.xmi \
  --output generated/

# Verbose generation with statistics
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --output generated/ \
  --verbose
```

**Input formats:** MTL templates (`.mtl`), XMI models (`.xmi`), JSON models (`.json`), Ecore metamodels (`.ecore`)

**Ecore roles:** `--model X.ecore` registers the metamodel and passes its root `EPackage` to the
main template, in command line order, like any other model. `--metamodel X.ecore` (repeatable)
only registers the metamodel, so that instance models can be parsed against it without the
`EPackage` becoming a template argument. Navigating the features of a native `EPackage` inside a
template requires a swift-ecore release with reflective metamodel objects.

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