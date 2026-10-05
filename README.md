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
- **Java Generation**: Generate Java model code from a generator model with `swift-ecore generate --language java`, driven by bundled MTL templates that follow the Eclipse code generator (enumerations and classes so far)
- **Template Sets**: Languages are directories of templates and data files; a new language needs no Swift code

### ATL Support
- **Eclipse ATL Compatibility**: Full syntax compatibility with Eclipse ATL transformations
- **Complete Parser**: Full ATL/OCL syntax support (96/96 tests passing)
- **XMI Serialisation**: Eclipse ATL XMI format support (134/134 round-trip tests passing)
- **Execution Engine**: Complete ATL virtual machine with expression evaluation
- **Advanced OCL**: Let expressions, tuple expressions, iterate operations, lambda expressions
- **Helper Functions**: Context and standalone helper functions
- **Module Parameters**: Values for `-- @param` declarations with `swift-atl transform --param name=value`
- **Built-in Metamodels**: The Ecore and generator metamodels resolve from `-- @nsURI` directives without metamodel files
- **Code Generation**: `swift-atl generate` turns Ecore models into generator models and generated code with the shared pipeline

### MOFM2T Support
- **MTL Parser**: Parse MTL templates from text files following the OMG MOFM2T v1.0 specification
- **MTL Runtime**: Execute templates with high performance using Swift's concurrent execution model
- **Model Loading**: Load models from XMI and JSON formats for transformation
- **Expression Language**: Full AQL (Acceleo Query Language) integration for expressions
- **Advanced Features**: File blocks, protected areas, queries, macros, control flow
- **CLI Tool**: Generate, parse, and validate MTL templates from the command line, with template search paths, parameters and merge or diff handling of existing files
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


## From Ecore to Java

<!-- from-ecore-to-java:begin -->
Turn an Ecore model into an Eclipse generator model (`.genmodel`) and into Java that compiles against the EMF runtime. The example is the extended library model of the Eclipse Modeling Framework, which is published under the Eclipse Public License and therefore downloaded rather than included:

```bash
mkdir -p extlibrary/model && cd extlibrary/model
curl -LO https://raw.githubusercontent.com/eclipse-emf/org.eclipse.emf/master/examples/org.eclipse.emf.examples.library/model/extlibrary.ecore
cd ..

# Two steps: write model/extlibrary.genmodel, then generate Java from it
swift-ecore genmodel model/extlibrary.ecore --base-package org.example
swift-ecore generate --language java model/extlibrary.genmodel --output src-gen

# One step: no generator model is left behind
swift-atl generate model/extlibrary.ecore --language java --base-package org.example --output src-gen
```

Both routes write the same 36 Java files below `src-gen/org/example/extlibrary`. Add `--model-directory` to `swift-ecore generate` to write below the model directory of the generator model together with `plugin.xml`, `MANIFEST.MF` and the other project files of an Eclipse model project. Regenerating merges into existing files: members tagged `@generated` are rewritten, members tagged `@generated NOT` and your own members are kept; `--diff` and `--force-overwrite` change that. To compile the result, `Scripts/fetch-emf-runtime.sh` downloads the EMF runtime jars and prints the class path.

`--defaults headless|wizard`, `--root-extends-class`, `--operation-reflection`, `--import-organizing` and `--code-style eclipse|emf` choose which of Eclipse's behaviours the output follows.

The [documentation](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/convertingecoretojava/index.html) lists every option and the files written, and [Matching Eclipse](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/matchingeclipse/index.html) explains precisely how the output relates to the Eclipse generator.
<!-- from-ecore-to-java:end -->

## Usage

The `swift-ecore` command-line tool provides comprehensive Eclipse Modelling Framework functionality for Swift. All commands except `info` support the `-v, --verbose` flag for detailed output, and every command supports `--help` for usage information.

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

