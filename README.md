# Swift Modelling

[![CI](https://github.com/mipalgu/swift-modelling/actions/workflows/ci.yml/badge.svg)](https://github.com/mipalgu/swift-modelling/actions/workflows/ci.yml)
[![Documentation](https://github.com/mipalgu/swift-modelling/actions/workflows/documentation.yml/badge.svg)](https://github.com/mipalgu/swift-modelling/actions/workflows/documentation.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmipalgu%2Fswift-modelling%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mipalgu/swift-modelling)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmipalgu%2Fswift-modelling%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mipalgu/swift-modelling)
[![License](https://img.shields.io/badge/License-BSD%204--Clause%20or%20GPL%202.0+-blue.svg)](https://github.com/mipalgu/swift-modelling/blob/main/LICENCE)

Command-line tools and libraries for model-driven engineering in pure Swift.

Swift Modelling reads, checks, transforms and generates from models without Java. It supports
the [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/), the
[Atlas Transformation Language (ATL)](https://eclipse.dev/atl/), the
[OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/) standard and
the Acceleo Query Language (AQL), and aims to stay compatible with the Eclipse tools.

## Features

- **swift-ecore**: validate, inspect, compare, measure, query, create and convert Ecore
  metamodels and models in XMI and JSON, including their OCL invariants
- **Code generation**: Eclipse-compatible generator models (`.genmodel`) and model code in Java,
  Swift, C and C++, from template sets that a new language can join without Swift code
- **swift-atl**: run, check and analyse ATL transformations and queries written for Eclipse ATL
- **swift-mtl**: generate text from MTL templates and template sets, merging with existing files
- **swift-aql**: evaluate AQL expressions against models, interactively or in scripts
- **swift-henshin**: apply, validate, analyse and explore Henshin graph transformations
- **swift-epsilon**: run Epsilon EOL programs, EVL constraints, ETL transformations and EGL templates
- **swift-xtend**: run Xtend methods and generators on models
- **Cross-platform**: macOS, Linux, Windows and WebAssembly

## Requirements

- Swift 6.0 or later
- macOS 15.0+, Linux, or Windows

## Installation

### Homebrew (macOS / Linux)

```bash
brew tap mipalgu/tap
brew install swift-modelling
```

This installs `swift-ecore`, `swift-atl`, `swift-mtl` and `swift-aql`.

### Windows

Download `swift-modelling-vX.Y.Z-windows-x86_64.zip` from
[GitHub Releases](https://github.com/mipalgu/swift-modelling/releases), extract it, and add the
executables to your PATH.

### WebAssembly (WASI)

Download `swift-modelling-vX.Y.Z-wasm32-wasi.tar.gz` and its SHA256 file from
[GitHub Releases](https://github.com/mipalgu/swift-modelling/releases). The archive holds
`swift-ecore.wasm`, `swift-atl.wasm`, `swift-mtl.wasm`, `swift-aql.wasm` and their resource
directories; keep these directories beside the modules. Run a module with a WASI runtime, such as
the `wasmkit` runtime of the Swift 6.4 toolchain:

```bash
cd swift-modelling-vX.Y.Z-wasm32-wasi
wasmkit run --stack-size 67108864 --env TMPDIR=. --dir . swift-ecore.wasm --help
```

`--dir .` grants access to the extracted resources and to the models in that directory, and
`TMPDIR=.` keeps generation scratch files there. Grant access to other directories as needed.

## Building from Source

```bash
swift build
swift run swift-ecore --help
```

## Quick Start

### swift-ecore

```bash
# Validate a model against its metamodel, including the OCL invariants of the metamodel
swift-ecore validate instance.xmi --metamodel schema.ecore

# Convert a model from XMI to JSON, with the classes and references of its metamodel
swift-ecore convert library.xmi library.json --metamodel library.ecore

# Show every class of a metamodel with its features
swift-ecore inspect metamodel.ecore --detail full

# Report what changed between two versions of a metamodel
swift-ecore compare legacy.ecore improved.ecore

# Find the objects of a class or of its subclasses
swift-ecore query model.xmi --query "find Person"
```

### From Ecore to a Programming Language

<!-- from-ecore-to-language:begin -->
```bash
# Two steps: write example.genmodel, then generate Java from it
swift-ecore genmodel example.ecore --base-package org.example
swift-ecore generate --language java example.genmodel --output src-gen

# One step: no generator model is left behind
swift-atl generate example.ecore --language java --base-package org.example --output src-gen

# Swift (the default language), C or C++ from an Ecore model
swift-ecore generate model/library.ecore --output Sources/Library/
swift-ecore generate model/library.ecore --language c --output c-src/
```
<!-- from-ecore-to-language:end -->

### swift-atl

```bash
# Run a transformation
swift-atl transform Families2Persons.atl --source families.xmi --target persons.xmi

# Check a transformation against its metamodels without running it
swift-atl transform Families2Persons.atl --validate-only \
  --source-metamodel Families.ecore --target-metamodel Persons.ecore

# Evaluate a query that writes a dot file below graphs/
swift-atl query Flow2Dot.atl --source order.xmi --output-directory graphs
```

### swift-mtl

```bash
# Generate text from a template and a model
swift-mtl generate template.mtl --model input.xmi --output generated/

# Run a template set instead of a single template
swift-mtl generate --template-set my-set/ --model input.xmi --output generated/

# Check the syntax of templates
swift-mtl validate template.mtl
```

### swift-aql

```bash
# Navigate from the root object, which is bound to its class name (company for a Company)
swift-aql evaluate --model company-data.xmi --expression "company.departments.name"

# Evaluate from an object selected by its xmi:id, fragment path or name
swift-aql query company-model.xmi --query "self.employees" --context company1
```

## Documentation

The [Swift Modelling documentation](https://mipalgu.github.io/swift-modelling/) describes every
command and option, and the [tutorials](https://mipalgu.github.io/swift-modelling/tutorials/tutorials/index.html)
introduce each tool step by step.

- [swift-ecore](https://mipalgu.github.io/swift-modelling/documentation/swift_ecore/index.html):
  metamodels and models
- [swift-atl](https://mipalgu.github.io/swift-modelling/documentation/swift_atl/index.html):
  ATL transformations, queries and generation
- [swift-mtl](https://mipalgu.github.io/swift-modelling/documentation/swift_mtl/index.html):
  MTL templates and template sets
- [swift-aql](https://mipalgu.github.io/swift-modelling/documentation/swift_aql/index.html):
  AQL queries
- [SwiftModelling](https://mipalgu.github.io/swift-modelling/documentation/swiftmodelling/swiftmodelling/index.html):
  architecture, interoperability, and compatibility with earlier releases
- [ModellingGenerators](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/index.html):
  generator models, template sets, and [converting Ecore to Java](https://mipalgu.github.io/swift-modelling/documentation/modellinggenerators/convertingecoretojava/index.html)
- [ModellingPipeline](https://mipalgu.github.io/swift-modelling/documentation/modellingpipeline/index.html)
  and [ModellingCommandLine](https://mipalgu.github.io/swift-modelling/documentation/modellingcommandline/index.html):
  libraries for other packages and tools

## Licence

See the details in the LICENCE file.

## References

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/) - The reference EMF implementation
- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/) - The reference ATL implementation
- [Eclipse Acceleo](https://eclipse.dev/acceleo/) - The reference MTL implementation
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/) - The metamodelling standard
- [OMG XMI (XML Metadata Interchange)](https://www.omg.org/spec/XMI/) - The XML serialisation format
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/) - The model transformation standard
- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/) - The model-to-text standard
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/) - The constraint and query language
