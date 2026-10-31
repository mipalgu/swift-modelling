# SwiftModelling

Build powerful Model-Driven Engineering (MDE) applications with Swift.

## Overview

SwiftModelling provides a comprehensive suite of CLI tools for Model-Driven Engineering using Swift 6. Transform, validate, and generate code from your models with industry-standard technologies including Ecore, ATL, MTL, and AQL.

### Key Technologies

- **Ecore**: EMF-compatible metamodelling and model validation
- **ATL**: Atlas Transformation Language for model-to-model transformations
- **MTL**: Model-to-Text Language for code generation
- **AQL**: Advanced Query Language for model analysis

### CLI Tools

- swift-ecore: Model validation, conversion, querying, generator models and code generation
- swift-atl: Model transformation execution and generation from Ecore models
- swift-mtl: Template-based code generation

### From Ecore to Java

Convert an Ecore model into an Eclipse generator model (`.genmodel`) and into Java that compiles against the EMF runtime, with `swift-ecore genmodel` and `swift-ecore generate --language java`, or in one step with `swift-atl generate --language java`.

- Converting Ecore to GenModel and Java: the commands, every option and the files written, with the Eclipse extended library example.
- Matching Eclipse: how the output relates to Eclipse's generator, and the options that choose between its behaviours.
- Both articles belong to the ModellingGenerators documentation, which also covers template sets and Java generation. Find them in the sidebar or on the front page of this site.
- <doc:Tutorials>: a step-by-step tutorial on the same conversion.

### From Ecore to Swift

Generate Swift model code that compiles against the ECore runtime, from an Ecore model or a generator model, with `swift-ecore generate` (Swift is its default language) or `swift-atl generate --language swift`. The code is written by the bundled `swift` template set, so it can be customised with `--template-path` like the Java output.

- Swift Generation: what the set writes for classes, enumerations, data types, packages and factories, how names are made safe, and how existing files are merged. Find it in the ModellingGenerators documentation.

### Compatibility with 0.6

The tools follow the behaviour of this release by default. `--semantics legacy` selects the behaviour of version 0.6 for every behaviour that changed, and one option for each behaviour overrides the preset:

- Templates (`swift-mtl generate`, `swift-ecore generate`, `swift-atl generate`): `--block-line-breaks acceleo|kept`, `--collection-parameters conforming|exact`, `--check-let-types` or `--no-check-let-types`, `--cache-containers` or `--no-cache-containers`, `--collection-arguments whole|first-element`, `--collection-kinds distinguished|sequences`, `--single-value-collections set|sequence` and `--container-lookup resources|registered-objects`.
- ATL source (`swift-atl parse`, `validate`, `analyze`, `compile`, `test`, `transform`, `query`, and `generate` for a transformation given with `--transformations`): `--collection-range-syntax ocl|eclipse`.
- Models (every command that accepts `--semantics`): `--container-scope any-resource|this-resource`, whether a model finds the containers of objects of the other models of the run.

The first value of each option is the default, and the second that of version 0.6. The help of each command and the documentation of each tool describe the options.

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable and then the `semantics` key of a configuration file choose the preset. The configuration file is the first `.swift-modelling.json` in the current directory or one of its parents, up to the root of the repository, unless `--config` names another file or `--no-config` is given. Its keys are the names of the options, and they override the preset but not the command line:

| Precedence | Source |
|--|--|
| 1 | A behaviour option on the command line |
| 2 | The same option in the configuration file |
| 3 | `--semantics` |
| 4 | `SWIFT_MODELLING_SEMANTICS` |
| 5 | `semantics` in the configuration file |
| 6 | The default, `standard` |

## Topics

### Tutorials

- <doc:Tutorials>