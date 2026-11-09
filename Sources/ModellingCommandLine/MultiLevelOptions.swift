//
// MultiLevelOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import AQLMultiLevel
import ArgumentParser
import ECore
import EMFBase
import Foundation
import MultiLevel

/// Which references of a multi-level model may connect clabjects at different levels, as the
/// command line spells it.
///
/// The raw values are the command-line spellings of ``LevelCrossingOptions``.
public enum LevelCrossingMode: String, CaseIterable, Sendable, ExpressibleByArgument {
    /// Strict metamodelling without exceptions: no reference may cross levels, so deep
    /// references, leap potencies and references declared with a target level are errors too.
    case strict

    /// Strict metamodelling with the sanctioned crossings (the default): a reference connects
    /// clabjects of one level, unless it is a deep reference, a clabject with leap potency or a
    /// reference declared with a target level.
    case declared

    /// Non-strict metamodelling: any reference may cross levels.
    case nonStrict = "non-strict"

    /// The policy of the multi-level library that the mode selects.
    ///
    /// Both ``strict`` and ``declared`` select `LevelCrossingPolicy.strict`, which admits the
    /// declared crossings; ``strict`` reports those crossings in addition (see
    /// ``diagnostics(for:)``).
    public var policy: LevelCrossingPolicy {
        switch self {
        case .strict, .declared: return .strict
        case .nonStrict: return .nonStrict
        }
    }

    /// The crossings that the mode forbids beyond those of its ``policy``.
    ///
    /// Only ``strict`` forbids more: every clabject with leap potency, every deep reference and
    /// every reference declared with a target level is reported as an error with the code
    /// `MultiLevelDiagnosticCode.levelCrossing`.
    ///
    /// - Parameter model: The deep model.
    /// - Returns: The errors, from the top level down, in declaration order.
    public func diagnostics(for model: DeepModel) -> [SourceDiagnostic] {
        guard self == .strict else { return [] }
        var diagnostics: [SourceDiagnostic] = []
        func report(_ message: String) {
            diagnostics.append(
                SourceDiagnostic(
                    severity: .error, code: MultiLevelDiagnosticCode.levelCrossing,
                    message: message + " (--\(LevelCrossingOptions.optionName) \(rawValue))"))
        }
        for clabject in model.allClabjects {
            if clabject.isLeap {
                report("'\(clabject.name)' has a leap potency, which crosses levels")
            }
            for feature in clabject.features {
                if feature.targetPotency != nil {
                    report("'\(clabject.name).\(feature.name)' is a deep reference, which crosses levels")
                } else if let level = feature.targetLevel {
                    report("'\(clabject.name).\(feature.name)' is declared to refer to level \(level), which crosses levels")
                }
            }
        }
        return diagnostics
    }
}

/// The command line option that chooses which references of a multi-level model may cross
/// levels.
///
/// The option applies when a multi-level model, such as a MetaDepth document (`.mdepth`), is
/// validated. The default, ``LevelCrossingMode/declared``, admits the crossings that the model
/// declares; ``LevelCrossingMode/strict`` admits none and ``LevelCrossingMode/nonStrict`` admits
/// every one.
///
/// The configuration file may choose the mode too, under the key ``optionName``; an option given
/// on the command line overrides it. The preset of ``SemanticsOptions`` does not change it.
public struct LevelCrossingOptions: ParsableArguments, Sendable {
    /// The long name of the option, and the key of the configuration file.
    public static let optionName = "level-crossing"

    /// The mode that applies when neither the command line nor the configuration file chooses one.
    public static let defaultMode = LevelCrossingMode.declared

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = LevelCrossingMode.allCases.map(\.rawValue).joined(separator: "|")

    /// The mode given on the command line, if any.
    @Option(
        name: .customLong(LevelCrossingOptions.optionName),
        help: ArgumentHelp(
            "Which references of a multi-level model may cross levels: \(LevelCrossingMode.strict.rawValue), "
                + "\(LevelCrossingMode.declared.rawValue) (the default) or \(LevelCrossingMode.nonStrict.rawValue)",
            discussion: """
                With \(LevelCrossingMode.declared.rawValue), a reference connects clabjects of one level \
                unless it is a deep reference, has a leap potency or declares its target level. With \
                \(LevelCrossingMode.strict.rawValue), those crossings are errors too, and with \
                \(LevelCrossingMode.nonStrict.rawValue), any reference may cross levels.
                """,
            valueName: LevelCrossingOptions.valueList))
    public var explicitMode: LevelCrossingMode?

