//
// CompatibilityCheckOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import Foundation
import ModelTyping

/// The spelling of identifiers as command-line values.
enum CommandLineSpelling {
    /// The character that separates the words of a command-line value.
    static let wordSeparator: Character = "-"

    /// Spells a camel-case identifier in kebab case.
    ///
    /// - Parameter identifier: The identifier, such as `totalNonIsomorphic`.
    /// - Returns: Its words in lower case, separated by ``wordSeparator``, such as
    ///   `total-non-isomorphic`.
    static func kebabCase(_ identifier: String) -> String {
        var spelling = ""
        for character in identifier {
            if character.isUppercase, !spelling.isEmpty { spelling.append(wordSeparator) }
            spelling += character.lowercased()
        }
        return spelling
    }
}

/// Parses a command-line value into a subtyping mode.
///
/// Each mode is spelled as its name in kebab case, such as `total-non-isomorphic`.
extension SubtypingMode: ExpressibleByArgument {
    /// Creates the mode that a command-line value names.
    ///
    /// - Parameter argument: The spelling of the mode, such as `partial-isomorphic`.
    /// - Returns: The mode, or `nil` if the value names none.
    public init?(argument: String) {
        guard let mode = Self.allCases.first(where: { $0.defaultValueDescription == argument }) else { return nil }
        self = mode
    }

    /// The spelling of the mode on the command line, its name in kebab case.
    public var defaultValueDescription: String { CommandLineSpelling.kebabCase(rawValue) }

    /// The spellings of every mode, in the order of the library.
    public static var allValueStrings: [String] { allCases.map(\.defaultValueDescription) }

    /// What each mode decides, indexed by its spelling, for the help of the option.
    public static var allValueDescriptions: [String: String] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0.defaultValueDescription, $0.commandLineDescription) })
    }

    /// What the mode decides, as a phrase for the help of the option.
    public var commandLineDescription: String {
        let renaming = "--\(CompatibilityCheckOptions.OptionName.rename)"
        switch self {
        case .totalIsomorphic:
            return "Every element of the metamodel must exist in the target metamodel, under the same name"
        case .totalNonIsomorphic:
            return "Every element of the metamodel must exist in the target metamodel, after the renamings of \(renaming)"
        case .partialIsomorphic:
            return "Only the elements that the module uses must exist, under the same names"
        case .partial:
            return "Only the elements that the module uses must exist, after the renamings of \(renaming)"
        }
    }
}

/// Parses a command-line value into a matching semantics.
///
/// Each semantics is spelled as its name in kebab case, such as `mof-class-matching`; the
/// published definitions may also be named after their authors (see
/// ``CompatibilityCheckOptions/semanticsAliases``).
extension MatchingSemantics: ExpressibleByArgument {
    /// Creates the semantics that a command-line value names.
    ///
    /// - Parameter argument: The spelling of the semantics, such as `access-refined`, or an
    ///   alias, such as `guy`.
    /// - Returns: The semantics, or `nil` if the value names none.
    public init?(argument: String) {
        if let alias = CompatibilityCheckOptions.semanticsAliases[argument] {
            self = alias
            return
        }
        guard let semantics = Self.allCases.first(where: { $0.defaultValueDescription == argument }) else {
            return nil
        }
        self = semantics
    }

    /// The spelling of the semantics on the command line, its name in kebab case.
    public var defaultValueDescription: String { CommandLineSpelling.kebabCase(rawValue) }

    /// The spellings of every semantics, in the order of the library.
    public static var allValueStrings: [String] { allCases.map(\.defaultValueDescription) }

    /// What each semantics compares, indexed by its spelling, for the help of the option.
    public static var allValueDescriptions: [String: String] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0.defaultValueDescription, $0.commandLineDescription) })
    }

    /// What the semantics compares, as a phrase for the help of the option.
    public var commandLineDescription: String {
        let aliases = CompatibilityCheckOptions.semanticsAliases.filter { $0.value == self }.keys.sorted()
        let alias = aliases.isEmpty ? "" : " (alias: \(aliases.joined(separator: ", ")))"
        switch self {
        case .objectTypeMatching:
            return "Object type matching as defined by Steel and Jézéquel" + alias
        case .mofClassMatching:
            return "MOF class matching as defined by Guy et al." + alias
        case .accessRefined:
            return "Matching by how the module uses each element: read, written or instantiated" + alias
        }
    }
}

