# ``ModellingGenerators``

Generator models and code generation for the Swift modelling toolchain.

## Overview

``ModellingGenerators`` turns Ecore models into generator models and generator models into source code.

``GenerationPipeline/ecoreToGenModel(ecoreURLs:options:progress:)`` imports Ecore models into a generator model (`.genmodel`) with the settings of Eclipse's headless generator, or optionally of its New EMF Generator Model wizard. ``GenerationPipeline/generate(genModelURL:language:outputDirectory:options:progress:)`` generates code from a generator model with the template set of a language, such as `java`.

``GenerationPipeline/generate(inputURL:language:outputDirectory:importOptions:options:progress:)`` accepts either kind of model and imports an Ecore model on the way. ``GenModelImportOptions/transformation`` replaces the bundled transformation, and ``GenModelImportOptions/defaults`` (a ``GenModelDefaults``, `.headless` unless set) with ``GenModelImportOptions/operationReflection``, ``GenModelImportOptions/rootExtendsClass`` and ``GenModelImportOptions/importOrganizing`` choose the Eclipse settings of the new generator model. See <doc:ConvertingEcoreToJava> for the whole chain from the command line, and <doc:MatchingEclipse> for how the Java output relates to Eclipse's.

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

- <doc:ConvertingEcoreToJava>
- <doc:MatchingEclipse>
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
