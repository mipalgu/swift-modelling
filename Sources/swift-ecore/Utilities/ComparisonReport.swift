//
// ComparisonReport.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// What the compare command found between two metamodels or two models.
///
/// The report holds the same information whether it is written as text or as JSON. A summary
/// report holds the counts of both documents instead of the individual differences.
struct ComparisonReport: Codable, Sendable, Equatable {
    /// The names of the compared files.
    var files: ComparedFiles

    /// Whether the files are metamodels or models.
    var kind: InspectionReport.Kind

    /// The differences in document order, or `nil` for a summary.
    var differences: [Difference]?

    /// The numbers of differences, and for models of added, removed and changed objects.
    var summary: ComparisonSummary

    /// The numbers of packages, classes and other elements of two metamodels, for a summary.
    var elementCounts: [CountComparison]?

    /// The numbers of objects of each class of two models, in alphabetical order, for a summary.
    var classCounts: [CountComparison]?

    /// The numbers of objects of two models, for a summary.
    var totals: CountComparison?

    /// Creates a report from the differences between two documents.
    ///
    /// - Parameters:
    ///   - files: The names of the compared files.
    ///   - kind: Whether the files are metamodels or models.
    ///   - differences: Every difference found, in document order.
    ///   - objects: The numbers of added, removed, changed and unchanged objects of two models.
    ///   - summaryOnly: Whether the report leaves out the individual differences.
    init(
        files: ComparedFiles, kind: InspectionReport.Kind, differences: [Difference], objects: ObjectChanges? = nil,
        summaryOnly: Bool
    ) {
        self.files = files
        self.kind = kind
        self.differences = summaryOnly ? nil : differences
        summary = ComparisonSummary(differences: differences, objects: objects)
    }

    /// Whether the documents differ.
    var hasDifferences: Bool { summary.differences > 0 }

    /// The report as a JSON document, with sorted keys and indentation.
    ///
    /// - Returns: The JSON text, ending with a line break.
    /// - Throws: The error of the encoder.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self) + "\n"
    }

    /// The report as text: a heading, one line per difference or count, and the summary line.
    ///
    /// - Returns: The text, ending with a line break.
    func text() -> String {
        var lines = ["Comparing \(kind.rawValue)s: \(files.original)\(ComparisonVocabulary.changeArrow)\(files.revised)"]
        lines += differences?.map(\.text) ?? []
        if let elementCounts {
            lines.append(ComparisonVocabulary.elementCountsHeading)
            lines += elementCounts.map { StatisticsVocabulary.indent + $0.text }
        }
        if let classCounts {
            lines.append(ComparisonVocabulary.classCountsHeading)
            lines += classCounts.map { StatisticsVocabulary.indent + $0.text }
            if let totals { lines.append(StatisticsVocabulary.indent + totals.text) }
        }
        if differences == nil, let objects = summary.objects { lines.append(objects.text) }
        lines.append(summary.text)
        return lines.joined(separator: "\n") + "\n"
    }
}

/// The names of the two files that a comparison compares.
struct ComparedFiles: Codable, Sendable, Equatable {
    /// The name of the original file.
    var original: String

    /// The name of the revised file.
    var revised: String
}

/// One difference between two metamodels or two models.
struct Difference: Codable, Sendable, Equatable {
    /// How an element differs.
    enum Change: String, Codable, Sendable {
        /// The element exists in the revised document only.
        case added

        /// The element exists in the original document only.
        case removed

        /// The element exists in both documents with a different property or value.
        case changed

        /// The marker that starts the line of a difference.
        var marker: String {
            switch self {
            case .added: return "+"
            case .removed: return "-"
            case .changed: return "~"
            }
        }
    }

    /// The kinds of element that can differ.
    enum Element: String, Codable, Sendable {
        /// A package or subpackage.
        case package

        /// A class, enumeration or data type whose kind changed.
        case classifier

        /// A class.
        case `class`

        /// An enumeration.
        case enumeration

        /// A data type that is not an enumeration.
        case dataType

        /// An attribute or reference whose kind changed.
        case feature

        /// An attribute.
        case attribute

        /// A reference.
        case reference

        /// An operation.
        case operation

        /// A literal of an enumeration.
        case literal

        /// An object of a model.
        case object

