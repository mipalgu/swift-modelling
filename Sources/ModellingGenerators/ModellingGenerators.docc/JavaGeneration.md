# Java Generation

Generate Java model code from a generator model.

## Overview

The bundled `java` template set generates Java for the Eclipse Modeling Framework runtime. Its output follows the Eclipse code generator for the default options, including the `@generated` tags in the documentation comments, so files can be merged with hand-written code.

```swift
var options = GenerationOptions()
options.templatePaths = [URL(fileURLWithPath: "my-templates")]
let result = try await GenerationPipeline.generate(
    genModelURL: URL(fileURLWithPath: "model/library.genmodel"),
    language: "java",
    outputDirectory: URL(fileURLWithPath: "src-gen"),
    options: options)
```

From the command line, `swift-ecore generate --language java model/library.genmodel --output src-gen` does the same.

### What is generated

For every enumeration of every package the set writes the Java enum that implements the runtime's `Enumerator`: the literal constants, the integer value constants, `VALUES_ARRAY` and `VALUES`, the lookup methods `get(String)`, `getByName(String)` and `get(int)`, and the accessors. The form for compliance level 5.0 and higher is written; `typeSafeEnumCompatible` decides how constants are named. The remaining files of the Eclipse generator (package, factory, classes, switch, adapter factory, validator, resources and project files) are listed as `TODO` in the main module.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the files of each package.
- `JavaNames.mtl` holds the naming rules: reserved word escaping, package names with their suffixes, interface and implementation class names, accessors and the constants of enumeration literals.
- `JavaTypes.mtl` maps built-in data types with the bundled type table, finds the Java type of a classifier and decides on `EList` and `EMap`.
- `JavaImports.mtl` implements imports: simple-name conflicts, `java.lang`, the package of the unit that is written, sorting and grouping.
- `JavaDocumentation.mtl` writes model tags, API tags from documentation, string literals and escapes.
- `Header.mtl` writes the copyright comment that opens a file.
- `EnumClass.mtl` writes the file of an enumeration.
- `TypeMapping.ecore` and `java-types.xmi` are the data model with the type table, the reserved words and the types that need no import.

### Existing files

A file that exists is merged with the generated text. A member whose comment carries `@generated` is regenerated, a member marked `@generated NOT` is kept, and members without the tag are kept. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new`.

### Checking the output

Setting `EMF_REFERENCE_ROOT` to a checkout of the Eclipse Modeling Framework compares the generated `BookCategory.java` of its extended library example with the committed source. Setting `EMF_RUNTIME_CLASSPATH` to the runtime jars compiles the generated Java with `javac`; `Scripts/fetch-emf-runtime.sh` downloads the jars and prints the class path.