    /// The mode given on the command line, or ``defaultMode`` if none is.
    ///
    /// The mode that applies to a run of a command that reads a configuration file also depends
    /// on that file; ``mode(settings:)`` resolves it. Setting this property gives the mode as if
    /// on the command line.
    public var mode: LevelCrossingMode {
        get { explicitMode ?? Self.defaultMode }
        set { explicitMode = newValue }
    }

    /// Creates the option with nothing given, which admits the declared crossings unless the
    /// configuration file says otherwise.
    public init() {}

    /// The mode that applies to a run.
    ///
    /// - Parameter settings: The settings of the run, whose configuration file is consulted.
    /// - Returns: The mode given on the command line, else the `level-crossing` of the
    ///   configuration file, else ``defaultMode``.
    public func mode(settings: SemanticsSettings) -> LevelCrossingMode {
        explicitMode ?? settings.configuration.levelCrossing ?? Self.defaultMode
    }
}

/// The command line option that presents multi-level models as the deep view of one level.
///
/// Without the option, a multi-level model, such as a MetaDepth document (`.mdepth`), is read as
/// instances of the linguistic metamodel of multi-level models. With it, each multi-level model
/// is replaced by the deep view of the level given: every type above the level becomes a class
/// whose supertypes include its ontological type, so that expressions, transformations and
/// templates written for Ecore find the deep instances of a type, and the services of
/// `AQLMultiLevelServices`, such as `clabjectName()` and `ontologicalType()`, are available.
public struct DeepViewOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "deep-view"

    /// The level whose deep view is presented, if any.
    @Option(
        name: .customLong(DeepViewOptions.optionName),
        help: ArgumentHelp(
            "Present each multi-level model as the deep view of a level, such as 0 for the bottom level",
            valueName: "level"))
    public var level: Int?

    /// Creates the option with no level.
    public init() {}

    /// Whether a level was given on the command line.
    public var isGiven: Bool { level != nil }
}

/// The deep views of a multi-level model, with the view that a command presents.
public struct DeepModelViews: Sendable {
    /// The deep model.
    public let model: DeepModel

    /// The deep views of every level, from the top level down.
    public let views: [DeepLevelView]

    /// The view of the level that was asked for.
    public let view: DeepLevelView

    /// The services that templates and expressions use with the views.
    public var services: AQLMultiLevelServices { AQLMultiLevelServices(views: views) }

    /// The clabject that an object of the views stands for.
    ///
    /// - Parameter value: An object of one of the views, or any other value.
    /// - Returns: The clabject, or `nil` if the value is not an object that stands for a
    ///   clabject of the model.
    public func clabject(of value: (any EcoreValue)?) -> Clabject? {
        guard let object = value as? any EObject else { return nil }
        return model.clabject(object.id)
    }

    /// The class that stands for the ontological type of an object of the views.
    ///
    /// The class is taken from the lowest view that has one, so that the type of an object of
    /// the view of a level is a class of that view.
    ///
    /// - Parameter value: An object of one of the views, or any other value.
    /// - Returns: The class, or `nil` if the value stands for no clabject or the clabject has
    ///   no ontological type.
    public func ontologicalClass(of value: (any EcoreValue)?) -> EClass? {
        guard let type = clabject(of: value)?.type else { return nil }
        return eClass(ofClabject: type)
    }

    /// The class that stands for a clabject, taken from the lowest view that has one.
    ///
    /// - Parameter id: The identifier of the clabject.
    /// - Returns: The class, or `nil` if no view has a class for the clabject.
    public func eClass(ofClabject id: EUUID) -> EClass? {
        for candidate in views.reversed() {
            if let eClass = candidate.eClass(of: id) { return eClass }
        }
        return nil
    }

    /// The clabject that a class of one of the views stands for.
    ///
    /// - Parameter eClass: A class of one of the views.
    /// - Returns: The clabject, or `nil` if the class belongs to no view.
    public func clabject(ofClass eClass: EClass) -> Clabject? {
        for candidate in views {
            if let clabject = candidate.clabject(ofClass: eClass) { return clabject }
        }
        return nil
    }

    /// The object that stands for a clabject in the view of its level.
    ///
    /// - Parameter id: The identifier of the clabject.
    /// - Returns: The object, or `nil` if the clabject has no object in the views.
    public func object(ofClabject id: EUUID) async -> (any EObject)? {
        guard let level = model.level(of: id), let view = views.first(where: { $0.level == level }) else {
            return nil
        }
        return await view.resource.resolve(id)
    }

    /// The classes of the deep types of an object of the views.
    ///
    /// - Parameter value: An object of one of the views, or any other value.
    /// - Returns: The classes, nearest first, or `nil` if the value stands for no clabject.
    public func deepTypeClasses(of value: (any EcoreValue)?) -> [EClass]? {
        guard let clabject = clabject(of: value) else { return nil }
        return model.deepTypes(of: clabject.id).compactMap { eClass(ofClabject: $0.id) }
    }