/// The formats in which a compatibility report is written.
public enum CompatibilityReportFormat: String, CaseIterable, Sendable, ExpressibleByArgument {
    /// The verdict on the first line, followed by one line for each finding, uncertainty and hint.
    case text

    /// A JSON object with the verdict, the findings, the footprint and the hints.
    case json
}

/// The verdict of a compatibility check, which decides the exit status of the command.
public enum CompatibilityVerdict: Sendable, Equatable, CaseIterable {
    /// The target metamodels can stand in for the metamodels of the module.
    case compatible

    /// The target metamodels cannot stand in for the metamodels of the module.
    case incompatible

    /// No incompatibility was found, but the types of some expressions could not be inferred.
    case inconclusive

    /// The exit status of a command that could not make the check, such as for a file that
    /// cannot be read or parsed.
    public static let failureExitStatus: Int32 = 3

    /// Creates the verdict of a report.
    ///
    /// A report with an error is incompatible, even if its footprint is incomplete.
    ///
    /// - Parameter report: The report of the check.
    public init(_ report: CompatibilityReport) {
        if !report.compatible {
            self = .incompatible
        } else {
            self = report.isConclusive ? .compatible : .inconclusive
        }
    }

    /// The exit status of the command for the verdict.
    ///
    /// - Returns: 0 for ``compatible``, 1 for ``incompatible`` and 2 for ``inconclusive``.
    public var exitStatus: Int32 {
        switch self {
        case .compatible: return 0
        case .incompatible: return 1
        case .inconclusive: return 2
        }
    }
}

/// A compatibility report together with its verdict, as written in JSON.
///
/// The object holds the flags ``FlagKey/compatible`` and ``FlagKey/conclusive`` beside the
/// members of the report itself, so that it can be read back as a `CompatibilityReport`.
public struct CompatibilityReportDocument: Encodable, Sendable {
    /// The keys of the verdict flags.
    public enum FlagKey: String, CodingKey {
        /// Whether the target metamodels are compatible.
        case compatible

        /// Whether the verdict rests on complete static knowledge of the footprint.
        case conclusive
    }

    /// The report.
    public let report: CompatibilityReport

    /// Creates the document of a report.
    ///
    /// - Parameter report: The report.
    public init(report: CompatibilityReport) {
        self.report = report
    }

    /// Encodes the verdict flags and the members of the report into one object.
    ///
    /// - Parameter encoder: The encoder.
    /// - Throws: The errors of the encoder.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FlagKey.self)
        try container.encode(report.compatible, forKey: .compatible)
        try container.encode(report.isConclusive, forKey: .conclusive)
        try report.encode(to: encoder)
    }
}

/// The metamodels of a compatibility check, loaded as model types.
public struct CompatibilityMetamodels: Sendable {
    /// The model types that the module was written against, indexed by metamodel name.
    public let required: [String: ModelType]

    /// The model types to check, indexed by the same names.
    ///
    /// A metamodel without a target metamodel is its own target.
    public let provided: [String: ModelType]

    /// Creates the metamodels of a check.
    ///
    /// - Parameters:
    ///   - required: The model types that the module was written against, by name.
    ///   - provided: The model types to check, by name.
    public init(required: [String: ModelType], provided: [String: ModelType]) {
        self.required = required
        self.provided = provided
    }

    /// The only metamodel of the check, for modules that are checked against one metamodel.
    ///
    /// - Returns: The name, the required and the provided model type, or `nil` unless there is
    ///   exactly one metamodel with a target.
    public var sole: (name: String, required: ModelType, provided: ModelType)? {
        guard required.count == 1, case let (name, requiredType)? = required.first,
            let providedType = provided[name]
        else {
            return nil
        }
        return (name, requiredType, providedType)
    }

