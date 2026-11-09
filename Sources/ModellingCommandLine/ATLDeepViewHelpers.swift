//
// ATLDeepViewHelpers.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQLMultiLevel
import ATL
import ECore
import EMFBase
import MultiLevel

/// The helpers that ATL transformations and queries call on the objects and types of deep views.
///
/// They offer ATL the services of `AQLMultiLevelServices` under the same names. Each helper is
/// declared for `OclAny` and gives `OclUndefined` for a receiver that stands for no clabject
/// of the deep views, or, for the helpers on types, for a receiver that is no type.
///
/// On an object of a view:
/// - `clabjectName()`: the name of its clabject, a `String`
/// - `ontologicalType()`: the class of its ontological type
/// - `linguisticType()`: `'Node'` or `'Edge'`
/// - `level()`: its level, an `Integer`
/// - `potency()`: its potency, an `Integer`, or `'*'` for an unbounded potency
/// - `deepTypes()`: the classes of its deep types, nearest first, as a `Sequence`
/// - `typeAtLevel(n)`: the object that stands for its ontological type at level `n`
/// - `slotValue('f')`: the value of the feature `f`, looked up along its type chain; a
///   `Sequence` if the feature holds several values
/// - `isDeepInstanceOf(T)`: whether it is a direct or indirect instance of the type `T`
///
/// On a type, given as a type such as `Bookshop!ProductType` or as a class of a view, such as
/// the value of `ontologicalType()`:
/// - `deepInstances()`: the objects of its direct and indirect instances at every level, as a
///   `Sequence`
/// - `instancesAtLevel(n)`: the objects of its direct and indirect instances at level `n`, as a
///   `Sequence`
///
/// Types are matched by the name of their clabjects, as in AQL.
public enum ATLDeepViewHelpers {
    /// The type that the helpers are declared for, so that every value receives them.
    public static let contextType = "OclAny"

    /// The separator between a metamodel name and a type name in an ATL type, as in
    /// `Bookshop!ProductType`.
    public static let typeSeparator: Character = "!"

    /// The names of the helpers, in the order of ``helpers(for:)``.
    public static let names = [
        AQLMultiLevelServiceName.clabjectName,
        AQLMultiLevelServiceName.ontologicalType,
        AQLMultiLevelServiceName.linguisticType,
        AQLMultiLevelServiceName.level,
        AQLMultiLevelServiceName.potency,
        AQLMultiLevelServiceName.deepTypes,
        AQLMultiLevelServiceName.typeAtLevel,
        AQLMultiLevelServiceName.slotValue,
        AQLMultiLevelServiceName.isDeepInstanceOf,
        AQLMultiLevelServiceName.deepInstances,
        AQLMultiLevelServiceName.instancesAtLevel,
    ]

    /// The ATL type names of the results and parameters of the helpers.
    enum TypeName {
        /// A string.
        static let string = "String"
        /// An integer.
        static let integer = "Integer"
        /// A Boolean value.
        static let boolean = "Boolean"
        /// A type.
        static let type = "OclType"
        /// Any value.
        static let any = "OclAny"
        /// A sequence of any values.
        static let sequence = "Sequence(OclAny)"
    }

    /// The error raised when a helper receives an argument of the wrong kind.
    struct ArgumentError: Error, CustomStringConvertible {
        /// The name of the helper.
        let helper: String

        /// The kind of argument that the helper expects.
        let expected: String

        /// The helper and the kind of argument it expects, as one sentence.
        var description: String { "\(helper)() expects \(expected) as its argument" }
    }

    /// The name of the type that a value denotes.
    ///
    /// - Parameters:
    ///   - value: A type such as `Bookshop!ProductType`, which ATL evaluates to its qualified
    ///     name, a class of one of the views, or, if `acceptsNames` is `true`, a type name.
    ///   - views: The deep views of the multi-level models of the run.
    ///   - acceptsNames: Whether a string without a metamodel name names a type.
    /// - Returns: The name of the type, or `nil` if the value denotes no type.
    static func typeName(of value: (any EcoreValue)?, in views: [DeepModelViews], acceptsNames: Bool) -> String? {
        if let eClass = value as? EClass {
            return views.lazy.compactMap { $0.clabject(ofClass: eClass)?.name }.first
        }
        guard let text = value as? String, !text.isEmpty else { return nil }
        guard let separator = text.lastIndex(of: typeSeparator) else { return acceptsNames ? text : nil }
        let name = String(text[text.index(after: separator)...])
        return name.isEmpty ? nil : name
    }

    /// The helpers for the objects and types of deep views.
    ///
    /// - Parameter views: The deep views of the multi-level models of a run.
    /// - Returns: A helper for each name of ``names``, or none if no view is given.
    public static func helpers(for views: [DeepModelViews]) -> [ATLNativeHelper] {
        guard !views.isEmpty else { return [] }
        return objectHelpers(for: views) + typeHelpers(for: views)
    }

