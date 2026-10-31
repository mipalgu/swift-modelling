//
// MTLSemanticsOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ArgumentParser
import MTL
import ModellingGenerators

/// Parses a command-line value into a way of writing line breaks after one-line blocks.
extension MTLBlockLineBreaks: @retroactive ExpressibleByArgument {}

/// Parses a command-line value into a way of matching collection-typed parameters.
extension MTLCollectionParameters: @retroactive ExpressibleByArgument {}

/// Parses a command-line value into a way of passing collection arguments.
extension AQLCollectionArguments: @retroactive ExpressibleByArgument {}

/// Parses a command-line value into a way of treating the kinds of collections.
extension AQLCollectionKinds: @retroactive ExpressibleByArgument {}

/// Parses a command-line value into the collection that an arrow call on a single value sees.
extension AQLSingleValueCollections: @retroactive ExpressibleByArgument {}

/// Parses a command-line value into a way of looking up containers.
extension AQLContainerLookup: @retroactive ExpressibleByArgument {}

/// The command line options that choose the behaviours of templates and their expressions.
///
/// Each option selects one behaviour of `MTLOptions` or of its expression language options,
/// `AQLOptions`. An option that is not given takes the value of the preset that
/// ``SemanticsOptions`` chooses, so `--semantics legacy` gives the behaviour of version 0.6
/// unless an option of this group says otherwise. The values of the options are the raw values
/// of the enumerations of the MTL and AQL libraries; the two Boolean behaviours are flags with a
/// `--no-` form.
///
/// How unset features read and how typed `let` blocks treat values of another type are chosen
/// by ``UnsetFeatureOptions`` and ``LetTypeMismatchOptions``, whose defaults do not depend on
/// the preset.
///
/// An option that is not given on the command line but is set in the configuration file takes
/// the value of the file, which overrides the preset (see ``SemanticsSettings``).
///
/// Commands include the options with `@OptionGroup`, and either pass
/// ``mtlOptions(settings:)`` to the generator they run or apply the options to their
/// generation options with ``apply(to:settings:)``.
public struct MTLSemanticsOptions: ParsableArguments, Sendable {
    /// The long names of the options.
    public enum OptionName {
        /// The option that chooses `MTLOptions.blockLineBreaks`.
        public static let blockLineBreaks = "block-line-breaks"

        /// The option that chooses `MTLOptions.collectionParameters`.
        public static let collectionParameters = "collection-parameters"

        /// The flag that chooses `MTLOptions.checksLetTypes`.
        public static let checkLetTypes = "check-let-types"

        /// The flag that chooses `MTLOptions.cachesContainers`.
        public static let cacheContainers = "cache-containers"

        /// The option that chooses `AQLOptions.collectionArguments`.
        public static let collectionArguments = "collection-arguments"

        /// The option that chooses `AQLOptions.collectionKinds`.
        public static let collectionKinds = "collection-kinds"

        /// The option that chooses `AQLOptions.singleValueCollections`.
        public static let singleValueCollections = "single-value-collections"

        /// The option that chooses `AQLOptions.containerLookup`.
        public static let containerLookup = "container-lookup"
    }

    /// The prefix of the inverted form of a flag.
    public static let inversionPrefix = "no-"

    /// What happens to the line break after a block written on one line.
    @Option(
        name: .customLong(OptionName.blockLineBreaks),
        help: ArgumentHelp(
            "The line break after a block written on one line: \(MTLBlockLineBreaks.acceleo.rawValue) "
                + "(the default) or \(MTLBlockLineBreaks.kept.rawValue), as in version 0.6",
            discussion: """
                With \(MTLBlockLineBreaks.acceleo.rawValue), the line break after the closing tag of \
                a block such as [if (c)][helper()/][/if] on a line of its own is dropped when the line \
                is empty once the block has run, as in Acceleo 4. With \
                \(MTLBlockLineBreaks.kept.rawValue), it is always written.
                """,
            valueName: MTLSemanticsOptions.valueList(MTLBlockLineBreaks.self)))
    public var blockLineBreaks: MTLBlockLineBreaks?

    /// Which arguments conform to a collection type.
    @Option(
        name: .customLong(OptionName.collectionParameters),
        help: ArgumentHelp(
            "Collections for collection-typed parameters: \(MTLCollectionParameters.conforming.rawValue) "
                + "(the default) or \(MTLCollectionParameters.exact.rawValue), as in version 0.6",
            discussion: """
                With \(MTLCollectionParameters.conforming.rawValue), any collection whose elements \
                conform, including a many-valued feature, conforms to a collection type such as \
                Sequence(String), and overloads are chosen by the types of the elements. With \
                \(MTLCollectionParameters.exact.rawValue), collection types are matched as in \
                version 0.6.
                """,
            valueName: MTLSemanticsOptions.valueList(MTLCollectionParameters.self)))
    public var collectionParameters: MTLCollectionParameters?