    /// The only metamodel of the check, for modules that are checked against one metamodel.
    ///
    /// - Returns: The name, the required and the provided model type.
    /// - Throws: ``CompatibilityCheckError/severalMetamodels(_:)`` unless there is exactly one
    ///   metamodel.
    public func requireSole() throws -> (name: String, required: ModelType, provided: ModelType) {
        guard let sole else { throw CompatibilityCheckError.severalMetamodels(required.keys.sorted()) }
        return sole
    }

    /// Checks that the module declares every metamodel of the check.
    ///
    /// - Parameter declared: The names of the metamodels that the module declares, such as
    ///   those of the header of an ATL module.
    /// - Throws: ``CompatibilityCheckError/undeclaredMetamodels(_:declared:)`` if a metamodel of
    ///   the check is not one of them.
    public func requireDeclared(in declared: some Collection<String>) throws {
        let undeclared = required.keys.filter { !declared.contains($0) }.sorted()
        guard undeclared.isEmpty else {
            throw CompatibilityCheckError.undeclaredMetamodels(undeclared, declared: declared.sorted())
        }
    }
}

/// The command line options of a check of whether a module can be reused with other metamodels.
///
/// The commands that check ATL modules, MTL modules and AQL expressions name the metamodels
/// that the module was written against with `--metamodel name=file` and the metamodels to
/// check with `--target-metamodel name=file`, choose the subtyping relation with `--mode` and
/// the definition of matching, a `MatchingSemantics`, with `--subtyping`, and tune the check
/// with `--rename`, `--allow-widening` and `--lenient-lower-bounds`. A check does not include
/// the preset of ``SemanticsOptions``, so `--semantics` keeps its meaning across the tools.
///
/// Commands include the options with `@OptionGroup`, check their module with `ReuseChecker`
/// in ``run(isolation:_:)``, and describe them with ``discussion(module:)``.
public struct CompatibilityCheckOptions: ParsableArguments, Sendable {
    /// The name of the command that checks compatibility in each tool.
    public static let commandName = "check-compat"

    /// The long names of the options.
    public enum OptionName {
        /// The option that names a metamodel the module was written against.
        public static let metamodel = MetamodelOptions.optionName

        /// The option that names a metamodel to check the module against.
        public static let targetMetamodel = "target-metamodel"

        /// The option that chooses the subtyping relation.
        public static let mode = "mode"

        /// The option that chooses the definition of matching, the matching semantics of
        /// model subtyping.
        public static let subtyping = "subtyping"

        /// The option that maps a required name to a provided name.
        public static let rename = "rename"

        /// The flag that lets numeric types widen in the direction of use.
        public static let allowWidening = "allow-widening"

        /// The flag that reports lower bound violations as warnings.
        public static let lenientLowerBounds = "lenient-lower-bounds"

        /// The option that chooses the format of the report.
        public static let format = "format"
    }

    /// The names of the values of the options in the usage of a command.
    public enum ValueName {
        /// The value of an option that names a metamodel.
        public static let metamodel = "name=file"

        /// The value of the renaming option.
        public static let rename = "required=provided"
    }

    /// The text that starts the message of a problem that prevents the check, as
    /// ArgumentParser starts the messages of errors.
    public static let errorPrefix = "Error: "

    /// The text that starts the message of an option that the check ignores, as the other
    /// warnings of the tools start.
    public static let warningPrefix = ConversionWarningReport.warningPrefix

    /// The other spellings of the published matching definitions, named after their authors.
    public static let semanticsAliases: [String: MatchingSemantics] = [
        "steel-jezequel": .objectTypeMatching, "guy": .mofClassMatching,
    ]

    /// The family of `name=file` options that name metamodels.
    static let metamodelFiles = KeyValueOption<String>(noun: "metamodel", keyPlaceholder: "name") { _, path in
        guard !path.isEmpty else { throw CompatibilityCheckError.missingFile }
        return path
    }