    /// The views of the model that a value stands for, with its clabject.
    ///
    /// - Parameters:
    ///   - value: Any value.
    ///   - views: The deep views of the multi-level models of a run.
    /// - Returns: The views and the clabject, or `nil` if the value stands for no clabject.
    static func lookup(_ value: (any EcoreValue)?, in views: [DeepModelViews]) -> (
        views: DeepModelViews, clabject: Clabject
    )? {
        for candidate in views {
            if let clabject = candidate.clabject(of: value) { return (candidate, clabject) }
        }
        return nil
    }

    /// The helpers on the objects of the views.
    ///
    /// - Parameter views: The deep views of the multi-level models of a run.
    /// - Returns: The helpers, in the order of ``names``.
    static func objectHelpers(for views: [DeepModelViews]) -> [ATLNativeHelper] {
        [
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.clabjectName, contextType: contextType, returnType: TypeName.string
            ) { receiver, _ in
                lookup(receiver, in: views)?.clabject.name
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.ontologicalType, contextType: contextType, returnType: TypeName.type
            ) { receiver, _ in
                lookup(receiver, in: views)?.views.ontologicalClass(of: receiver)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.linguisticType, contextType: contextType, returnType: TypeName.string
            ) { receiver, _ in
                lookup(receiver, in: views).map {
                    $0.clabject.isEdge ? MultiLevelSyntax.edgeKeyword : MultiLevelSyntax.nodeKeyword
                }
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.level, contextType: contextType, returnType: TypeName.integer
            ) { receiver, _ in
                guard let found = lookup(receiver, in: views) else { return nil }
                return found.views.model.level(of: found.clabject.id)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.potency, contextType: contextType, returnType: TypeName.any
            ) { receiver, _ in
                guard let found = lookup(receiver, in: views), let potency = found.views.model.potency(of: found.clabject.id)
                else { return nil }
                return potency.finiteValue.map { $0 as any EcoreValue } ?? potency.description
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.deepTypes, contextType: contextType, returnType: TypeName.sequence
            ) { receiver, _ in
                guard let classes = lookup(receiver, in: views)?.views.deepTypeClasses(of: receiver) else { return nil }
                return ATLCollectionValue(kind: .sequence, values: classes)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.typeAtLevel, contextType: contextType,
                parameterTypes: [TypeName.integer], returnType: TypeName.any
            ) { receiver, arguments in
                guard let level = arguments.first.flatMap({ $0 as? Int }) else {
                    throw ArgumentError(helper: AQLMultiLevelServiceName.typeAtLevel, expected: "an Integer level")
                }
                guard let found = lookup(receiver, in: views) else { return nil }
                return await found.views.typeObject(of: receiver, atLevel: level)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.slotValue, contextType: contextType,
                parameterTypes: [TypeName.string], returnType: TypeName.any
            ) { receiver, arguments in
                guard let feature = arguments.first.flatMap({ $0 as? String }) else {
                    throw ArgumentError(helper: AQLMultiLevelServiceName.slotValue, expected: "a String feature name")
                }
                guard let found = lookup(receiver, in: views),
                    let values = await found.views.slotValues(of: receiver, feature: feature)
                else { return nil }
                return values.count == 1 ? values[0] : ATLCollectionValue(kind: .sequence, values: values)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.isDeepInstanceOf, contextType: contextType,
                parameterTypes: [TypeName.type], returnType: TypeName.boolean
            ) { receiver, arguments in
                guard let typeName = typeName(of: arguments.first ?? nil, in: views, acceptsNames: true) else {
                    throw ArgumentError(helper: AQLMultiLevelServiceName.isDeepInstanceOf, expected: "a type")
                }
                return lookup(receiver, in: views)?.views.isDeepInstance(receiver, ofTypeNamed: typeName)
            },
        ]
    }

    /// The helpers on the types of the views.
    ///
    /// - Parameter views: The deep views of the multi-level models of a run.
    /// - Returns: The helpers, in the order of ``names``.
    static func typeHelpers(for views: [DeepModelViews]) -> [ATLNativeHelper] {
        @Sendable func instances(of receiver: (any EcoreValue)?, atLevel level: Int?) async -> (any EcoreValue)? {
            guard let typeName = typeName(of: receiver, in: views, acceptsNames: false) else { return nil }
            var objects: [any EcoreValue] = []
            for candidate in views {
                objects += await candidate.deepInstanceObjects(ofTypeNamed: typeName, atLevel: level) as [any EcoreValue]
            }
            return ATLCollectionValue(kind: .sequence, values: objects)
        }
        return [
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.deepInstances, contextType: contextType, returnType: TypeName.sequence
            ) { receiver, _ in
                await instances(of: receiver, atLevel: nil)
            },
            ATLNativeHelper(
                name: AQLMultiLevelServiceName.instancesAtLevel, contextType: contextType,
                parameterTypes: [TypeName.integer], returnType: TypeName.sequence
            ) { receiver, arguments in
                guard let level = arguments.first.flatMap({ $0 as? Int }) else {
                    throw ArgumentError(helper: AQLMultiLevelServiceName.instancesAtLevel, expected: "an Integer level")
                }
                return await instances(of: receiver, atLevel: level)
            },
        ]
    }
}
