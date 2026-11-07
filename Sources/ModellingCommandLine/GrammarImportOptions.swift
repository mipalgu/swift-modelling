//
// GrammarImportOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore

/// How an ASDL import turns sum types into enumerations, as the command line spells it.
///
/// The raw values are the command-line spellings and the values of the configuration key
/// ``GrammarImportOptions/OptionName/asdlEnumerations``.
public enum ASDLEnumerationsOption: String, CaseIterable, Sendable, ExpressibleByArgument {
    /// A sum type whose constructors all have no fields becomes an enumeration (the default).
    case allNullary = "all-nullary"

    /// Every sum type becomes an abstract class with a subclass for each constructor.
    case never

    /// The style of the ASDL importer that the spelling selects.
    public var style: ASDLEnumerationStyle {
        switch self {
        case .allNullary: return .allNullarySums
        case .never: return .never
        }
    }
}

/// Parses a command-line value into the way a Langium import types its rules.
///
/// The raw values of the enumeration, `normal` and `strict`, are the command-line spellings.
extension LangiumTypeMode: @retroactive ExpressibleByArgument {}

/// The command line options that choose how metamodels are imported from grammars.
///
/// An ASDL (`.asdl`), Langium (`.langium`), Xtext (`.xtext`) or SDF3 (`.sdf3`) document
/// describes the syntax of a language, and the importer derives a metamodel from it. The
/// options name the package of that metamodel (``OptionName/packageName``, for a grammar that
/// declares no name, ``OptionName/nsURI`` and ``OptionName/nsPrefix``) and choose how the
/// grammar of each notation is mapped (``OptionName/asdlEnumerations``, ``OptionName/langiumTypes``,
/// ``OptionName/sdf3Labels``). Metamodels in other formats are not affected.
///
/// The configuration file may give each option under its long name; an option given on the
/// command line overrides it. The preset of ``SemanticsOptions`` does not change them.
public struct GrammarImportOptions: ParsableArguments, Sendable {
    /// The long names of the options, which are also the keys of the configuration file.
    public enum OptionName {
        /// The name of the package of an imported metamodel.
        public static let packageName = "package-name"

        /// The namespace URI of the package of an imported metamodel.
        public static let nsURI = "ns-uri"

        /// The namespace prefix of the package of an imported metamodel.
        public static let nsPrefix = "ns-prefix"

        /// Which ASDL sum types become enumerations.
        public static let asdlEnumerations = "asdl-enumerations"

        /// How a Langium grammar types its rules.
        public static let langiumTypes = "langium-types"

        /// Whether SDF3 constructor labels name the classes of an import.
        public static let sdf3Labels = "sdf3-labels"
    }

    /// The prefix that turns a flag off, as in `--no-sdf3-labels`.
    public static let inversionPrefix = "no-"

    /// The values of ``OptionName/asdlEnumerations``, separated as in the usage of a command.
    public static let asdlEnumerationsValueList = ASDLEnumerationsOption.allCases.map(\.rawValue).joined(separator: "|")

    /// The values of ``OptionName/langiumTypes``, separated as in the usage of a command.
    public static let langiumTypesValueList = LangiumTypeMode.allCases.map(\.rawValue).joined(separator: "|")

    /// The name of the package given on the command line, if any.
    @Option(
        name: .customLong(OptionName.packageName),
        help: ArgumentHelp(
            "The name of the package of a metamodel imported from an ASDL, Langium, Xtext or SDF3 grammar "
                + "that declares no name",
            discussion: "A name that the grammar declares takes precedence. Without either, the package "
                + "is named after the file.",
            valueName: "name"))
    public var explicitPackageName: String?

    /// The namespace URI given on the command line, if any.
    @Option(
        name: .customLong(OptionName.nsURI),
        help: ArgumentHelp(
            "The namespace URI of the package of a metamodel imported from a grammar",
            valueName: "uri"))
    public var explicitNSURI: String?

    /// The namespace prefix given on the command line, if any.
    @Option(
        name: .customLong(OptionName.nsPrefix),
        help: ArgumentHelp(
            "The namespace prefix of the package of a metamodel imported from a grammar",
            valueName: "prefix"))
    public var explicitNSPrefix: String?

