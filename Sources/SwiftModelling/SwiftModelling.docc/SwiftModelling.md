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

## Topics

### Tutorials

- <doc:Tutorials>