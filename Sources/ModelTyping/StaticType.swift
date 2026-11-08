//
//  StaticType.swift
//  ModelTyping
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import Foundation

/// The statically inferred type of an expression during footprint extraction.
///
/// Inference is deliberately shallow: it follows navigations, iterators,
/// type casts and helper or query signatures, and gives up with ``unknown``
/// where a precise type would need full OCL type checking.
public indirect enum StaticType: Sendable, Hashable, CustomStringConvertible {
    /// An instance of a class of a metamodel.
    case object(metamodel: String, className: String)
    /// A literal of an enumeration of a metamodel.
    case enumeration(metamodel: String, name: String)
    /// A data value, named by its canonical category or primitive type name.
    case dataValue(String)
    /// A collection of values of the element type.
    case collection(StaticType)
    /// A class used as a value, as in `Type.allInstances()`.
    case typeLiteral(metamodel: String, className: String)
    /// The ATL transformation module itself (`thisModule`).
    case module
    /// A type that could not be inferred.
    case unknown

    /// The type of the elements, or the type itself if it is not a collection.
    public var elementType: StaticType {
        if case .collection(let element) = self { return element.elementType }
        return self
    }

    /// Whether the type is a collection type.
    public var isCollection: Bool {
        if case .collection = self { return true }
        return false
    }

    /// Whether the type could not be inferred.
    public var isUnknown: Bool { self == .unknown }

    /// A collection of this type's elements, flattening nested collections.
    public var flattenedCollection: StaticType { .collection(elementType) }

    /// The type written in a compact form for diagnostics.
    public var description: String {
        switch self {
        case .object(let metamodel, let className): return "\(metamodel)!\(className)"
        case .enumeration(let metamodel, let name): return "\(metamodel)!\(name)"
        case .dataValue(let name): return name
        case .collection(let element): return "Collection(\(element))"
        case .typeLiteral(let metamodel, let className): return "type \(metamodel)!\(className)"
        case .module: return ModelTypingVocabulary.thisModuleVariable
        case .unknown: return "?"
        }
    }
}

/// A type name as written in ATL, MTL or AQL source, split into its parts.
///
/// Written types may wrap a classifier name in collection constructors
/// (`Sequence(MM!Class)`, `OrderedSet(pkg::Class)`) and qualify it with a
/// metamodel or package name using `!` or `::`.
public struct WrittenTypeName: Sendable, Hashable {
    /// The number of collection constructors around the classifier name.
    public let collectionDepth: Int
    /// The metamodel or package qualifier, if the name is qualified.
    public let qualifier: String?
    /// The simple classifier name.
    public let name: String

    /// Parses a written type name.
    ///
    /// - Parameter text: The type as written in source.
    public init(_ text: String) {
        var remainder = text.trimmingCharacters(in: .whitespaces)
        var depth = 0
        while let open = remainder.firstIndex(of: "("), remainder.hasSuffix(")") {
            let constructor = String(remainder[..<open]).trimmingCharacters(in: .whitespaces)
            guard ModelTypingVocabulary.collectionTypeConstructors.contains(constructor) else { break }
            remainder = String(remainder[remainder.index(after: open)..<remainder.index(before: remainder.endIndex)])
                .trimmingCharacters(in: .whitespaces)
            depth += 1
        }
        let split = ModelType.splitQualifiedName(remainder)
        self.collectionDepth = depth
        self.qualifier = split.qualifier
        self.name = split.name
    }

    /// Whether the classifier name is a primitive type of OCL, ATL, AQL or MTL.
    public var isPrimitive: Bool {
        qualifier == nil && (ModelTypingVocabulary.primitiveTypeNames.contains(name)
            || name.hasPrefix("TupleType") || name.hasPrefix("Map"))
    }
}
