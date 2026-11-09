//
// CommandVocabulary.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import ECore
import ModellingCommandLine

// MARK: - Output Formats

/// The formats in which the inspect and validate commands write their reports.
///
/// Text is meant for people, JSON for tools that process the report further.
enum ReportFormat: String, CaseIterable, ExpressibleByArgument, Sendable {
    /// Indented text for reading in a terminal.
    case text

    /// A JSON document with the same information as the text.
    case json
}

// MARK: - Inspection

/// How much an inspection shows.
enum InspectionDetail: String, CaseIterable, ExpressibleByArgument, Sendable {
    /// The packages or classes with their counts and the names of their elements.
    case summary

    /// Every element with its features, types, multiplicities and values.
    case full
}

// MARK: - Queries

/// The queries that the query command understands.
///
/// A query is named by the first word of the query expression; ``find`` takes the name of a
/// class as its second word. Names are matched without regard to case.
enum QueryKind: String, CaseIterable, Sendable {
    /// The number of objects, the root objects and the objects of each class.
    case info

    /// The number of objects of the whole document.
    case count

    /// The classes of a document: for a model the classes of its objects with their counts,
    /// for a metamodel every class it defines with its supertypes.
    case listClasses = "list-classes"

    /// The inheritance hierarchy of the classes of a document.
    case hierarchy

    /// The objects of a class or of one of its subclasses, with their features.
    case find

    /// The containment tree of the whole document.
    case tree

    /// Other names that select a query.
    static let aliases: [String: QueryKind] = ["classes": .listClasses]

    /// The query that a name selects, if any.
    ///
    /// - Parameter name: The first word of a query expression, in any case.
    /// - Returns: The query that the name or one of its ``aliases`` denotes, or `nil`.
    static func named(_ name: String) -> QueryKind? {
        let key = name.lowercased()
        return QueryKind(rawValue: key) ?? aliases[key]
    }

    /// The names that the help of the command lists, in the order of the cases.
    static var helpList: String {
        allCases.map { $0 == .find ? "\($0.rawValue) <class>" : $0.rawValue }.joined(separator: ", ")
    }
}

// MARK: - Object Descriptions

/// The words and symbols with which the commands describe models and metamodels.
enum ModelVocabulary {
    /// The features whose value names an object, in order of preference.
    static let labelFeatures = ["name", "title", "label", "id", "identifier", "key"]

    /// The symbol that shows an unbounded upper bound, as in `[0..*]`.
    static let unbounded = "*"

    /// The upper bound that Ecore uses for an unbounded feature.
    static let unboundedUpperBound = -1

    /// The name shown for the Ecore format; other formats are shown in capitals.
    static let ecoreFormatName = "Ecore"

    /// The type shown for an operation that returns nothing.
    static let voidType = "void"

    /// The flag shown for an abstract class.
    static let abstractFlag = "abstract"

    /// The flag shown for an interface.
    static let interfaceFlag = "interface"

    /// The flag shown for a containment reference.
    static let containmentFlag = "containment"

    /// The flag shown for a reference to the container of its object.
    static let containerFlag = "container"

    /// The flag shown for a derived feature.
    static let derivedFlag = "derived"

    /// The flag shown for a transient feature.
    static let transientFlag = "transient"

    /// The flag shown for an identifying attribute.
    static let idFlag = "id"

    /// The flag shown for a feature that cannot be changed.
    static let readOnlyFlag = "read-only"

    /// The fragment that names the single root object of a document.
    static let rootFragment = "/"

    /// The location shown for an object that the resource holds but no root contains.
    static let uncontainedLocation = "not contained"

    /// The fragment separator between a document and an object within it.
    static let fragmentSeparator = "#"

    /// The prefix of a containment step in a fragment, as in `@employees.0`.
    static let featureStepPrefix = "@"

    /// The separator between a feature and an index in a fragment step.
    static let indexSeparator = "."

    /// The separator between the segments of a fragment.
    static let segmentSeparator = "/"

    /// The longest text of a value that a description shows before shortening it.
    static let maximumValueLength = 60

    /// The text that marks a shortened value.
    static let ellipsis = "..."
}

// MARK: - OCL Constraints

/// Where a metamodel keeps the OCL invariants of its classes.
///
/// A class names its constraints in the `constraints` detail of its annotation with the
/// ``AnnotationSource/ecore`` source, and gives the expression of each in a detail of its
/// annotation with an OCL source. Without the `constraints` detail, every detail of the OCL
/// annotation of a class is an invariant.
enum OCLVocabulary {
    /// The annotation sources that hold OCL expressions.
    static let annotationSources = [AnnotationSource.ocl, AnnotationSource.ocl + "/Pivot"]

