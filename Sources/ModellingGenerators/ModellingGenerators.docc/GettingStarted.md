# Getting Started

Change the templates, add a language and call the generator from Swift.

## Overview

The first step is to convert a model; <doc:ConvertingEcoreToJava> walks through that with the extended library example of the Eclipse Modeling Framework, and <doc:MatchingEclipse> explains how the output relates to Eclipse's. In short:

```bash
swift-ecore genmodel library/model/library.ecore --base-package org.example
swift-ecore generate --language java library/model/library.genmodel --output src-gen
```

The first command writes `library/model/library.genmodel` beside the Ecore model; the second writes the Java packages below `src-gen`. The Eclipse layout `library/model/library.ecore` names the project `library`. `swift-atl generate library/model/library.ecore --language java --output src-gen` does both in one step.

To use your own Ecore-to-generator-model transformation, give `swift-atl generate --transformations` a file, or a directory that holds `Ecore2GenModel.atl`. The replacement receives the same parameters as the bundled one (see ``GenModelImportConstants/Parameter``).

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

Every tool lists the bundled languages in its help; a language that `--template-path` adds is accepted but not listed there, and an unknown language is rejected with every language that can be used. To bundle a set permanently, add its directory to `Sources/ModellingGenerators/Templates`. <doc:TemplateSets> describes the descriptor, the services that templates can call and the merge declaration.

### Using the library

The command line tools are thin layers over ``GenerationPipeline``:

```swift
let model = URL(fileURLWithPath: "library/model/library.ecore")

// Ecore to generator model
let importing = GenModelImportOptions(basePackage: "org.example", defaults: .wizard)
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
