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
    /// The preset of the settings that differ between headless and interactive use.
    @Option(
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
    @Option(help: "The class that generated root objects extend, overriding the preset")
    public var rootExtendsClass: String?

    /// Whether generated models include operation reflection.
    @Flag(
        inversion: .prefixedNo,
        help: "Whether generated models include operation reflection, overriding the preset")
    public var operationReflection: Bool?

    /// Whether generated code organises its imports.
    @Flag(
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
}