        /// The words that name the kind of element in a text report.
        var text: String {
            switch self {
            case .dataType: return "data type"
            default: return rawValue
            }
        }
    }

    /// Whether the element was added, removed or changed.
    var change: Change

    /// The kind of element.
    var element: Element

    /// The qualified name of a metamodel element, such as `Order.total`, or the label of an object.
    var path: String

    /// The location of an object within its model, if the element is an object.
    var location: String?

    /// The property or feature that changed, if the element exists in both documents.
    var property: String?

    /// The original value, or the description of a removed element.
    var original: String?

    /// The revised value, or the description of an added element.
    var revised: String?

    /// The line of the difference in a text report.
    ///
    /// For example `+ attribute Customer.phone: EString [0..1]` or
    /// `~ object Order 'A-1' (//@orders.0) status: "PAID" -> "SHIPPED"`.
    var text: String {
        var line = "\(change.marker) \(element.text) \(path)"
        if let location { line += " (\(location))" }
        switch change {
        case .changed:
            if let property { line += " \(property)" }
            line += ": " + (original ?? ComparisonVocabulary.none) + ComparisonVocabulary.changeArrow
                + (revised ?? ComparisonVocabulary.none)
        case .added:
            if let revised { line += ": " + revised }
        case .removed:
            if let original { line += ": " + original }
        }
        return line
    }
}

/// The numbers of differences of a comparison.
struct ComparisonSummary: Codable, Sendable, Equatable {
    /// The number of differences.
    var differences: Int

    /// The number of added elements or objects.
    var added: Int

    /// The number of removed elements or objects.
    var removed: Int

    /// The number of changed properties or values.
    var changed: Int

    /// The numbers of added, removed, changed and unchanged objects of two models.
    var objects: ObjectChanges?

    /// Counts the differences of a comparison.
    ///
    /// - Parameters:
    ///   - differences: The differences.
    ///   - objects: The numbers of objects of two models, or `nil` for metamodels.
    init(differences: [Difference], objects: ObjectChanges?) {
        self.differences = differences.count
        added = differences.filter { $0.change == .added }.count
        removed = differences.filter { $0.change == .removed }.count
        changed = differences.filter { $0.change == .changed }.count
        self.objects = objects
    }

    /// The summary line, such as `3 differences: 1 added, 1 removed, 1 changed`.
    var text: String {
        guard differences > 0 else { return ComparisonVocabulary.noDifferences }
        let noun = differences == 1 ? ComparisonVocabulary.differenceSingular : ComparisonVocabulary.differencePlural
        return "\(differences) \(noun): \(added) added, \(removed) removed, \(changed) changed"
    }
}

/// The numbers of objects of two models that were added, removed, changed or left unchanged.
struct ObjectChanges: Codable, Sendable, Equatable {
    /// The objects of the revised model only.
    var added: Int

    /// The objects of the original model only.
    var removed: Int

    /// The objects of both models with at least one changed value.
    var changed: Int

    /// The objects of both models with the same values.
    var unchanged: Int

    /// The line of a summary, such as `Objects: 1 added, 0 removed, 2 changed, 4 unchanged`.
    var text: String {
        "Objects: \(added) added, \(removed) removed, \(changed) changed, \(unchanged) unchanged"
    }
}

/// A count in the original and in the revised document.
struct CountComparison: Codable, Sendable, Equatable {
    /// What is counted, such as a class name or `Classes`.
    var name: String

    /// The count in the original document.
    var original: Int

    /// The count in the revised document.
    var revised: Int

    /// The revised count minus the original count.
    var difference: Int

    /// Creates a comparison of two counts.
    ///
    /// - Parameters:
    ///   - name: What is counted.
    ///   - original: The count in the original document.
    ///   - revised: The count in the revised document.
    init(name: String, original: Int, revised: Int) {
        self.name = name
        self.original = original
        self.revised = revised
        difference = revised - original
    }

    /// The line of the count, such as `Product: 0 -> 2 (+2)` or `Order: 2 -> 2`.
    var text: String {
        let line = "\(name): \(original)\(ComparisonVocabulary.changeArrow)\(revised)"
        guard difference != 0 else { return line }
        return line + " (" + (difference > 0 ? "+" : "") + "\(difference))"
    }
}
