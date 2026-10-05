# Swift Modelling

The
[swift-modelling](https://github.com/mipalgu/swift-modelling)
package provides a comprehensive Model-Driven Engineering (MDE)
toolkit with CLI tools for working with Ecore, ATL, and MTL.

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
- macOS 15.0+ or Linux

## References

- [Eclipse Modeling Framework (EMF)](https://eclipse.dev/emf/)
- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [OMG MOF (Meta Object Facility)](https://www.omg.org/mof/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)

## Related Packages

- [swift-ecore](https://github.com/mipalgu/swift-ecore) - EMF/Ecore metamodelling
- [swift-atl](https://github.com/mipalgu/swift-atl) - ATL model transformations
- [swift-mtl](https://github.com/mipalgu/swift-mtl) - MTL code generation
- [swift-aql](https://github.com/mipalgu/swift-aql) - AQL model queries

## Documentation

The package provides three CLI tools: swift-ecore for model
validation and conversion, swift-atl for model-to-model
transformations, and swift-mtl for template-based code generation.
For converting Ecore models into generator models and Java, see
[Converting Ecore to GenModel and Java](documentation/modellinggenerators/convertingecoretojava/index.html)
and [Matching Eclipse](documentation/modellinggenerators/matchingeclipse/index.html).
For the rest, see the [SwiftModelling](documentation/swiftmodelling/swiftmodelling/index.html)
overview and its [tutorials](tutorials/tutorials/index.html).