    /// Whether an object of the views is a direct or indirect instance of a type.
    ///
    /// - Parameters:
    ///   - value: An object of one of the views, or any other value.
    ///   - typeName: The name of the type.
    /// - Returns: Whether a deep type of the object has the name, or `nil` if the value stands
    ///   for no clabject.
    public func isDeepInstance(_ value: (any EcoreValue)?, ofTypeNamed typeName: String) -> Bool? {
        guard let clabject = clabject(of: value) else { return nil }
        return model.deepTypes(of: clabject.id).contains { $0.name == typeName }
    }

    /// The object that stands for the ontological type of an object of the views at a level.
    ///
    /// - Parameters:
    ///   - value: An object of one of the views, or any other value.
    ///   - level: The level of the type.
    /// - Returns: The object whose slots hold the values set at that level, or `nil` if the
    ///   value stands for no clabject or has no type at that level.
    public func typeObject(of value: (any EcoreValue)?, atLevel level: Int) async -> (any EObject)? {
        guard let clabject = clabject(of: value),
            let type = model.ontologicalTypeChain(of: clabject.id).first(where: { model.level(of: $0.id) == level })
        else { return nil }
        return await object(ofClabject: type.id)
    }

    /// The values of a feature of an object of the views, looked up along its type chain.
    ///
    /// Strings, enumeration literals, numbers and Booleans are given as they are, and clabjects
    /// as the objects that stand for them.
    ///
    /// - Parameters:
    ///   - value: An object of one of the views, or any other value.
    ///   - feature: The name of the feature.
    /// - Returns: The values, or `nil` if the value stands for no clabject or no clabject of
    ///   its type chain gives the feature a value.
    public func slotValues(of value: (any EcoreValue)?, feature: String) async -> [any EcoreValue]? {
        guard let clabject = clabject(of: value), let values = model.values(of: feature, at: clabject.id) else {
            return nil
        }
        var converted: [any EcoreValue] = []
        for value in values {
            switch value {
            case .string(let text), .literal(let text): converted.append(text)
            case .integer(let number): converted.append(number)
            case .real(let number): converted.append(number)
            case .boolean(let flag): converted.append(flag)
            case .object(let id):
                if let object = await object(ofClabject: id) { converted.append(object) }
            }
        }
        return converted
    }

    /// The objects of the direct and indirect instances of the types of a name.
    ///
    /// - Parameters:
    ///   - typeName: The name of the types.
    ///   - level: The level to restrict to, or `nil` for every level.
    /// - Returns: The objects, from the top level down, in declaration order.
    public func deepInstanceObjects(ofTypeNamed typeName: String, atLevel level: Int? = nil) async -> [any EObject] {
        var objects: [any EObject] = []
        for type in model.allClabjects where type.name == typeName {
            for instance in model.instances(of: type.id, atLevel: level) {
                if let object = await object(ofClabject: instance.id) { objects.append(object) }
            }
        }
        return objects
    }
}

/// Reads multi-level models for the command-line tools.
public enum MultiLevelSupport {
    /// Makes the MetaDepth notation (`.mdepth`) available to every reader and writer of the run.
    ///
    /// Registering the handler more than once has no further effect.
    public static func registerFormats() async {
        await MultiLevelFormats.register()
    }

    /// Registers the linguistic metamodel of multi-level models with a resource set, so that
    /// an XMI or JSON document of linguistic instances is read with its classes.
    ///
    /// - Parameter resourceSet: The resource set.
    public static func registerLinguisticMetamodel(in resourceSet: ResourceSet) async {
        await resourceSet.registerMetamodel(MultiLevelPackage.package)
    }

    /// Whether a file is an XMI or JSON document of the linguistic instances of a multi-level
    /// model, which names the namespace of the linguistic metamodel near its start.
    ///
    /// Such a document is read with the linguistic metamodel registered (see
    /// ``registerLinguisticMetamodel(in:)``), so that it converts back to a multi-level model.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: `true` if the start of the file names the namespace URI of `MultiLevelPackage`.
    public static func holdsLinguisticInstances(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let prefix = try? handle.read(upToCount: ModelFormatRegistry.recognitionPrefixLength) else { return false }
        return String(decoding: prefix, as: UTF8.self).contains(MultiLevelPackage.package.nsURI)
    }

    /// The deep model that a resource of linguistic instances holds.
    ///
    /// - Parameter resource: The resource, such as one read from a MetaDepth document.
    /// - Returns: The deep model, or `nil` if the resource holds no deep model.
    public static func deepModel(in resource: Resource) async -> DeepModel? {
        try? await LinguisticEncoding.model(from: resource)
    }

