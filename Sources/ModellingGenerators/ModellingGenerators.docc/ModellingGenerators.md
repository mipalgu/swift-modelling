# ``ModellingGenerators``

Generator models and code generation for the Swift modelling toolchain.

## Overview

``ModellingGenerators`` turns Ecore models into generator models and generator models into source code.

``GenerationPipeline/ecoreToGenModel(ecoreURLs:options:progress:)`` imports Ecore models into a generator model (`.genmodel`) with the settings that the Eclipse Ecore importer gives a new model. ``GenerationPipeline/generate(genModelURL:language:outputDirectory:options:progress:)`` generates code from a generator model with the template set of a language, such as `java`.

``GenerationPipeline/generate(inputURL:language:outputDirectory:importOptions:options:progress:)`` accepts either kind of model and imports an Ecore model on the way. ``GenModelImportOptions/transformation`` replaces the bundled transformation. See <doc:GettingStarted> for the whole chain.

A template set is a directory of Model-to-Text templates and data files; the engines, the generator model and the language-neutral services are the only Swift involved. Adding a language means adding a directory, never changing Swift. See <doc:TemplateSets> for the layout and <doc:JavaGeneration> for the Java set.

```swift
let result = try await GenerationPipeline.generate(
    genModelURL: URL(fileURLWithPath: "model/library.genmodel"),
    language: "java",
    outputDirectory: URL(fileURLWithPath: "src-gen"),
    progress: { print($0.message) })
print(result.files.count)
```

## Topics

### Articles

- <doc:GettingStarted>
- <doc:TemplateSets>
- <doc:JavaGeneration>

### Importing Ecore models

- ``GenerationPipeline``
- ``GenModelImportOptions``
- ``GenModelDefaults``
- ``GenModelResult``

### Generating code

- ``GenerationOptions``
- ``GenerationProgressUpdate``
- ``GenerationProgressReporter``
- ``GenerationProgressBar``
- ``GenerationResult``
- ``GenerationError``

### Template sets

- ``TemplateSet``
- ``TemplateSetDescriptor``
- ``TemplateSetConstants``

### Template services

- ``GenModelServices``
- ``GenModelServiceName``
- ``TemplateDataServices``
