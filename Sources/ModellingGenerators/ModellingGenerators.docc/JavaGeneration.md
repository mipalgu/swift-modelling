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

From the command line, `swift-ecore generate --language java model/library.genmodel --output src-gen` and `swift-atl generate model/library.ecore --language java --output src-gen` do the same; <doc:GettingStarted> walks through the chain.

### What is generated

For every package the set writes the package interface and implementation, the factory interface and implementation, the interface and implementation class of every class, the Java enum of every enumeration, and, where the package asks for them, the XML processor, resource factory and resource, the switch and adapter factory, and the validator. When the output location includes the source directory of the model project it also writes the plugin class, plugin properties, build properties, bundle manifest and plugin descriptor. Compliance level 5.0 and higher is covered; generic type parameters, reflective, dynamic and virtual feature delegation, packed enumeration flags and the Google Web Toolkit platform are not.

### Modules of the set

- `generate.mtl` is the main module. It declares the merge and writes the files of each package.
- `JavaNames.mtl` holds the naming rules: reserved word escaping, package names with their suffixes, interface and implementation class names, accessors and the constants of enumeration literals.
- `JavaTypes.mtl` maps built-in data types with the bundled type table, finds the Java type of a classifier and decides on `EList` and `EMap`.
- `JavaImports.mtl` implements imports: simple-name conflicts, `java.lang`, the package of the unit that is written, sorting and grouping. A generator model that organises its imports (`importOrganizing`) gets explicit imports in groups of `java`, `javax`, `org`, `com` and other packages; otherwise the factory implementation, switch, adapter factory and validator import the interface package with a wildcard.
- `JavaDocumentation.mtl` writes model tags, API tags from documentation, string literals and escapes.
- `Header.mtl` writes the copyright comment that opens a file.
- `EnumClass.mtl` writes the file of an enumeration.
- `PackageClass.mtl` writes the package interface and the package implementation, and `PackageNames.mtl` holds its queries. Generic types and type parameters in the metamodel, the GWT platform and compliance levels below 5.0 are not supported.
- `SwitchClass.mtl` and `AdapterFactoryClass.mtl` write the switch and the adapter factory of a package that has classes and asks for adapter factories. `ValidatorClass.mtl` writes the validator of a package that has constraints (annotated constraints, invariant operations and data type facets). `JavaUtilities.mtl` holds what the three share. Classes with type parameters, external interfaces, runtimes older than 2.7 and facets that derive from base, item or member types are not covered.
- `TypeMapping.ecore` and `java-types.xmi` are the data model with the type table, the reserved words and the types that need no import.

### Existing files

A Java file that exists is merged with the generated text. A member whose comment carries `@generated` is regenerated, a member marked `@generated NOT` is kept, and members without the tag are kept. ``GenerationOptions/forceOverwrite`` replaces the file; ``GenerationOptions/diff`` writes the generated text beside it as `.<name>.new`.

The project files are not merged. An existing plugin descriptor, bundle manifest and plugin properties file stay as they are unless the overwrite is forced, and the build properties are replaced only while there is no plugin descriptor yet or when the overwrite is forced. The properties files are written in ISO-8859-1, with a Unicode escape for every character beyond it.

### Code styles

The templates write the layout of the Eclipse Modeling Framework repository sources: two-space indentation and the opening brace on its own line. The descriptor of the set declares two code styles that convert it, chosen with ``GenerationOptions/codeStyle``. `eclipse`, the default, indents with tabs and writes the opening brace at the end of the preceding line, as the Eclipse generator leaves the files in a workspace with the default Java formatter preferences. `emf` keeps the layout of the templates. Both styles share the blank lines of the Eclipse output: one blank line before and after the import block, or two blank lines between the package statement and the first comment when there are no imports; two blank lines between the identifier constants and the accessors of a package interface; and none between the constructor of a package implementation and the comment that follows it. Only `*.java` files are converted.

Switching the style of an existing tree is safe: generated members are regenerated in the new style, while members that you marked `@generated NOT` or wrote yourself keep their layout, so a mixture remains until the overwrite is forced.

### Checking the output

Setting `EMF_REFERENCE_ROOT` to a checkout of the Eclipse Modeling Framework compares the generated `BookCategory.java` of its extended library example with the committed source. Setting `EMF_RUNTIME_CLASSPATH` to the runtime jars compiles the generated Java with `javac`; `Scripts/fetch-emf-runtime.sh` downloads the jars and prints the class path.