    /// The metamodels that the module was written against, as `name=file` in command line order.
    @Option(
        name: [.customShort(MetamodelOptions.shortName), .customLong(OptionName.metamodel)],
        help: ArgumentHelp(
            "A metamodel that the module was written against, as name=file (can be specified multiple times)",
            discussion: """
                The name is the metamodel name of an ATL module header, such as Families in \
                IN : Families; for an MTL module or an AQL expression, it is the name under \
                which findings refer to the metamodel, conventionally its package name. The \
                file may be in any metamodel format: \(MetamodelOptions.formatList).
                """,
            valueName: ValueName.metamodel))
    public var requiredMetamodels: [String] = []

    /// The metamodels to check, as `name=file` in command line order.
    @Option(
        name: .customLong(OptionName.targetMetamodel),
        help: ArgumentHelp(
            "A metamodel to check the module against, as name=file (can be specified multiple times)",
            discussion: """
                Each name must be one that --\(OptionName.metamodel) gives. A metamodel without a \
                target metamodel is checked against itself, as if it were unchanged.
                """,
            valueName: ValueName.metamodel))
    public var targetMetamodels: [String] = []

    /// The subtyping relation that is decided unless the command line chooses another,
    /// `SubtypingMode.partial`.
    public static let defaultMode = SubtypingMode.partial

    /// The matching semantics that applies unless the command line chooses another, the
    /// default of `CheckOptions`, which is `MatchingSemantics.accessRefined`.
    public static let defaultSemantics = CheckOptions().semantics

    /// The subtyping relation given on the command line, if any.
    @Option(
        name: .customLong(OptionName.mode),
        help: ArgumentHelp(
            "The subtyping relation to decide (default: \(CompatibilityCheckOptions.defaultMode.defaultValueDescription))"))
    public var explicitMode: SubtypingMode?

    /// The matching semantics given on the command line, if any.
    @Option(
        name: .customLong(OptionName.subtyping),
        help: ArgumentHelp(
            "How model subtyping matches classes and features (default: "
                + "\(CompatibilityCheckOptions.defaultSemantics.defaultValueDescription))"))
    public var explicitSemantics: MatchingSemantics?

    /// The subtyping relation to decide.
    ///
    /// - Returns: The mode given on the command line, else ``defaultMode``.
    public var mode: SubtypingMode { explicitMode ?? Self.defaultMode }

    /// The definition of class and property matching.
    ///
    /// - Returns: The semantics given on the command line, else ``defaultSemantics``.
    public var semantics: MatchingSemantics { explicitSemantics ?? Self.defaultSemantics }

    /// The renamings from required to provided names, as given on the command line.
    @Option(
        name: .customLong(OptionName.rename),
        help: ArgumentHelp(
            "Map a required name to a provided one, as Class=NewClass or Class.feature=newFeature "
                + "(can be specified multiple times)",
            discussion: """
                Renamings apply only in the modes \(SubtypingMode.partial.defaultValueDescription) \
                and \(SubtypingMode.totalNonIsomorphic.defaultValueDescription); the other modes \
                ignore them with a warning. A classifier \
                renaming applies to a class, an enumeration or a data type; a member renaming, \
                written Owner.member with the names of the original metamodel, applies to a \
                feature or an enumeration literal. One value may hold several renamings, \
                separated by commas.
                """,
            valueName: ValueName.rename))
    public var renamings: [String] = []

    /// Whether numeric data types may widen in the direction of use.
    @Flag(
        name: .customLong(OptionName.allowWidening),
        help: ArgumentHelp(
            "Let numeric types widen in the direction of use",
            discussion: """
                An attribute that the module reads may then have a narrower type in the target \
                metamodel, such as EInt where ELong was declared, and one that it writes a wider \
                type. Widening is an extension of the \(MatchingSemantics.accessRefined.defaultValueDescription) \
                semantics and applies only in the modes that allow renamings. The published \
                semantics ignore it, even for an attribute that is only read: they relate no \
                data types by subtyping, so EInt does not match ELong, and they assume that \
                every attribute may be written as well as read.
                """))
    public var allowWidening = false

    /// Whether lower bound violations are reported as warnings.
    @Flag(
        name: .customLong(OptionName.lenientLowerBounds),
        help: ArgumentHelp(
            "Report lower bounds that do not conform as warnings instead of errors",
            discussion: """
                The leniency is an extension of the \(MatchingSemantics.accessRefined.defaultValueDescription) \
                semantics and applies only in the modes that allow renamings.
                """))
    public var lenientLowerBounds = false

