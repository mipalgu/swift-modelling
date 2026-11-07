//
// VerificationServices.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation

/// The names of the services that the verification template sets call.
public enum VerificationServiceName {
    /// `name.verificationIdentifier(target)`: a model name made safe as an identifier.
    public static let identifier = "verificationIdentifier"
    /// `enumName.verificationLiteral(literalName, target)`: the identifier of an enumeration literal.
    public static let literal = "verificationLiteral"
    /// `className.verificationFeature(featureName, target)`: the identifier of a feature.
    public static let feature = "verificationFeature"
    /// `text.verificationString(target)`: the literal that denotes a string.
    public static let string = "verificationString"
    /// `classifier.verificationKind()`: how the exports interpret the values of a classifier:
    /// `integer`, `boolean`, `string`, `enumeration`, `object` or `uninterpreted`.
    public static let kind = "verificationKind"
    /// `package.verificationInvariants(eClass)`: the names of the constraints of a class.
    public static let invariants = "verificationInvariants"
    /// `package.verificationInvariantBody(eClass, name)`: the OCL text of a constraint, or null.
    public static let invariantBody = "verificationInvariantBody"
    /// `package.verificationFormula(eClass, name, target[, primed])`: the translated constraint, or null;
    /// with `primed`, the classes and features that Event-B machines declare as variables are primed.
    public static let formula = "verificationFormula"
    /// `package.verificationProblem(eClass, name, target)`: why a constraint is not translated, or null.
    public static let problem = "verificationProblem"
}

/// The names of the kinds of values that ``VerificationServiceName/kind`` reports.
public enum VerificationKindName {
    /// Integers.
    public static let integer = "integer"
    /// Truth values.
    public static let boolean = "boolean"
    /// Text.
    public static let string = "string"
    /// Enumeration literals.
    public static let enumeration = "enumeration"
    /// Objects of a class.
    public static let object = "object"
    /// Values of a data type that the exports do not interpret.
    public static let uninterpreted = "uninterpreted"
}

/// Offers the translation of OCL invariants and the naming rules of the targets to templates.
///
/// The template sets of the verification targets write the structure of a metamodel themselves,
/// and call these services for what MTL cannot express: parsing and translating the OCL text of
/// invariants, and the identifiers that the translated formulas use, so that the declarations
/// written by the templates and the formulas always agree.
///
/// Each service that takes a package translates against that package and its nested packages.
/// The translator of a package is built on first use and kept for the lifetime of the provider.
///
/// ## Example
///
/// ```
/// [for (name : String | ePackage.verificationInvariants(eClass))]
/// [let formula : String = ePackage.verificationFormula(eClass, name, 'alloy')]
/// ...
/// ```
public struct VerificationServices: AQLServiceProvider {
    private let cache = TranslatorCache()

    /// Creates the services.
    public init() {}

    /// The services offered to templates.
    public var services: [AQLService] {
        let cache = self.cache
        return [
            AQLService(VerificationServiceName.identifier, receiver: .string, arity: 1) { call in
                try Self.target(call, 0).identifier(try call.receiverString())
            },
            AQLService(VerificationServiceName.literal, receiver: .string, arity: 2) { call in
                try Self.target(call, 1).literal(enumeration: try call.receiverString(), literal: try call.string(0))
            },
            AQLService(VerificationServiceName.feature, receiver: .string, arity: 2) { call in
                try Self.target(call, 1).feature(className: try call.receiverString(), feature: try call.string(0))
            },
            AQLService(VerificationServiceName.string, receiver: .string, arity: 1) { call in
                try Self.target(call, 0).stringLiteral(try call.receiverString())
            },
            AQLService(VerificationServiceName.kind, receiver: .any, arity: 0) { call in
                switch call.receiver {
                case is EClass: return VerificationKindName.object
                case is EEnum: return VerificationKindName.enumeration
                case let dataType as EDataType:
                    switch MetamodelIndex.kind(ofDataType: dataType.name, instanceClass: dataType.instanceClassName) {
                    case .integer: return VerificationKindName.integer
                    case .boolean: return VerificationKindName.boolean
                    case .string: return VerificationKindName.string
                    default: return VerificationKindName.uninterpreted
                    }
                default:
                    throw AQLExecutionError.typeError("\(call.name) requires a classifier receiver")
                }
            },
            AQLService(VerificationServiceName.invariants, receiver: .any, arity: 1) { call in
                let translator = try await cache.translator(for: try Self.package(call))
                return AQLValues.collection(translator.invariants(of: try Self.className(call, 0)).map(\.name))
            },
            AQLService(VerificationServiceName.invariantBody, receiver: .any, arity: 2) { call in
                let translator = try await cache.translator(for: try Self.package(call))
                let name = try call.string(1)
                return translator.invariants(of: try Self.className(call, 0)).first { $0.name == name }?.body
            },
            AQLService(VerificationServiceName.formula, receiver: .any, arity: 3...4) { call in
                let translator = try await cache.translator(for: try Self.package(call))
                let target = try Self.target(call, 2)
                let primed = (call.argument(3) as? Bool ?? false) ? Self.variables(of: translator.index, target: target) : []
                return try? translator.translate(
                    className: try Self.className(call, 0), constraint: try call.string(1), target: target, primed: primed
                ).get()
            },
            AQLService(VerificationServiceName.problem, receiver: .any, arity: 3) { call in
                let translator = try await cache.translator(for: try Self.package(call))
                let result = translator.translate(
                    className: try Self.className(call, 0), constraint: try call.string(1), target: try Self.target(call, 2))
                if case .failure(let error) = result { return error.reason }
                return nil
            },
        ]
    }

    /// The identifiers of the variables of an Event-B machine.
    ///
    /// The populations of the classes change as objects are created and deleted, so every class
    /// is a variable, and so is every exported feature, whose domain is the population of its class.
    /// Features that cannot change keep their values once an object has them, which the events
    /// of a refinement must respect; the exported machines only initialise them.
    ///
    /// - Parameters:
    ///   - index: The metamodel.
    ///   - target: The target that names the classes and features.
    /// - Returns: The identifiers of the classes and of the features that are not derived.
    static func variables(of index: MetamodelIndex, target: VerificationTarget) -> Set<String> {
        let features = index.classes.values.flatMap { $0.features }.filter { !$0.isDerived }.map {
            target.feature(className: $0.owner, feature: $0.name)
        }
        return Set(features + index.classes.keys.map { target.identifier($0) })
    }

    private static func target(_ call: AQLServiceCall, _ index: Int) throws -> VerificationTarget {
        let name = try call.string(index)
        guard let target = VerificationTarget(rawValue: name) else {
            throw AQLExecutionError.invalidOperation("'\(name)' is not a verification target")
        }
        return target
    }

    private static func package(_ call: AQLServiceCall) throws -> EPackage {
        guard let package = call.receiver as? EPackage else {
            throw AQLExecutionError.typeError("\(call.name) requires a package receiver")
        }
        return package
    }

    private static func className(_ call: AQLServiceCall, _ index: Int) throws -> String {
        if let eClass = call.argument(index) as? EClass { return eClass.name }
        return try call.string(index)
    }
}

/// The translators built for packages, kept so that each package is indexed once.
actor TranslatorCache {
    private var translators: [EUUID: InvariantTranslator] = [:]

    /// The translator for a package.
    ///
    /// - Parameter package: The package.
    /// - Returns: The translator for the package and its nested packages.
    func translator(for package: EPackage) -> InvariantTranslator {
        if let known = translators[package.id] { return known }
        let translator = InvariantTranslator(packages: [package])
        translators[package.id] = translator
        return translator
    }
}
