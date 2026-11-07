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
public struct LevelCrossingOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "level-crossing"

    /// The mode that applies when the option is not given.
    public static let defaultMode = LevelCrossingMode.declared

    /// The values of the option, separated as in the usage of a command.
    public static let valueList = LevelCrossingMode.allCases.map(\.rawValue).joined(separator: "|")

    /// The mode given on the command line.
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
    public var mode: LevelCrossingMode = LevelCrossingOptions.defaultMode

    /// Creates the option with the default mode.
    public init() {}
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
}