    /// The format of the report.
    @Option(
        name: .customLong(OptionName.format),
        help: ArgumentHelp(
            "The format of the report",
            discussion: """
                \(CompatibilityReportFormat.json.rawValue) writes one object with the flags \
                \(CompatibilityReportDocument.FlagKey.compatible.rawValue) and \
                \(CompatibilityReportDocument.FlagKey.conclusive.rawValue), the mode, the \
                findings, the footprint of the module and the renaming hints. In the \
                footprint, the classes are an object by name, the features and literals are \
                arrays of objects, and each use lists its access by name, such as \
                ["read", "write"].
                """))
    public var format: CompatibilityReportFormat = .text

    /// How metamodels in KM3 and in grammar formats are read.
    @OptionGroup public var formatOptions: MetamodelFormatOptions

    /// Creates the options with nothing given.
    public init() {}

    /// Checks that the metamodels and renamings are well formed and that every target
    /// metamodel has a metamodel of the same name.
    ///
    /// - Throws: A `ValidationError` that names the first problem.
    public func validate() throws {
        guard !requiredMetamodels.isEmpty else {
            throw ValidationError("Give at least one --\(OptionName.metamodel) \(ValueName.metamodel)")
        }
        guard !targetMetamodels.isEmpty else {
            throw ValidationError("Give at least one --\(OptionName.targetMetamodel) \(ValueName.metamodel)")
        }
        let required: [String: String]
        let targets: [String: String]
        do {
            required = try requiredMetamodelFiles()
            targets = try targetMetamodelFiles()
        } catch {
            throw ValidationError(String(describing: error))
        }
        for name in targets.keys.sorted() where required[name] == nil {
            throw ValidationError(
                "--\(OptionName.targetMetamodel) names '\(name)', which no --\(OptionName.metamodel) names")
        }
        _ = try renaming()
    }

    /// Checks that the command line names exactly one metamodel, for modules that are checked
    /// against a single metamodel.
    ///
    /// - Throws: A `ValidationError` if several metamodels are given.
    public func validateSingleMetamodel() throws {
        let names = (try? requiredMetamodelFiles().keys.sorted()) ?? []
        guard names.count <= 1 else {
            throw ValidationError(CompatibilityCheckError.severalMetamodels(names).description)
        }
    }

    /// The files of the metamodels that the module was written against.
    ///
    /// - Returns: The paths by metamodel name; a later name replaces an earlier one.
    /// - Throws: A `KeyValueOptionError` if a value is not of the form `name=file`.
    public func requiredMetamodelFiles() throws -> [String: String] {
        try Self.metamodelFiles.values(from: requiredMetamodels)
    }

    /// The files of the metamodels to check.
    ///
    /// - Returns: The paths by metamodel name; a later name replaces an earlier one.
    /// - Throws: A `KeyValueOptionError` if a value is not of the form `name=file`.
    public func targetMetamodelFiles() throws -> [String: String] {
        try Self.metamodelFiles.values(from: targetMetamodels)
    }

    /// The renaming that the command line gives.
    ///
    /// - Returns: The renaming, which is empty without `--rename`.
    /// - Throws: A `ValidationError` if a renaming is not of the form `required=provided`.
    public func renaming() throws -> Renaming {
        do {
            return try Renaming(parsing: renamings)
        } catch RenamingError.malformedEntry(let entry) {
            throw ValidationError("Invalid renaming '\(entry)': expected \(ValueName.rename)")
        }
    }

