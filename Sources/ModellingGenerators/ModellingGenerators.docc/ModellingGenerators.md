# ``ModellingGenerators``

Generator models and code generation for the Swift modelling toolchain.

## Overview

``ModellingGenerators`` turns Ecore models into generator models and generator models into source code.

``GenerationPipeline/ecoreToGenModel(ecoreURLs:options:progress:)`` imports Ecore models into a generator model (`.genmodel`) with the settings of Eclipse's headless generator, or optionally of its New EMF Generator Model wizard. ``GenerationPipeline/generate(genModelURL:language:outputDirectory:options:progress:)`` generates code from a generator model with the template set of a language, such as `java`, `swift`, `c` or `cpp`.

``GenerationPipeline/generate(inputURL:language:outputDirectory:importOptions:options:progress:)`` accepts either kind of model and imports an Ecore model on the way. ``GenModelImportOptions/transformation`` replaces the bundled transformation, and ``GenModelImportOptions/defaults`` (a ``GenModelDefaults``, `.headless` unless set) with ``GenModelImportOptions/operationReflection``, ``GenModelImportOptions/rootExtendsClass`` and ``GenModelImportOptions/importOrganizing`` choose the Eclipse settings of the new generator model. See <doc:ConvertingEcoreToJava> for the whole chain from the command line, and <doc:MatchingEclipse> for how the Java output relates to Eclipse's.

A template set is a directory of Model-to-Text templates and data files; the engines, the generator model and the language-neutral services are the only Swift involved. Adding a language means adding a directory, never changing Swift. See <doc:TemplateSets> for the layout, <doc:JavaGeneration> for the Java set, <doc:SwiftGeneration> for the Swift set, <doc:CGeneration> for the C set and <doc:CppGeneration> for the C++ set.

The verification sets, `alloy`, `tla`, `eventb` and `lean`, export a metamodel with its OCL invariants to a formal method, and ``GenerationPipeline/generate(modelURL:metamodelURL:language:outputDirectory:options:progress:)`` exports models of it as well, so that the tools of the method check that a model conforms. See <doc:VerificationExports>.

```swift
let result = try await GenerationPipeline.generate(
    genModelURL: URL(fileURLWithPath: "model/library.genmodel"),
    language: "java",
    outputDirectory: URL(fileURLWithPath: "src-gen"),
    progress: { print($0.message) })
print(result.files.count)
```

## Related Documentation

### Command-Line Tools

- [swift-ecore](https://mipalgu.github.io/swift-modelling/documentation/swift_ecore/index.html) - `genmodel` and `generate` create generator models, code and verification exports
- [swift-atl](https://mipalgu.github.io/swift-modelling/documentation/swift_atl/index.html) - `generate` goes from an Ecore model to code in one step
- [swift-mtl](https://mipalgu.github.io/swift-modelling/documentation/swift_mtl/index.html) - `generate --template-set` runs any template set on models

### Tutorials

- Java Code Generation: [From Ecore to a Generator Model](https://mipalgu.github.io/swift-modelling/tutorials/swiftmodelling/java-01-ecore-to-genmodel/index.html)
- Java Code Generation: [From a Generator Model to Java](https://mipalgu.github.io/swift-modelling/tutorials/swiftmodelling/java-02-genmodel-to-java/index.html)
- Formal Verification Exports: [Checking a Metamodel with Alloy](https://mipalgu.github.io/swift-modelling/tutorials/swiftmodelling/verification-01-alloy/index.html)
- MTL Code Generation: [Complete Code Generator](https://mipalgu.github.io/swift-modelling/tutorials/swiftmodelling/mtl-08-complete-generator/index.html)
- [All tutorials](https://mipalgu.github.io/swift-modelling/tutorials/tutorials/index.html)

### Libraries

- [GenModel](https://mipalgu.github.io/swift-ecore/documentation/genmodel/) of [swift-ecore](https://mipalgu.github.io/swift-ecore/) - Eclipse generator models
- [OCL](https://mipalgu.github.io/swift-ecore/documentation/ocl/) of [swift-ecore](https://mipalgu.github.io/swift-ecore/) - The OCL invariants that the verification exports translate
- [MTL](https://mipalgu.github.io/swift-mtl/documentation/mtl/) of [swift-mtl](https://mipalgu.github.io/swift-mtl/) - The template engine that runs the template sets
- [ATL](https://mipalgu.github.io/swift-atl/documentation/atl/) of [swift-atl](https://mipalgu.github.io/swift-atl/) - The transformation engine that imports Ecore models into generator models

## Topics

### Articles

- <doc:ConvertingEcoreToJava>
- <doc:MatchingEclipse>
- <doc:GettingStarted>
- <doc:TemplateSets>
- <doc:JavaGeneration>
- <doc:SwiftGeneration>
- <doc:CGeneration>
- <doc:CppGeneration>
- <doc:VerificationExports>

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

### Verification exports

- ``VerificationTarget``
- ``VerificationServices``
- ``VerificationServiceName``
- ``VerificationKindName``

### Saving models together

- ``DocumentRelocation``
- ``DocumentRelocationError``
