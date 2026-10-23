# ``ModellingPipeline``

Transformations, generations and template sets run on models held in memory.

## Overview

``ModellingPipeline`` combines the engines of the modelling toolchain into steps that a program runs on models it holds, without going through the command-line tools.

A ``TransformationStep`` parses an ATL module against the metamodels it is given and runs it on source models, with module parameters and helpers implemented in Swift, and returns the target models. A ``GenerationStep`` runs MTL templates, either a template set or a single module, with parameters and further services, and returns the files it wrote. A ``TemplateSetLocator`` finds template sets below a list of resource directories, so that a package ships template sets of its own and finds them like the bundled ones. A ``ModelPipeline`` runs a sequence of steps that load, transform, generate from and save models over one resource set, collects what a conversion could not keep and reports progress.

```swift
let pipeline = ModelPipeline(steps: [
    .registerMetamodels([familiesEcore, personsEcore]),
    .load(name: "families", url: familiesModel),
    .transform(
        TransformationStep(moduleURL: families2Persons),
        sources: ["IN": "families"], targets: ["OUT": "persons"]),
    .generate(
        GenerationStep(templates: .module(reportModule), outputDirectory: reportDirectory),
        arguments: ["persons"]),
    .save(name: "persons", url: personsJSON),
])
let result = try await pipeline.run(progress: { print($0.message) })
print(result.generatedFiles)
```

### Template sets of a package

A package that ships template sets keeps them in a resource directory with a directory for each language, each holding a `templateset.json` descriptor, and adds that directory to the roots of a locator:

```swift
let roots = TemplateSet.defaultBundledRoots + [Bundle.module.url(forResource: "Templates", withExtension: nil)!]
let step = GenerationStep(
    templates: .templateSet("c", locator: TemplateSetLocator(bundledRoots: roots)),
    parameters: ["prefix": "lib"],
    outputDirectory: URL(fileURLWithPath: "Generated"))
let result = try await step.run(arguments: [model])
```

A descriptor can list directories of modules that the set shares with other sets under `imports`, such as `["../expressions"]`, and its modules then import them as `[import expressions::c/]`.

## Topics

### Pipelines

- ``ModelPipeline``
- ``ModelPipelineError``

### Steps

- ``TransformationStep``
- ``GenerationStep``

### Template sets

- ``TemplateSetLocator``