    /// Warnings about options that the mode or the matching semantics of the check ignores.
    ///
    /// The isomorphic modes admit no adaptation, so they ignore `--rename`, `--allow-widening`
    /// and `--lenient-lower-bounds`. The published matching semantics ignore the last two,
    /// which are extensions of the access-refined semantics: the published definitions relate
    /// no data types by subtyping and assume every possible use of an element.
    ///
    /// - Returns: One line for each ignored option, starting with ``warningPrefix``.
    public var ignoredOptionWarnings: [String] {
        var warnings: [String] = []
        let modeName = mode.defaultValueDescription
        if mode.isIsomorphic, !renamings.isEmpty {
            warnings.append(
                Self.warningPrefix + "--\(OptionName.rename) is ignored in the mode \(modeName), which admits no renaming")
        }
        let extensions = [(allowWidening, OptionName.allowWidening), (lenientLowerBounds, OptionName.lenientLowerBounds)]
        for (isGiven, option) in extensions where isGiven {
            if mode.isIsomorphic {
                warnings.append(
                    Self.warningPrefix + "--\(option) is ignored in the mode \(modeName), which admits no adaptation")
            } else if semantics.isPublished {
                warnings.append(
                    Self.warningPrefix + "--\(option) is ignored by \(semantics.defaultValueDescription); it applies "
                        + "only to the \(MatchingSemantics.accessRefined.defaultValueDescription) semantics")
            }
        }
        return warnings
    }

    /// The options of the check that the command line chooses.
    ///
    /// - Returns: The options, with the renaming, widening, leniency and semantics given.
    /// - Throws: A `ValidationError` if a renaming is not of the form `required=provided`.
    public func checkOptions() throws -> CheckOptions {
        CheckOptions(
            renaming: try renaming(), allowsNumericWidening: allowWidening, lenientLowerBounds: lenientLowerBounds,
            semantics: semantics)
    }

    /// Loads the metamodels of the check as model types.
    ///
    /// Every root package of a file belongs to its model type. A file named more than once is
    /// read once, and a metamodel without a target metamodel is its own target.
    ///
    /// - Returns: The required and the provided model types.
    /// - Throws: `MetamodelRegistrationError.fileNotFound(_:)` if a file does not exist, or the
    ///   error of the reader if a file cannot be loaded.
    public func loadMetamodels() async throws -> CompatibilityMetamodels {
        let loadOptions = formatOptions.ecoreLoadOptions
        var loaded: [String: ModelType] = [:]
        func modelType(at path: String) async throws -> ModelType {
            if let modelType = loaded[path] { return modelType }
            let modelType = ModelType(packages: try await MetamodelRegistration.loadPackages(at: path, options: loadOptions))
            loaded[path] = modelType
            return modelType
        }
        var required: [String: ModelType] = [:]
        for (name, path) in try requiredMetamodelFiles().sorted(by: { $0.key < $1.key }) {
            required[name] = try await modelType(at: path)
        }
        var provided = required
        for (name, path) in try targetMetamodelFiles().sorted(by: { $0.key < $1.key }) {
            provided[name] = try await modelType(at: path)
        }
        return CompatibilityMetamodels(required: required, provided: provided)
    }

    /// The text of a report in the format that the command line chooses.
    ///
    /// - Parameter report: The report.
    /// - Returns: The text of `CompatibilityReport.formatted(includesNotes:)`, or the JSON of
    ///   a ``CompatibilityReportDocument`` with sorted keys.
    /// - Throws: The error of the JSON encoder.
    public func render(_ report: CompatibilityReport) throws -> String {
        switch format {
        case .text:
            return report.formatted()
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            return String(decoding: try encoder.encode(CompatibilityReportDocument(report: report)), as: UTF8.self)
        }
    }

    /// Loads the metamodels, checks the module, prints the report and exits with the status of
    /// the verdict.
    ///
    /// Each of the ``ignoredOptionWarnings`` is written to standard error first.
    ///
    /// The report is printed to standard output. A problem that prevents the check, such as a
    /// file that cannot be read or a module that cannot be parsed, is written to standard
    /// error, and the command exits with ``CompatibilityVerdict/failureExitStatus``.
    ///
    /// - Parameters:
    ///   - isolation: The actor the check runs on, by default that of the caller.
    ///   - check: Parses the module and checks it against the loaded metamodels.
    /// - Throws: `ExitCode` with the status of the verdict unless it is compatible, or with
    ///   ``CompatibilityVerdict/failureExitStatus`` if the check could not be made.
    public func run(
        isolation: isolated (any Actor)? = #isolation,
        _ check: (CompatibilityMetamodels) async throws -> CompatibilityReport
    ) async throws {
        for warning in ignoredOptionWarnings { FileDiagnosticReport.writeToStandardError(warning + "\n") }
        let output: String
        let verdict: CompatibilityVerdict
        do {
            let report = try await check(try await loadMetamodels())
            output = try render(report)
            verdict = CompatibilityVerdict(report)
        } catch {
            FileDiagnosticReport.writeToStandardError(Self.errorPrefix + Self.message(for: error) + "\n")
            throw ExitCode(CompatibilityVerdict.failureExitStatus)
        }
        print(output)
        if verdict != .compatible { throw ExitCode(verdict.exitStatus) }
    }

