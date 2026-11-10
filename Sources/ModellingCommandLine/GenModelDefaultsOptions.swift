//
// GenModelDefaultsOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ModellingGenerators

extension GenModelDefaults: ExpressibleByArgument {}

/// The command line options that choose the defaults of a generator model.
///
/// The options select a preset of the settings that the Eclipse tools write differently for
/// headless and interactive use (`--defaults`), and override individual settings of that preset.
/// A setting that is not given on the command line is left to the preset.
///
/// Commands include the options with `@OptionGroup`, and apply them to their import options
/// with ``apply(to:)``.
public struct GenModelDefaultsOptions: ParsableArguments, Sendable {
    /// The long names of the options, which are also the keys of the configuration file.
    public enum OptionName {
        /// The preset of the settings that differ between headless and interactive use.
        public static let defaults = "defaults"

        /// The class that generated root objects extend.
        public static let rootExtendsClass = "root-extends-class"

        /// Whether generated models include operation reflection.
        public static let operationReflection = "operation-reflection"

        /// Whether generated code organises its imports.
        public static let importOrganizing = "import-organizing"

        /// The base package of the root packages, an option of the commands that write a
        /// generator model.
        public static let basePackage = "base-package"

        /// A prefix of the root package or of one package, an option of the commands that write
        /// a generator model.
        public static let prefix = "prefix"

        /// The compliance level of the generated code, an option of the commands that write a
        /// generator model.
        public static let jdkLevel = "jdk-level"
    }

    /// The preset of the settings that differ between headless and interactive use.
    @Option(
        name: .customLong(OptionName.defaults),
        help: ArgumentHelp(
            "The preset of generator model defaults: headless (the default) or wizard",
            discussion: """
                headless leaves operation reflection, the root class and import organising at the \
                defaults of the generator metamodel, as the command line generator of the Eclipse \
                tools does. wizard gives the settings that the interactive generator model wizard \
                writes: operation reflection and import organising on, and a root class with a \
                container. With --reload, a preset replaces the settings of the existing model.
                """,
            valueName: "headless|wizard"))
    public var defaults: GenModelDefaults?

    /// The class that generated root objects extend.
    @Option(
        name: .customLong(OptionName.rootExtendsClass),
        help: "The class that generated root objects extend, overriding the preset")
    public var rootExtendsClass: String?

    /// Whether generated models include operation reflection.
    @Flag(
        name: .customLong(OptionName.operationReflection),
        inversion: .prefixedNo,
        help: "Whether generated models include operation reflection, overriding the preset")
    public var operationReflection: Bool?

    /// Whether generated code organises its imports.
    @Flag(
        name: .customLong(OptionName.importOrganizing),
        inversion: .prefixedNo,
        help: "Whether generated code organises its imports, overriding the preset")
    public var importOrganizing: Bool?

    /// Creates options with nothing set, which leaves every setting to the preset.
    public init() {}

    /// Whether any of the options was given on the command line.
    public var isGiven: Bool {
        defaults != nil || rootExtendsClass != nil || operationReflection != nil || importOrganizing != nil
    }

    /// Copies the options given on the command line to import options.
    ///
    /// Options that were not given leave the corresponding import option unchanged.
    ///
    /// - Parameter options: The import options to update.
    public func apply(to options: inout GenModelImportOptions) {
        if let defaults { options.defaults = defaults }
        if let rootExtendsClass { options.rootExtendsClass = rootExtendsClass }
        if let operationReflection { options.operationReflection = operationReflection }
        if let importOrganizing { options.importOrganizing = importOrganizing }
    }

    /// Copies the options of a run to import options.
    ///
    /// Each option is the one given on the command line, else the value of its key in the
    /// configuration file; an option that neither gives leaves the import option unchanged.
    ///
    /// - Parameters:
    ///   - options: The import options to update.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    public func apply(to options: inout GenModelImportOptions, settings: SemanticsSettings) {
        let file = settings.configuration
        if let defaults = defaults ?? file.genModelDefaults { options.defaults = defaults }
        if let rootExtendsClass = rootExtendsClass ?? file.rootExtendsClass { options.rootExtendsClass = rootExtendsClass }
        if let operationReflection = operationReflection ?? file.operationReflection {
            options.operationReflection = operationReflection
        }
        if let importOrganizing = importOrganizing ?? file.importOrganizing { options.importOrganizing = importOrganizing }
    }

    /// Copies the base package, the prefixes and the compliance level of a run to import options.
    ///
    /// Each setting is the one given on the command line, else the value of its key in the
    /// configuration file; prefixes given on the command line replace those of the file.
    ///
    /// - Parameters:
    ///   - basePackage: The base package given with ``OptionName/basePackage``, if any.
    ///   - prefixes: The prefixes given with ``OptionName/prefix``, in command line order.
    ///   - complianceLevel: The compliance level given with ``OptionName/jdkLevel``, if any.
    ///   - settings: The settings of the run, whose configuration file is consulted.
    ///   - options: The import options to update.
    public static func applyProjectSettings(
        basePackage: String?, prefixes: [String], complianceLevel: String?, settings: SemanticsSettings,
        to options: inout GenModelImportOptions
    ) {
        let file = settings.configuration
        options.basePackage = basePackage ?? file.basePackage
        (prefixes.isEmpty ? file.prefixes ?? [] : prefixes).forEach { options.addPrefix($0) }
        options.complianceLevel = complianceLevel ?? file.complianceLevel
    }
}
