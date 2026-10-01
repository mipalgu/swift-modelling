# Getting Started

Take an Ecore model to a generator model and to Java, change the templates, and add a language.

## Overview

This article follows one model, `library.ecore`, through the whole chain with the command line tools and with the library. The model lives in the Eclipse layout `library/model/library.ecore`.

### From Ecore to a generator model

A generator model (`.genmodel`) holds the settings that decide what code is generated for an Ecore model. Create it with `swift-ecore genmodel`, or with `swift-atl generate --language genmodel`; both run the bundled ATL transformation `Ecore2GenModel.atl`, which gives the model the settings that the Eclipse Ecore importer gives a new model:

```bash
swift-ecore genmodel library/model/library.ecore --base-package org.example
```

The generator model is written beside the Ecore model as `library.genmodel`. Edit it to change settings, for example the model directory or the compliance level; it opens unchanged in the Eclipse tooling. Running the command again with `--reload library/model/library.genmodel` keeps your settings while the structure follows the Ecore model.

To use your own transformation, give `swift-atl generate --transformations` a file, or a directory that holds `Ecore2GenModel.atl`. The replacement receives the same parameters as the bundled one (see ``GenModelImportConstants/Parameter``).

### From the generator model to Java

```bash
swift-ecore generate --language java library/model/library.genmodel --output src-gen
```

The packages of the model are written below `src-gen`: `src-gen/org/example/library/Book.java`, `src-gen/org/example/library/impl/BookImpl.java`, the package and factory classes, enumerations, and the utility classes. Giving the Ecore model instead imports it into a temporary generator model on the way, and `swift-atl generate library/model/library.ecore --language java --output src-gen` does the same through the ATL command.

A progress bar with the number of files appears on an interactive terminal; with `--verbose` every file is reported on its own line.

### Regenerating

Generating into a directory that holds earlier output merges the new text with the existing files. A member whose documentation comment carries `@generated` is regenerated; mark a member `@generated NOT` to keep your version, or add members without the tag, and they are kept. Two options change this: `--force-overwrite` replaces everything, and `--diff` leaves existing files alone and writes the generated text beside them as `.<name>.new`.

### Customising templates

`--template-path <directory>` (repeatable) replaces bundled template files. A file in that directory replaces the bundled file of the same name, so a directory with one `Header.mtl` changes the file header of every generated file and nothing else:

```text
my-templates/
    Header.mtl
```

```bash
swift-ecore generate --language java library/model/library.genmodel -o src-gen --template-path my-templates
```

Later directories win over earlier ones. Copy a bundled module as the starting point when you only want to change a part of it; modules import each other by name, so replacing `JavaNames.mtl` changes the naming everywhere.

### Adding a language

A language is a template set: a directory with a descriptor, a main module and the modules and data it needs. No Swift changes are needed. Put the directory, named after the language, inside a directory that you pass with `--template-path`:

```text
my-templates/
    outline/
        templateset.json
        generate.mtl
```

`templateset.json`:

```json
{ "name": "outline", "mainModule": "generate", "mainTemplate": "generate" }
```

`generate.mtl`:

```text
[module generate('http://www.eclipse.org/emf/2002/GenModel')/]
[template public generate(genModel : GenModel)]
[file ('outline.txt')]
[for (genPackage : GenPackage | genModel.genPackages)]
[genPackage.ecorePackage.name/]
[for (genClass : GenClass | genPackage.genClasses)]
  [genClass.ecoreClass.name/]
[/for]
[/for]
[/file]
[/template]
```

```bash
swift-ecore generate --language outline library/model/library.genmodel -o out --template-path my-templates
```

Every tool lists the languages that exist in its help, including those that `--template-path` adds. To bundle a set permanently, add its directory to `Sources/ModellingGenerators/Templates`. <doc:TemplateSets> describes the descriptor, the services that templates can call and the merge declaration.

### Using the library

The command line tools are thin layers over ``GenerationPipeline``:

```swift
let model = URL(fileURLWithPath: "library/model/library.ecore")

// Ecore to generator model
var importing = GenModelImportOptions(basePackage: "org.example")
let created = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [model], options: importing)

// Generator model, or Ecore model, to Java
let bar = GenerationProgressBar(verbose: false)
let result = try await GenerationPipeline.generate(
    inputURL: created.url, language: "java",
    outputDirectory: URL(fileURLWithPath: "src-gen"),
    progress: bar.reporter)
bar.finish()
print("\(result.files.count) files")
```

``TemplateSet/availableLanguages(templatePaths:)`` lists the languages that can be generated.