    /// Checks that the file of the module to check exists.
    ///
    /// - Parameter path: The path of the file, as given on the command line.
    /// - Throws: ``CompatibilityCheckError/moduleNotFound(_:)`` if there is no such file.
    public static func requireModule(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else { throw CompatibilityCheckError.moduleNotFound(path) }
    }

    /// The message of an error for the reader of the command line.
    ///
    /// - Parameter error: The error.
    /// - Returns: The localised description of the error if it has one, else its description.
    static func message(for error: any Error) -> String {
        if let localised = error as? any LocalizedError, let description = localised.errorDescription {
            return description
        }
        return String(describing: error)
    }

    /// Paragraphs that describe a check in the discussion of a command.
    ///
    /// - Parameter module: What is checked, such as `the transformation`.
    /// - Returns: The paragraphs, naming the footprint, the defaults and the exit statuses.
    public static func discussion(module: String) -> String {
        """
        The command decides whether \(module), written against the metamodels that \
        --\(OptionName.metamodel) names, can be used with models of the metamodels that \
        --\(OptionName.targetMetamodel) names. It extracts the footprint of \(module), the \
        classes, features and literals that it reads, writes or instantiates, and checks the \
        target metamodels against it by structural model subtyping. A missing element comes \
        with a hint for --\(OptionName.rename) where a similar element exists.

        The default mode is \(defaultMode.defaultValueDescription) and the default matching \
        semantics \(defaultSemantics.defaultValueDescription), which --\(OptionName.subtyping) \
        chooses.

        Exit status: \(CompatibilityVerdict.compatible.exitStatus) if the target metamodels \
        are compatible, \(CompatibilityVerdict.incompatible.exitStatus) if they are not, \
        \(CompatibilityVerdict.inconclusive.exitStatus) if no incompatibility was found but \
        the types of some expressions could not be inferred, so that the verdict is \
        inconclusive, \(CompatibilityVerdict.failureExitStatus) if the check could not be \
        made, such as for a file that cannot be read or parsed, and \(ExitCode.validationFailure.rawValue) \
        for invalid arguments.
        """
    }
}

/// A problem that prevents a compatibility check.
public enum CompatibilityCheckError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// A metamodel is named without a file.
    case missingFile

    /// The file of the module to check does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case moduleNotFound(String)

    /// Metamodels of the check are not declared by the module.
    ///
    /// The associated values are the names of those metamodels and the names of the
    /// metamodels that the module declares.
    case undeclaredMetamodels([String], declared: [String])

    /// A module that is checked against one metamodel is given another number of them.
    ///
    /// The associated value holds the names of the metamodels given.
    case severalMetamodels([String])

    /// A description of the problem for the reader of the command line.
    public var description: String {
        switch self {
        case .missingFile:
            return "expected the path of a metamodel file"
        case .moduleNotFound(let path):
            return "File not found: \(path)"
        case .undeclaredMetamodels(let names, let declared):
            let list = declared.isEmpty ? "none" : declared.joined(separator: ", ")
            return "The module declares no metamodel named \(names.joined(separator: ", ")) "
                + "(it declares: \(list))"
        case .severalMetamodels(let names):
            return "Give one --\(CompatibilityCheckOptions.OptionName.metamodel), not several "
                + "(\(names.joined(separator: ", ")))"
        }
    }

    /// The localised description of the problem, which is its ``description``.
    public var errorDescription: String? { description }
}