Languages that have a template set, such as `java`, are generated from a generator model or an Ecore model by the shared template pipeline; see [Generating Java from a Generator Model](#generating-java-from-a-generator-model). `swift-ecore generate --help` lists the bundled template set languages; a language that a `--template-path` directory adds is accepted but not listed there, and an unknown language is reported together with every language that can be used, including those additions. The built-in generator for `swift`, `cpp`, `c` and `llvm` is unchanged.

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
- `--defaults` - `headless` (the default) or `wizard`: the preset of operation reflection, root class and import organising (see below)
- `--root-extends-class` - the class that generated root objects extend, overriding the preset
- `--operation-reflection` / `--no-operation-reflection` - whether generated models include operation reflection, overriding the preset
- `--import-organizing` / `--no-import-organizing` - whether generated code organises its imports, overriding the preset
- `--reload` - an existing generator model whose settings are kept
- `-o, --output` - the generator model to write (default: beside the first Ecore model, named after it)
- `-v, --verbose` - show progress and a summary

**Defaults.** A new generator model gets the settings of the Ecore importer: importer identifier, compliance level `17.0`, model directory `/<project>/src`, model plug-in identifier derived from the project, model name taken from the generator model file, and no copyright fields. Each package gets a prefix (its name with the first letter in upper case unless given), disposable provider factories, the XML resource kind when it uses extended metadata, and the load-initialisation settings that suit its size. Classes, features, enumerations, data types, operations and parameters get the settings that the importer derives from the Ecore model. References to the Ecore model are written in the layout Eclipse uses, for example `ecoreFeature="ecore:EAttribute library.ecore#//Book/title"`.

**Preset.** Operation reflection, the root class and import organising follow the headless generator of the Eclipse tools (`org.eclipse.emf.codegen.ecore.Generator -ecore2GenModel`) unless you ask otherwise: they keep the defaults of the generator metamodel (no operation reflection, `org.eclipse.emf.ecore.impl.EObjectImpl` as the root class, no import organising), so none of the three is written to the generator model. `--defaults wizard` gives the settings that the interactive New EMF Generator Model wizard writes instead: `operationReflection="true"`, `rootExtendsClass="org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"` and `importOrganizing="true"`. `--root-extends-class`, `--operation-reflection` and `--import-organizing` (or their `--no-` forms) override single settings of either preset, whatever their order on the command line. The presets are defined in the bundled transformation `Ecore2GenModel.atl` (the `defaults` parameter and the `...Override` parameters), so a replacement transformation can define its own. The same options exist on `swift-ecore generate` (for an Ecore model given for a template language) and on `swift-atl generate`; they do not apply to a generator model that is generated from directly.

**Project name.** The project is the `--model-project` option if given. Otherwise, when the Ecore model lives in a directory named `model`, the project is the name of that directory's parent (the Eclipse layout `<project>/model/<name>.ecore`); in any other case it is the name of the root package.

**Reloading.** With `--reload`, every setting of the existing generator model is kept for the elements that still exist, matched by name, while new Ecore elements get the defaults and removed ones are dropped. Options given on the command line override the existing settings. The compliance level of the existing model is kept unless `--jdk-level` is given, and operation reflection, the root class and import organising are kept unless `--defaults` or the corresponding flag is given.

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
- `--code-style <style>` - the layout of the generated text, one of the styles of the template set (`java`: `eclipse`, the default, or `emf`); rejected for the built-in languages
- `-v, --verbose` - show every progress report; without it a progress bar appears on an interactive terminal

**Code styles.** The Java template set offers two layouts, named in its descriptor as data. `eclipse` (the default) indents with tabs and writes the opening brace at the end of the preceding line, which is what the Eclipse generator leaves in a workspace with the default Java formatter preferences. `emf` indents with two spaces and writes the opening brace on its own line, as the sources in the Eclipse Modeling Framework repository do. The two styles differ only in white space, token for token, and the blank lines are the same in both. An unknown name is rejected with the styles that exist. The conversion runs on the generated text before it is merged with an existing file, so after changing the style of an existing tree every generated member is in the new style, and only a member that you marked `@generated NOT`, or wrote yourself, keeps the layout you gave it. Only files that match the patterns of the style (`*.java`) are converted; the project files are not. A template set declares its own styles in `templateset.json` (see the documentation of template sets).

**Imports.** When the generator model does not organise its imports (`importOrganizing` unset or false, the headless default), the factory implementation, switch, adapter factory and validator import the interface package of the model with one wildcard import (`import org.example.library.*;`), as the Eclipse generator writes it. When the generator model organises its imports (`importOrganizing="true"`, as `--defaults wizard` or `--import-organizing` ask), every file instead imports the types it uses by name, sorted within groups for `java`, `javax`, `org`, `com` and any other top-level package, with a blank line between groups, as the organise-imports pass of Eclipse leaves them.

**Existing files.** A file that exists is treated in this order: `--force-overwrite` replaces it; otherwise `--diff` writes the new text beside it; otherwise the generated members are merged with the file. In a merge, a member whose documentation comment carries `@generated` is regenerated, a member marked `@generated NOT` is kept as it is, and members without the tag (your own) are kept. Imports that you added stay. Only Java files are merged; the project files of a model (below) follow their own rules.

**Current coverage.** The Java template set writes the package interface and implementation (with loaded initialisation, literals interface, operation reflection, nested packages and annotations; no generic metamodels), the factory interface and implementation, the XML processor and the resource factory and resource of packages that ask for them, the validator (for packages with constraints), the interface (unless the class names an existing Java interface) and implementation class (unless the class is an interface) of every class, one file for every enumeration (the full `EnumClass` template for compliance level 5.0 and higher, `typeSafeEnumCompatible` honoured), the switch and adapter factory, and, when the output location includes the source directory, the plugin class, plugin properties, build properties, bundle manifest and plugin descriptor of the model project. The `Class` template covers fields, default value constants, accessors with notification, containment and bidirectional references with their inverse methods, many-valued features with the list classes the Eclipse generator chooses, unsettable features, boolean flags (`booleanFlagsField`), group delegation to feature maps, map features and map entry classes, operations with bodies from the `body` annotation, `eGet`/`eSet`/`eUnset`/`eIsSet`, `eBaseStructuralFeatureID`, `eInvoke` (`operationReflection`), minimal or complete reflective methods, and `toString`. It does not cover generic type parameters, compliance levels below 5.0, reflective, dynamic or virtual feature delegation, array accessors, packed enumeration flags, setting delegates, invariant operations with validation delegates, `suppressInterfaces` and the Google Web Toolkit platform.

**Checking the output.** Two optional checks run when their environment variable is set. `EMF_REFERENCE_ROOT` names a checkout of the Eclipse Modeling Framework; the generated enumeration, interfaces and implementation classes of its extended library example are then compared with the committed sources (`EMFJavaClassParityTests` lists the differences caused by manual edits of those sources). `EMF_RUNTIME_CLASSPATH` names the EMF runtime jars; the generated Java is then compiled with `javac`. `Scripts/fetch-emf-runtime.sh [directory]` downloads the jars from Maven Central and prints the class path:

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
    PackageClass.mtl     the package interface and implementation
    PackageNames.mtl     queries for the package templates
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
- `styles` and `defaultStyle` (optional) declare the code styles that `--code-style` chooses from, as data: each style names the indentation unit that the templates write (`sourceIndent`), the unit to produce (`targetIndent`), whether a block opener stays on its own line (`openerPlacement`: `ownLine` or `sameLine`) and the `files` it applies to. `defaultStyle` applies when no style is chosen. The Java set declares `eclipse` (the default) and `emf`; a set without `styles` rejects `--code-style`.
- Templates can ask `layoutIncludesSourceRoot()` whether the output location is the source directory itself (`false`) or contains it (`true`). The Java set writes the plugin descriptor, bundle manifest, build properties and plugin properties of the model project, which belong to the parent of the source directory, only in the second case (`--model-directory`). An existing `plugin.xml`, `MANIFEST.MF` and plugin properties file is kept unless `--force-overwrite` is given; the build properties are replaced only while no `plugin.xml` exists (or with `--force-overwrite`), as in the Eclipse generator. Properties files are written in ISO-8859-1, with a Unicode escape for every character beyond it. Merging an existing `plugin.xml`, `MANIFEST.MF` or properties file by key is not supported. The templates use the file controls of the template engine for this: `create` mode, the `files=*.java` scope of the `[merge]` declaration, `merge=false`, `fileExists` and `forceOverwrite`.

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

### Generating with ATL: `swift-atl generate`

`swift-atl generate` is the ATL entry to the same pipeline. An Ecore model is first transformed into a generator model by the bundled ATL transformation `Ecore2GenModel.atl`; a template language then turns the generator model into source files. The input is an Ecore model or a generator model.

```bash
# Create library.genmodel beside library.ecore (the language genmodel stops after the transformation)
swift run swift-atl generate model/library.ecore --language genmodel --base-package org.example

# Generate Java from an Ecore model in one step (no generator model is left behind)
swift run swift-atl generate model/library.ecore --language java --base-package org.example -o src-gen/

# Generate from an existing generator model, with customised templates and a copy of what would change
swift run swift-atl generate model/library.genmodel --language java --template-path my-templates --diff -o src-gen/

# Replace the bundled transformation with a file, or with a directory that holds Ecore2GenModel.atl
swift run swift-atl generate model/library.ecore --language genmodel --transformations my-atl/
```

**Languages.** `--language` takes `genmodel` (the default) or the name of any template set: the bundled ones (`java`) and the sets that `--template-path` directories add. `swift-atl generate --help` lists the bundled languages (a language that a `--template-path` directory adds is accepted but not listed there), and an unknown name is rejected with every language that can be used, including those additions. There are no other languages.

**Options.** `--base-package`, `--prefix`, `--model-project`, `--model-plugin-id`, `--copyright`, `--jdk-level`, `--defaults`, `--root-extends-class`, `--operation-reflection` and `--import-organizing` (with their `--no-` forms) mirror `swift-ecore genmodel`. `--template-path` (repeatable), `--force-overwrite`, `--diff`, `--model-directory` and `--code-style` mirror `swift-ecore generate` (`--code-style` is rejected for the language `genmodel`). `-o, --output` is the output directory (default `Generated`); for the language `genmodel` it is the directory or the `.genmodel` file to write, and the default is beside the Ecore model. `--transformations` replaces the bundled transformation with a transformation file or a directory holding `Ecore2GenModel.atl`; the replacement receives the same parameters as the bundled one. A progress bar with counts appears on an interactive terminal; `-v` prints one line for every file.

### ATL Transformations: `swift-atl transform`

```bash
# Positional source and target, as before
swift run swift-atl transform Families2Persons.atl --source families.xmi --target persons.xmi

# Values for the parameters a transformation declares with -- @param (repeatable)
swift run swift-atl transform Ecore2GenModel.atl --source IN=library.ecore --target OUT=library.genmodel \
  --param basePackage=org.example --param prefix=Library
```

**Parameters.** `--param name=value` binds a value to a module parameter declared in the transformation with `-- @param name : Type [= default]`. The text is converted to the declared type (`String`, `Integer`, `Real`, `Boolean`); the value is everything after the first `=`, and an undeclared name, a value of the wrong type, a missing required parameter or an argument without `name=` is an error. Inside the transformation a parameter is read as `thisModule.name`.

**Built-in metamodels.** The Ecore metamodel (`http://www.eclipse.org/emf/2002/Ecore`) and the generator metamodel (`http://www.eclipse.org/emf/2002/GenModel`) are built in. A transformation names them with directives, so no metamodel file is needed:

```text
-- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
-- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
module Tiny;
create OUT : GenModel from IN : Ecore;
```

**Output layout.** A target that is an instance of a built-in metamodel is written in the layout of the Eclipse Modeling Framework: references to other models are `uri#fragment` attribute values (`ecorePackage="library.ecore#/"`), with relative URIs and name-based fragments, so that the result opens unchanged in the Eclipse tooling. Other targets are written as before.

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

# Import modules from extra directories, and pass parameters to the templates
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --template-path shared/templates \
  --param package=org.example --param verbose=true \
  --output generated/

# Keep existing files and write the new text beside them as .<name>.new, or replace them all
swift run swift-mtl generate template.mtl --model input.xmi --diff --output generated/
swift run swift-mtl generate template.mtl --model input.xmi --force-overwrite --output generated/

# Verbose generation with statistics
swift run swift-mtl generate template.mtl \
  --model input.xmi \
  --output generated/ \
  --verbose
```

**Template path.** `--template-path <dir>` (repeatable) adds directories in which `[import ...]` looks for modules, after the directory of the template itself. A directory that does not exist is an error.

**Parameters.** `--param name=value` (repeatable) is available to every template as the bare variable `[name/]` and through two services: `parameter('name')` returns the value (`null` if it was not given) and `hasParameter('name')` tells whether it was given. A name must be an identifier that is not an MTL or AQL reserved keyword. A value is a boolean when it reads `true` or `false`, an integer when it is a whole number, and a string otherwise, so `[if (parameter('verbose'))]` and `[parameter('count') + 1/]` work. The value is everything after the first `=`, and a later argument replaces an earlier one of the same name.

**Existing files.** A file that exists is merged with the generated text when the module declares a merge, and replaced otherwise. `--force-overwrite` always replaces it. `--diff` keeps it and writes the generated text beside it as `.<name>.new`; `--force-overwrite` wins when both are given.

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
- [x] GenModel command - Create generator models from Ecore models
- [x] Generate command for template sets - Generate Java (and any added template set) from generator models and Ecore models, also through `swift-atl generate`

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