    /// Whether `let` blocks check their values against the declared types.
    @Flag(
        name: .customLong(OptionName.checkLetTypes),
        inversion: .prefixedNo,
        help: ArgumentHelp(
            "Whether typed let blocks check their values (the default); --\(MTLSemanticsOptions.inversionPrefix)"
                + "\(OptionName.checkLetTypes) binds them unchecked, as in version 0.6",
            discussion: """
                A value that does not conform to the declared type of a let variable is then treated \
                as --\(LetTypeMismatchOptions.optionName) says.
                """))
    public var checksLetTypes: Bool?

    /// Whether the container of each model object is looked up only once per run.
    @Flag(
        name: .customLong(OptionName.cacheContainers),
        inversion: .prefixedNo,
        help: ArgumentHelp(
            "Whether containers are looked up once per run (the default); --\(MTLSemanticsOptions.inversionPrefix)"
                + "\(OptionName.cacheContainers) looks them up every time, as in version 0.6"))
    public var cachesContainers: Bool?

    /// How a collection passed to an operation that adds an element is treated.
    @Option(
        name: .customLong(OptionName.collectionArguments),
        help: ArgumentHelp(
            "How a collection argument is added: \(AQLCollectionArguments.whole.rawValue) (the default) "
                + "or \(AQLCollectionArguments.firstElement.rawValue), as in version 0.6",
            discussion: """
                With \(AQLCollectionArguments.whole.rawValue), Sequence{'a'}->append(Sequence{'b', \
                'c'}) adds the sequence as one element. With \
                \(AQLCollectionArguments.firstElement.rawValue), only 'b' is added.
                """,
            valueName: MTLSemanticsOptions.valueList(AQLCollectionArguments.self)))
    public var collectionArguments: AQLCollectionArguments?

    /// Whether collections keep their kinds.
    @Option(
        name: .customLong(OptionName.collectionKinds),
        help: ArgumentHelp(
            "The kinds of collections: \(AQLCollectionKinds.distinguished.rawValue) (the default) "
                + "or \(AQLCollectionKinds.sequences.rawValue), as in version 0.6",
            discussion: """
                With \(AQLCollectionKinds.distinguished.rawValue), sequences, ordered sets, sets and \
                bags keep their kinds, and sets do not repeat elements. With \
                \(AQLCollectionKinds.sequences.rawValue), every collection behaves as a sequence.
                """,
            valueName: MTLSemanticsOptions.valueList(AQLCollectionKinds.self)))
    public var collectionKinds: AQLCollectionKinds?

    /// The collection that an arrow call on a single value sees.
    @Option(
        name: .customLong(OptionName.singleValueCollections),
        help: ArgumentHelp(
            "The collection of a single value in an arrow call: \(AQLSingleValueCollections.set.rawValue) "
                + "(the default) or \(AQLSingleValueCollections.sequence.rawValue), as in version 0.6",
            discussion: """
                With \(AQLSingleValueCollections.set.rawValue), 'a'->including('a') yields Set{'a'}. \
                With \(AQLSingleValueCollections.sequence.rawValue), it yields Sequence{'a', 'a'}. The \
                option matters only while collection kinds are distinguished.
                """,
            valueName: MTLSemanticsOptions.valueList(AQLSingleValueCollections.self)))
    public var singleValueCollections: AQLSingleValueCollections?

    /// How the containers of model objects are found.
    @Option(
        name: .customLong(OptionName.containerLookup),
        help: ArgumentHelp(
            "How containers are found: \(AQLContainerLookup.resources.rawValue) (the default) "
                + "or \(AQLContainerLookup.registeredObjects.rawValue), as in version 0.6",
            discussion: """
                With \(AQLContainerLookup.resources.rawValue), eContainer() and the services that \
                depend on it ask the registered resources, so they also find the containers of \
                nested metamodel contents. With \(AQLContainerLookup.registeredObjects.rawValue), \
                only the registered model objects are searched.
                """,
            valueName: MTLSemanticsOptions.valueList(AQLContainerLookup.self)))
    public var containerLookup: AQLContainerLookup?

    /// Creates the options with nothing set, which leaves every behaviour to the preset.
    public init() {}

    /// The values of an option, separated as in the usage of a command.
    ///
    /// - Parameter type: The enumeration whose raw values are the spellings of the option.
    /// - Returns: The raw values of all cases, separated by `|`.
    public static func valueList<Value: CaseIterable & RawRepresentable>(_ type: Value.Type) -> String
    where Value.RawValue == String {
        type.allCases.map(\.rawValue).joined(separator: "|")
    }