    /// The ASDL enumeration style given on the command line, if any.
    @Option(
        name: .customLong(OptionName.asdlEnumerations),
        help: ArgumentHelp(
            "Which ASDL sum types become enumerations: \(ASDLEnumerationsOption.allNullary.rawValue) "
                + "(the default) or \(ASDLEnumerationsOption.never.rawValue)",
            discussion: """
                With \(ASDLEnumerationsOption.allNullary.rawValue), a sum type whose constructors \
                all have no fields becomes an enumeration. With \(ASDLEnumerationsOption.never.rawValue), \
                every sum type becomes an abstract class with a subclass for each constructor.
                """,
            valueName: GrammarImportOptions.asdlEnumerationsValueList))
    public var explicitASDLEnumerations: ASDLEnumerationsOption?

    /// The Langium type mode given on the command line, if any.
    @Option(
        name: .customLong(OptionName.langiumTypes),
        help: ArgumentHelp(
            "How a Langium grammar types its rules: \(LangiumTypeMode.normal.rawValue) (the default) "
                + "or \(LangiumTypeMode.strict.rawValue)",
            discussion: """
                With \(LangiumTypeMode.strict.rawValue), the classes of the metamodel come only from \
                the types and interfaces that the grammar declares, as in a Langium grammar in strict mode.
                """,
            valueName: GrammarImportOptions.langiumTypesValueList))
    public var explicitLangiumTypes: LangiumTypeMode?

    /// Whether SDF3 constructor labels name classes, as given on the command line, if at all.
    @Flag(
        name: .customLong(OptionName.sdf3Labels),
        inversion: .prefixedNo,
        help: ArgumentHelp(
            "Whether the constructor labels of an SDF3 grammar name the classes of the metamodel; "
                + "--\(GrammarImportOptions.inversionPrefix)\(OptionName.sdf3Labels) (the default) "
                + "names them after their sorts"))
    public var explicitSDF3Labels: Bool?

    /// Creates the options with nothing given.
    public init() {}

    /// Applies the options given on the command line alone to the options of a metamodel load.
    ///
    /// Commands that read no configuration file use this.
    ///
    /// - Parameter options: The options with which metamodels are loaded.
    public func apply(to options: inout EcoreLoadOptions) {
        apply(to: &options, configuration: ModellingConfiguration())
    }

    /// Applies the options of a run to the options of a metamodel load.
    ///
    /// Each option is the one given on the command line, else the value of its key in the
    /// configuration file, else the default of the importer.
    ///
    /// - Parameters:
    ///   - options: The options with which metamodels are loaded.
    ///   - configuration: The configuration file of the run.
    public func apply(to options: inout EcoreLoadOptions, configuration: ModellingConfiguration) {
        let packageName = explicitPackageName ?? configuration.packageName
        let nsURI = explicitNSURI ?? configuration.nsURI
        let nsPrefix = explicitNSPrefix ?? configuration.nsPrefix
        options.asdlOptions.packageName = packageName
        options.asdlOptions.nsURI = nsURI
        options.asdlOptions.nsPrefix = nsPrefix
        options.langiumOptions.packageName = packageName
        options.langiumOptions.nsURI = nsURI
        options.langiumOptions.nsPrefix = nsPrefix
        options.xtextOptions.packageName = packageName
        options.xtextOptions.nsURI = nsURI
        options.xtextOptions.nsPrefix = nsPrefix
        options.sdf3Options.packageName = packageName
        options.sdf3Options.nsURI = nsURI
        options.sdf3Options.nsPrefix = nsPrefix
        if let enumerations = explicitASDLEnumerations ?? configuration.asdlEnumerations {
            options.asdlOptions.enumerations = enumerations.style
        }
        if let typeMode = explicitLangiumTypes ?? configuration.langiumTypes {
            options.langiumOptions.typeMode = typeMode
        }
        if let useLabels = explicitSDF3Labels ?? configuration.sdf3Labels {
            options.sdf3Options.useLabels = useLabels
        }
    }
}