    /// The separators between the names of the `constraints` detail.
    static let constraintNameSeparators: Set<Character> = [" ", "\t", "\n", ","]

    /// The OCL string operation that returns the 1-based position of a substring, or 0.
    static let indexOfOperation = "indexOf"

    /// What the progress bar shows while invariants are evaluated.
    static let progressMessage = "Checking invariants"

    /// The name of the variable that holds the object an invariant is evaluated for.
    static let selfVariable = "self"
}

// MARK: - Encodings

/// The words with which the commands describe the encoding of the documents they read.
enum EncodingVocabulary {
    /// The documents to which `--encoding` applies, for the discussion of a command.
    static let encodedDocuments = "the documents in text formats that the command reads, including its metamodels "
        + "and Complete OCL documents, such as KM3, Emfatic, Xcore, OCLinEcore, Complete OCL, ASDL, Langium, "
        + "Xtext, SDF3 and MetaDepth"

    /// The documents to which `--encoding` applies for the create command.
    static let createdMetamodels = "the metamodels in text formats given with --\(MetamodelOptions.optionName), "
        + "such as KM3, Emfatic, Xcore, OCLinEcore, ASDL, Langium, Xtext and SDF3"
}

// MARK: - Configuration file

/// The keys of the configuration file that the commands honour, and the words that describe them.
enum ConfigurationVocabulary {
    /// The keys of the options that choose how metamodels in KM3 and in grammar formats are read.
    static let metamodelFormatKeys = [
        KM3Options.optionName, GrammarImportOptions.OptionName.packageName, GrammarImportOptions.OptionName.nsURI,
        GrammarImportOptions.OptionName.nsPrefix, GrammarImportOptions.OptionName.asdlEnumerations,
        GrammarImportOptions.OptionName.langiumTypes, GrammarImportOptions.OptionName.sdf3Labels,
    ]

    /// The keys that the commands which read documents in text formats honour.
    static let readingKeys = [SourceEncodingOptions.optionName] + metamodelFormatKeys + [CompleteOCLOptions.optionName]

    /// The keys that the validate command honours.
    static let validationKeys = readingKeys + [
        MTLSemanticsOptions.OptionName.strictAQL, LevelCrossingOptions.optionName, OutputEncodingOptions.optionName,
        ValidationOptionName.strict, ValidationOptionName.requireExplicitValues,
    ]

    /// The keys that the genmodel command honours.
    static let genModelKeys = [
        SemanticsOptions.OptionName.semantics, SemanticsOptions.OptionName.containerScope, UnsetFeatureOptions.optionName,
        OutputEncodingOptions.optionName, GenModelDefaultsOptions.OptionName.defaults,
        GenModelDefaultsOptions.OptionName.rootExtendsClass, GenModelDefaultsOptions.OptionName.operationReflection,
        GenModelDefaultsOptions.OptionName.importOrganizing, GenModelDefaultsOptions.OptionName.basePackage,
        GenModelDefaultsOptions.OptionName.prefix, GenModelDefaultsOptions.OptionName.jdkLevel,
    ]

    /// The keys that the create command honours.
    static let creationKeys = [SourceEncodingOptions.optionName] + metamodelFormatKeys + [OutputEncodingOptions.optionName]

    /// The keys that the commands which read documents in text formats and write files honour.
    static let writingKeys = readingKeys + [OutputEncodingOptions.optionName]

    /// The paragraph on the configuration file of the commands that read documents in text formats.
    static let readingDiscussion = ConfigurationFileOptions.discussion(keys: readingKeys)

    /// The paragraph on the configuration file of the commands that read documents in text
    /// formats and write files.
    static let writingDiscussion = ConfigurationFileOptions.discussion(keys: writingKeys)

    /// The paragraph on the configuration file of the commands that also read multi-level models.
    static let multiLevelDiscussion = ConfigurationFileOptions.discussion(
        keys: writingKeys + [LevelCrossingOptions.optionName])

    /// The paragraph on the configuration file of the convert command, which also writes XMI.
    static let conversionDiscussion = ConfigurationFileOptions.discussion(
        keys: writingKeys + [LevelCrossingOptions.optionName, ReferenceStyleOptions.optionName])
}