    /// The behaviours of the expression language that the options and a preset select.
    ///
    /// - Parameter preset: The preset whose behaviours apply where no option was given.
    /// - Returns: The options of the preset, with each option given on the command line in place.
    public func aqlOptions(preset: SemanticsPreset) -> AQLOptions {
        aqlOptions(settings: SemanticsSettings(preset: preset))
    }

    /// The behaviours of the expression language that the options and the settings of a run select.
    ///
    /// Each behaviour is the option given on the command line, else the option in the
    /// configuration file of the settings, else that of their preset.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The options of the expression language.
    public func aqlOptions(settings: SemanticsSettings) -> AQLOptions {
        let file = settings.configuration
        var options = settings.preset.mtlOptions.aql
        if let value = collectionArguments ?? file.collectionArguments { options.collectionArguments = value }
        if let value = collectionKinds ?? file.collectionKinds { options.collectionKinds = value }
        if let value = singleValueCollections ?? file.singleValueCollections { options.singleValueCollections = value }
        if let value = containerLookup ?? file.containerLookup { options.containerLookup = value }
        return options
    }

    /// The behaviours of the template language that the options and a preset select.
    ///
    /// - Parameter preset: The preset whose behaviours apply where no option was given.
    /// - Returns: The options of the preset, with each option given on the command line in place.
    ///   Unset features and typed `let` mismatches keep the values of the preset.
    public func mtlOptions(preset: SemanticsPreset) -> MTLOptions {
        mtlOptions(settings: SemanticsSettings(preset: preset))
    }

    /// The behaviours of the template language that the options and the settings of a run select.
    ///
    /// Each behaviour is the option given on the command line, else the option in the
    /// configuration file of the settings, else that of their preset.
    ///
    /// - Parameter settings: The preset and configuration file of the run.
    /// - Returns: The options of the template language. Unset features and typed `let`
    ///   mismatches keep the values of the preset; ``UnsetFeatureOptions`` and
    ///   ``LetTypeMismatchOptions`` choose them.
    public func mtlOptions(settings: SemanticsSettings) -> MTLOptions {
        let file = settings.configuration
        var options = settings.preset.mtlOptions
        options.aql = aqlOptions(settings: settings)
        if let value = blockLineBreaks ?? file.blockLineBreaks { options.blockLineBreaks = value }
        if let value = collectionParameters ?? file.collectionParameters { options.collectionParameters = value }
        if let value = checksLetTypes ?? file.checksLetTypes { options.checksLetTypes = value }
        if let value = cachesContainers ?? file.cachesContainers { options.cachesContainers = value }
        return options
    }

    /// Copies the behaviours that the options and a preset select to generation options.
    ///
    /// How unset features read and how typed `let` mismatches are treated stay as the
    /// generation options have them, so the order in which option groups are applied does not
    /// matter.
    ///
    /// - Parameters:
    ///   - options: The generation options to update.
    ///   - preset: The preset whose behaviours apply where no option was given.
    public func apply(to options: inout GenerationOptions, preset: SemanticsPreset) {
        apply(to: &options, settings: SemanticsSettings(preset: preset))
    }

    /// Copies the behaviours that the options and the settings of a run select to generation options.
    ///
    /// How unset features read and how typed `let` mismatches are treated stay as the
    /// generation options have them, so the order in which option groups are applied does not
    /// matter.
    ///
    /// - Parameters:
    ///   - options: The generation options to update.
    ///   - settings: The preset and configuration file of the run.
    public func apply(to options: inout GenerationOptions, settings: SemanticsSettings) {
        var selected = mtlOptions(settings: settings)
        selected.unsetFeatureReads = options.mtlOptions.unsetFeatureReads
        selected.letTypeMismatches = options.mtlOptions.letTypeMismatches
        options.mtlOptions = selected
    }

    /// A paragraph that describes the options in the discussion of a command.
    ///
    /// - Parameter reader: What runs the templates, such as `the templates`.
    /// - Returns: The paragraph, naming the options and how to get the behaviour of version 0.6.
    public static func discussion(reader: String) -> String {
        "--\(OptionName.blockLineBreaks), --\(OptionName.collectionParameters), "
            + "--[\(inversionPrefix)]\(OptionName.checkLetTypes), --[\(inversionPrefix)]"
            + "\(OptionName.cacheContainers), --\(OptionName.collectionArguments), "
            + "--\(OptionName.collectionKinds), --\(OptionName.singleValueCollections) and "
            + "--\(OptionName.containerLookup) choose how \(reader) and their expressions behave. "
            + "Each defaults to the behaviour of this release, or to that of version 0.6 with "
            + "--\(SemanticsOptions.optionName) \(SemanticsPreset.legacy.rawValue)."
    }
}
