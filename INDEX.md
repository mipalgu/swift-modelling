# Swift Modelling

The
[swift-modelling](https://github.com/mipalgu/swift-modelling)
package provides a comprehensive Model-Driven Engineering (MDE)
toolkit with seven command-line tools for working with Ecore, AQL,
MTL, ATL, Henshin, Epsilon and Xtend, together with code generators
and step-by-step tutorials.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mipalgu/swift-modelling.git",
             branch: "main"),
]
```

## Requirements

- Swift 6.0 or later
- macOS 15.0+, Linux, or Windows

## References

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)

## Related Packages

- [swift-ecore](https://mipalgu.github.io/swift-ecore/) - EMF/Ecore metamodelling, OCL, generator models and multi-level modelling ([GitHub](https://github.com/mipalgu/swift-ecore))
- [swift-aql](https://mipalgu.github.io/swift-aql/) - AQL model queries ([GitHub](https://github.com/mipalgu/swift-aql))
- [swift-mtl](https://mipalgu.github.io/swift-mtl/) - MTL model-to-text generation ([GitHub](https://github.com/mipalgu/swift-mtl))
- [swift-atl](https://mipalgu.github.io/swift-atl/) - ATL model transformations ([GitHub](https://github.com/mipalgu/swift-atl))
- [swift-henshin](https://mipalgu.github.io/swift-henshin/) - Henshin graph transformation, critical pair analysis and state-space exploration ([GitHub](https://github.com/mipalgu/swift-henshin))
- [swift-epsilon](https://mipalgu.github.io/swift-epsilon/) - Epsilon model management languages (EOL, EVL, ETL and EGL) ([GitHub](https://github.com/mipalgu/swift-epsilon))
- [swift-xtend](https://mipalgu.github.io/swift-xtend/) - Xtend generators and transformations ([GitHub](https://github.com/mipalgu/swift-xtend))

## Documentation

The package provides seven command-line tools:

- [swift-ecore](documentation/swift_ecore/index.html) - Model validation, conversion,
  querying, generator models and code generation
- [swift-aql](documentation/swift_aql/index.html) - Evaluation of AQL queries against models
- [swift-mtl](documentation/swift_mtl/index.html) - Template-based code generation
- [swift-atl](documentation/swift_atl/index.html) - Model-to-model transformations and
  generation from Ecore models
- [swift-henshin](documentation/swift_henshin/index.html) - Henshin graph transformation,
  analysis and state-space exploration
- [swift-epsilon](documentation/swift_epsilon/index.html) - EOL programs, EVL constraints,
  ETL transformations and EGL templates
- [swift-xtend](documentation/swift_xtend/index.html) - Xtend methods and generators run on
  models

The libraries [ModellingGenerators](documentation/modellinggenerators/index.html),
[ModellingPipeline](documentation/modellingpipeline/index.html),
[ModelTyping](documentation/modeltyping/index.html) and
[ModellingCommandLine](documentation/modellingcommandline/index.html) offer the code
generators, the pipelines, the model typing checks and the shared command-line options to
other packages.

For converting Ecore models into generator models and Java, see
[Converting Ecore to GenModel and Java](documentation/modellinggenerators/convertingecoretojava/index.html)
and [Matching Eclipse](documentation/modellinggenerators/matchingeclipse/index.html).
For the rest, see the [SwiftModelling](documentation/swiftmodelling/swiftmodelling/index.html)
overview and its [tutorials](tutorials/tutorials/index.html), which introduce
every tool step by step.