    /// The deep views of the deep model that a resource holds.
    ///
    /// - Parameters:
    ///   - resource: The resource of linguistic instances.
    ///   - level: The level whose view is presented.
    ///   - resourceSet: The resource set that receives the views and their packages.
    /// - Returns: The views, or `nil` if the resource holds no deep model.
    /// - Throws: `MultiLevelError` if the model has no such level, or a view cannot be built.
    public static func views(
        of resource: Resource, level: Int, in resourceSet: ResourceSet
    ) async throws -> DeepModelViews? {
        guard let model = await deepModel(in: resource) else { return nil }
        guard model.levelNumbers.contains(level) else {
            throw MultiLevelError.noSuchLevel(level)
        }
        let views = try await model.deepLevelViews(in: resourceSet)
        guard let view = views.first(where: { $0.level == level }) else { throw MultiLevelError.noSuchLevel(level) }
        return DeepModelViews(model: model, views: views, view: view)
    }

    /// Whether a file holds a multi-level model: a MetaDepth document, or an XMI or JSON
    /// document of the linguistic instances of a multi-level model.
    ///
    /// The formats of multi-level models must be registered (see ``registerFormats()``) for
    /// a MetaDepth document to be recognised by its extension.
    ///
    /// - Parameters:
    ///   - url: The location of the file.
    ///   - explicitFormat: The name of a format given on the command line, if any, such as `json`.
    /// - Returns: `true` if the file is read as a multi-level model.
    /// - Throws: `ModelFormatError.undetectableFormat(_:)` if the format of the file cannot be
    ///   determined.
    public static func holdsMultiLevelModel(_ url: URL, explicitFormat: String? = nil) throws -> Bool {
        let format = try ModelFileFormat.detectedInstanceFormat(of: url, explicit: explicitFormat)
        return format == .metadepth || holdsLinguisticInstances(url)
    }

    /// Reads the multi-level model of a file and presents the deep view of a level.
    ///
    /// The formats of multi-level models are registered first, so that a MetaDepth document
    /// is read by its extension, and the linguistic metamodel is registered with the resource
    /// set, so that an XMI or JSON document of linguistic instances is read with its classes.
    ///
    /// - Parameters:
    ///   - url: The location of the file.
    ///   - level: The level whose view is presented.
    ///   - explicitFormat: The name of a format given on the command line, if any, such as `json`.
    ///   - encoding: The encoding of a MetaDepth document, or `nil` (the default) to read UTF-8
    ///     with a fallback to ISO-8859-1, as ``TextDocumentLoading`` reads it.
    ///   - resourceSet: The resource set that receives the model and its views.
    /// - Returns: The views, or `nil` if the file holds no multi-level model.
    /// - Throws: ``DeepViewError`` if the model has no such level or a view cannot be built,
    ///   ``SourceFileError/malformed(path:encoding:)`` if a MetaDepth document is not valid in
    ///   the encoding, and the error of the reader if the file cannot be read.
    public static func views(
        ofFileAt url: URL, level: Int, explicitFormat: String? = nil, encoding: TextEncoding? = nil,
        in resourceSet: ResourceSet
    ) async throws -> DeepModelViews? {
        await registerFormats()
        guard try holdsMultiLevelModel(url, explicitFormat: explicitFormat) else { return nil }
        let format = try ModelFileFormat.detectedInstanceFormat(of: url, explicit: explicitFormat)
        if format != .metadepth {
            await registerLinguisticMetamodel(in: resourceSet)
        }
        let resource = try await TextDocumentLoading.load(
            url: url, format: format, resourceSet: resourceSet,
            options: ModelIO.LoadOptions(requiresMetamodel: false), encoding: encoding
        ).resource
        do {
            return try await views(of: resource, level: level, in: resourceSet)
        } catch let error as MultiLevelError {
            throw DeepViewError(path: url.relativePath, reason: error.description)
        }
    }
}

/// The error raised when a multi-level model cannot be presented as the deep view of a level.
public struct DeepViewError: Error, LocalizedError, CustomStringConvertible, Equatable, Sendable {
    /// The path of the file that holds the model.
    public let path: String

    /// Why the view cannot be presented, such as a level that the model does not have.
    public let reason: String

    /// Creates the error.
    ///
    /// - Parameters:
    ///   - path: The path of the file that holds the model.
    ///   - reason: Why the view cannot be presented.
    public init(path: String, reason: String) {
        self.path = path
        self.reason = reason
    }

    /// The path and the reason, as one sentence.
    public var description: String { "\(path): \(reason)" }

    /// The path and the reason, as one sentence.
    public var errorDescription: String? { description }
}
