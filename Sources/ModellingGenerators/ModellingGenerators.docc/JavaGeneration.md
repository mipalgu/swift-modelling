# Java Generation

Generate Java model code from a generator model.

## Overview

The bundled `java` template set generates Java for the Eclipse Modeling Framework runtime. Its output follows the Eclipse code generator, including the `@generated` tags in the documentation comments, so files can be merged with hand-written code. <doc:MatchingEclipse> describes how, and which Eclipse defaults and code styles can be chosen.

```swift
var options = GenerationOptions()
options.templatePaths = [URL(fileURLWithPath: "my-templates")]
let result = try await GenerationPipeline.generate(
    genModelURL: URL(fileURLWithPath: "model/library.genmodel"),
    language: "java",
    outputDirectory: URL(fileURLWithPath: "src-gen"),
    options: options)
```

From the command line, `swift-ecore generate --language java model/library.genmodel --output src-gen` and `swift-atl generate model/library.ecore --language java --output src-gen` do the same; <doc:ConvertingEcoreToJava> walks through the chain and lists every option.

### What is generated

For every package the set writes the package interface and implementation, the factory interface and implementation, the interface and implementation class of every class, and the Java enum of every enumeration. Where the package asks for them it also writes the XML processor, resource factory and resource, the switch and adapter factory, and the validator. When the output location includes the source directory of the model project (`--model-directory`), it also writes the plugin class when the generator model names one, plugin properties, build properties, bundle manifest and plugin descriptor.

Compliance level 5.0 and higher is covered. <doc:MatchingEclipse> lists the model features that are not.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the files of each package.
- `Class.mtl` writes the interface and implementation of a class, with `ClassQueries.mtl` (what a class contains), `ClassFeature.mtl` (fields and accessors), `ClassOperation.mtl` (operations), `ClassReflection.mtl` (the reflective methods) and `ClassModelInfo.mtl` (the model tags of documentation comments).
- `PackageClass.mtl` writes the package interface and implementation, and `PackageNames.mtl` holds its queries.
- `FactoryClass.mtl` writes the factory interface and implementation.
- `EnumClass.mtl` writes the file of an enumeration.
- `SwitchClass.mtl` and `AdapterFactoryClass.mtl` write the switch and the adapter factory of a package that has classes and asks for adapter factories. `ValidatorClass.mtl` writes the validator of a package that has constraints (annotated constraints, invariant operations and data type facets). `JavaUtilities.mtl` holds what the three share.
- `XMLProcessorClass.mtl`, `ResourceFactoryClass.mtl`, `ResourceClass.mtl` and `JavaResources.mtl` write the resource support of a package.
- `ProjectFiles.mtl` writes the project files: `Plugin.mtl` (the plugin class), `PluginXML.mtl`, `PluginProperties.mtl`, `BuildProperties.mtl` and `ManifestMF.mtl`, with `JavaProject.mtl` deciding which of them a model project needs.
- `JavaNames.mtl` holds the naming rules: reserved word escaping, package names with their suffixes, interface and implementation class names, accessors and the constants of enumeration literals.
- `JavaTypes.mtl` maps built-in data types with the bundled type table, finds the Java type of a classifier and decides on `EList` and `EMap`.
- `JavaImports.mtl` implements imports: simple-name conflicts, `java.lang`, the package of the unit that is written, sorting and grouping. A generator model that organises its imports (`importOrganizing`) gets explicit imports in groups of `java`, `javax`, `org`, `com` and other packages; otherwise the factory implementation, switch, adapter factory and validator import the interface package with a wildcard.
- `JavaDocumentation.mtl` writes model tags, API tags from documentation, string literals and escapes.
- `Header.mtl` writes the copyright comment that opens a file.
- `TypeMapping.ecore` and `java-types.xmi` are the data model with the type table, the reserved words and the types that need no import.

### Existing files

A Java file that exists is merged with the generated text. A member whose comment carries `@generated` is regenerated, a member marked `@generated NOT` is kept, and members without the tag are kept. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new` (hidden, for example `.Book.java.new`). With both set, the overwrite wins.

The project files are not merged. An existing plugin descriptor, bundle manifest and plugin properties file stay as they are unless the overwrite is forced, and the build properties are replaced only while there is no plugin descriptor yet or when the overwrite is forced. The properties files are written in ISO-8859-1, with a Unicode escape for every character beyond it.

### Code styles

The templates write the layout of the Eclipse Modeling Framework repository sources: two-space indentation and the opening brace on its own line. The descriptor of the set declares two code styles that convert it, chosen with ``GenerationOptions/codeStyle``. `eclipse`, the default, indents with tabs and writes the opening brace at the end of the preceding line, as the Eclipse generator leaves the files in a workspace with the default Java formatter preferences. `emf` keeps the layout of the templates. Both styles share the blank lines of the Eclipse output: one blank line before and after the import block, or two blank lines between the package statement and the first comment when there are no imports; two blank lines between the identifier constants and the accessors of a package interface; and none between the constructor of a package implementation and the comment that follows it. Only `*.java` files are converted.

Switching the style of an existing tree is safe: every generated member is regenerated in the new style, including the closing brace of a nested type and the body of an operation that has no implementation. Only members that you marked `@generated NOT` or wrote yourself keep their layout. A container whose own comment is tagged `@generated NOT`, such as a class, keeps its header as well.

### Checking the output

Setting `EMF_REFERENCE_ROOT` to a checkout of the Eclipse Modeling Framework compares the generated `BookCategory.java` of its extended library example with the committed source. Setting `EMF_RUNTIME_CLASSPATH` to the runtime jars compiles the generated Java with `javac`; `Scripts/fetch-emf-runtime.sh` downloads the jars and prints the class path.
