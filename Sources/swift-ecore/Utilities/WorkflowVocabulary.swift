//
// WorkflowVocabulary.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingCommandLine

// MARK: - Comparison

/// The words, symbols and option names with which the compare command describes differences.
///
/// The command compares two metamodels or two models and reports one line per difference,
/// marked as added, removed or changed, followed by a summary line.
enum ComparisonVocabulary {
    /// The name of the option that shows the counts only.
    static let summaryOption = "summary"

    /// The name of the option that names a feature or element to leave out of the comparison.
    static let ignoreOption = "ignore"

    /// The name of the option that makes differences fail the command.
    static let exitCodeOption = "exit-code"

    /// The separator between a class and a feature in an ignored name, as in `Order.note`.
    static let pathSeparator = "."

    /// The separator between the original and the revised value of a change.
    static let changeArrow = " -> "

    /// The text shown for a value that is not set, or a list without elements.
    static let none = "none"

    /// The text shown for a single-valued feature that an object does not set.
    static let unsetValue = "null"

    /// The text shown for a reference to an object that cannot be found in any document.
    static let unresolvedTarget = "unresolved object"

    /// The text shown for a many-valued feature that an object does not set.
    static let emptyList = "[]"

    /// The separator between the elements of a list in a description.
    static let listSeparator = ", "

    /// The word that introduces the supertypes of an added or removed class.
    static let extendsWord = "extends"

    /// The heading of the counts of a metamodel comparison summary.
    static let elementCountsHeading = "Elements:"

    /// The heading of the counts of a model comparison summary.
    static let classCountsHeading = "Objects per class:"

    /// The name of the line that adds up the objects of every class.
    static let totalName = "Total"

    /// The line that reports that the documents do not differ.
    static let noDifferences = "No differences"

    /// The word for one difference.
    static let differenceSingular = "difference"

    /// The word for several differences.
    static let differencePlural = "differences"

    /// What the progress bar shows while the objects of two models are compared.
    static let progressMessage = "Comparing objects"

    /// The confirmation printed after the report has been written to a file.
    static let writtenConfirmation = "Comparison written: "

    /// The warning that two models in different formats were read without a metamodel.
    ///
    /// Without a metamodel, each reader names the classes of the objects it reads in its own
    /// way: an XMI reader after the elements, which name features rather than classes, and a
    /// JSON reader after the `eClass` entries. Objects are matched by class, so the same
    /// objects may then be reported as removed and added.
    ///
    /// - Parameters:
    ///   - original: The file name and format of the original model, such as `a.xmi (XMI)`.
    ///   - revised: The file name and format of the revised model.
    /// - Returns: The warning, starting with ``ConversionWarningReport/warningPrefix``.
    static func untypedFormatsWarning(original: String, revised: String) -> String {
        ConversionWarningReport.warningPrefix
            + "\(original) and \(revised) were read without a metamodel, so each format names the "
            + "classes of their objects in its own way and the same objects may be reported as "
            + "removed and added; give the metamodel of the models with --\(MetamodelOptions.optionName) "
            + "<\(MetamodelOptions.valueName)> to compare them by their classes"
    }

    /// The names of the element counts of a metamodel comparison summary, in the order shown.
    enum ElementCount: String, CaseIterable, Sendable {
        /// Packages and subpackages.
        case packages = "Packages"

        /// Classes.
        case classes = "Classes"

        /// Enumerations.
        case enumerations = "Enumerations"

        /// Data types that are not enumerations.
        case dataTypes = "Data types"

        /// Attributes declared by classes.
        case attributes = "Attributes"

        /// References declared by classes.
        case references = "References"

        /// Operations declared by classes.
        case operations = "Operations"
    }

    /// The properties whose changes the comparison reports.
    enum Property: String, Sendable {
        /// The name of a root package.
        case name

        /// The namespace URI of a package.
        case nsURI

        /// The namespace prefix of a package.
        case nsPrefix

        /// Whether a classifier is a class, an enumeration or a data type, or a feature an
        /// attribute or a reference.
        case kind

        /// Whether a class is abstract.
        case abstract

        /// Whether a class is an interface.
        case interface

        /// The direct supertypes of a class.
        case supertypes

        /// The type of a feature.
        case type

        /// The bounds of a feature.
        case multiplicity

        /// Whether a reference contains its targets.
        case containment

        /// The opposite of a reference.
        case opposite

        /// Whether an attribute identifies its object.
        case id

        /// Whether a feature is derived.
        case derived

        /// Whether a feature is transient.
        case transient

        /// Whether a feature cannot be changed.
        case readOnly = "read-only"

        /// The default value of a feature.
        case defaultValue = "default"

        /// The value of an enumeration literal.
        case value

        /// The parameters and result of an operation.
        case signature

        /// The class of the values of a data type.
        case instanceClass = "instance class"
    }
}

// MARK: - Statistics

/// The labels with which the statistics command reports its measurements.
enum StatisticsVocabulary {
    /// The number of decimal places of an average.
    static let averageDecimals = 2

    /// The heading of the counts of objects per class.
    static let objectsPerClassHeading = "Objects per class:"

    /// The heading of the features per class.
    static let featuresPerClassHeading = "Features per class:"

    /// The heading of the classes ordered by their number of features.
    static let classesByFeaturesHeading = "Classes by number of features:"

    /// The indentation of a line that belongs to the line above it.
    static let indent = "  "

    /// What the progress bar shows while the objects of a model are measured.
    static let progressMessage = "Measuring objects"

    /// The confirmation printed after the report has been written to a file.
    static let writtenConfirmation = "Statistics written: "
}

// MARK: - Validation of Several Files

/// The words with which the validate command reports on several files.
enum BatchValidationVocabulary {
    /// The heading printed before the findings of each file.
    static let fileHeading = "Validating: "

    /// The result of a file that passed validation.
    static let valid = "valid"

    /// The result of a file that did not pass validation.
    static let invalid = "invalid"

    /// What the progress bar shows while the files are validated.
    static let progressMessage = "Validating files"
}

extension ValidationCode {
    /// A file could not be read, so it was not validated.
    static let unreadable = "document.unreadable"
}
