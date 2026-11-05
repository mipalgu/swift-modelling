//
// StatisticsReport.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The measurements that the statistics command took of a metamodel or a model.
///
/// The report holds the same information whether it is written as text or as JSON.
struct StatisticsReport: Codable, Sendable, Equatable {
    /// The name of the measured file.
    var file: String

    /// Whether the file is a metamodel or a model.
    var kind: InspectionReport.Kind

    /// The format in which the file was read, such as `XMI`.
    var format: String

    /// The measurements of a metamodel, or `nil` for a model.
    var metamodel: MetamodelStatistics?

    /// The measurements of a model, or `nil` for a metamodel.
    var model: ModelStatistics?

    /// The report as a JSON document, with sorted keys and indentation.
    ///
    /// - Returns: The JSON text, ending with a line break.
    /// - Throws: The error of the encoder.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self) + "\n"
    }

    /// The report as text, one measurement per line.
    ///
    /// - Returns: The text, ending with a line break.
    func text() -> String {
        var lines = ["\(kind == .metamodel ? "Metamodel" : "Model"): \(file) (\(format))"]
        if let metamodel { lines += metamodel.lines }
        if let model { lines += model.lines }
        return lines.joined(separator: "\n") + "\n"
    }
}

/// The class that holds the largest value of a measurement, and that value.
struct Extreme: Codable, Sendable, Equatable {
    /// The largest value, or zero if there is no class.
    var count: Int

    /// The class with the largest value, the first in alphabetical order on a tie, or `nil` if
    /// the value is zero.
    var className: String?

    /// The value followed by the class in parentheses, such as `4 (Manager)`.
    var text: String {
        className.map { "\(count) (\($0))" } ?? "\(count)"
    }

    /// Finds the class with the largest value.
    ///
    /// - Parameter values: The value of each class.
    /// - Returns: The largest value and its class, the first in alphabetical order on a tie.
    static func largest(of values: [(name: String, count: Int)]) -> Extreme {
        let best = values.sorted { ($1.count, $0.name) < ($0.count, $1.name) }.first
        guard let best, best.count > 0 else { return Extreme(count: 0) }
        return Extreme(count: best.count, className: best.name)
    }
}

/// The average and the largest number of features of the classes of a metamodel.
struct FeatureDistribution: Codable, Sendable, Equatable {
    /// The number of features per class, rounded to ``StatisticsVocabulary/averageDecimals`` places.
    var average: Double

    /// The largest number of features of a class.
    var maximum: Extreme

    /// Measures the numbers of features of classes.
    ///
    /// - Parameter values: The number of features of each class.
    init(_ values: [(name: String, count: Int)]) {
        let scale = pow(10, Double(StatisticsVocabulary.averageDecimals))
        let mean = values.isEmpty ? 0 : Double(values.map(\.count).reduce(0, +)) / Double(values.count)
        average = (mean * scale).rounded() / scale
        maximum = Extreme.largest(of: values)
    }

    /// The text of the distribution, such as `average 1.20, maximum 2 (Office)`.
    var text: String {
        "average " + String(format: "%.\(StatisticsVocabulary.averageDecimals)f", average) + ", maximum " + maximum.text
    }
}

/// The number of features of one class.
struct ClassFeatureCount: Codable, Sendable, Equatable {
    /// The name of the class.
    var name: String

    /// The number of features, including the inherited ones.
    var features: Int

    /// The number of features that the class declares itself.
    var declared: Int
}

/// The measurements of a metamodel.
struct MetamodelStatistics: Codable, Sendable, Equatable {
    /// The number of packages, including subpackages.
    var packages: Int

    /// The number of classes.
    var classes: Int

    /// The number of abstract classes that are not interfaces.
    var abstractClasses: Int

    /// The number of interfaces.
    var interfaces: Int

    /// The number of enumerations.
    var enumerations: Int

    /// The number of literals of all enumerations.
    var literals: Int

    /// The number of data types that are not enumerations.
    var dataTypes: Int

    /// The number of attributes that the classes declare.
    var attributes: Int

    /// The number of references that the classes declare.
    var references: Int

    /// The number of containment references.
    var containmentReferences: Int

    /// The number of pairs of references that are each other's opposites.
    var bidirectionalPairs: Int

    /// The number of operations that the classes declare.
    var operations: Int

    /// The number of OCL invariants that the classes declare.
    var invariants: Int

    /// The longest chain of supertypes above a class.
    var maximumInheritanceDepth: Extreme

    /// The largest number of classes that directly extend one class.
    var maximumDirectSubclasses: Extreme

    /// The features that each class declares.
    var declaredFeatures: FeatureDistribution

    /// The features of each class, including the inherited ones.
    var allFeatures: FeatureDistribution

    /// Every class with its number of features, the most first, ties in alphabetical order.
    var classesByFeatures: [ClassFeatureCount]

    /// The lines of the measurements in a text report.
    var lines: [String] {
        let indent = StatisticsVocabulary.indent
        return [
            "Packages: \(packages)",
            "Classes: \(classes)",
            indent + "Abstract: \(abstractClasses)",
            indent + "Interfaces: \(interfaces)",
            "Enumerations: \(enumerations)",
            indent + "Literals: \(literals)",
            "Data types: \(dataTypes)",
            "Attributes: \(attributes)",
            "References: \(references)",
            indent + "Containment: \(containmentReferences)",
            indent + "Bidirectional pairs: \(bidirectionalPairs)",
            "Operations: \(operations)",
            "OCL invariants: \(invariants)",
            "Maximum inheritance depth: " + maximumInheritanceDepth.text,
            "Maximum direct subclasses: " + maximumDirectSubclasses.text,
            StatisticsVocabulary.featuresPerClassHeading,
            indent + "Declared: " + declaredFeatures.text,
            indent + "With inherited: " + allFeatures.text,
            StatisticsVocabulary.classesByFeaturesHeading,
        ] + classesByFeatures.map { indent + "\($0.name): \($0.features) (\($0.declared) declared)" }
    }
}

/// The measurements of a model.
struct ModelStatistics: Codable, Sendable, Equatable {
    /// The number of objects, including every contained object.
    var objects: Int

    /// The number of root objects.
    var rootObjects: Int

    /// The number of classes that have objects.
    var classesInstantiated: Int

    /// The number of objects of each class, in alphabetical order.
    var classes: [ClassCount]

    /// The number of containers between the most deeply nested object and its root.
    var maximumContainmentDepth: Int

    /// The number of attributes that the objects set.
    var attributeValues: Int

    /// The number of objects that another object contains.
    var containmentLinks: Int

    /// The number of references to objects that the referring object does not contain.
    var crossReferences: Int

    /// The number of cross-references into other documents.
    var externalReferences: Int

    /// The number of cross-references that lead to no object, into other documents or not.
    var unresolvedReferences: Int

    /// The concrete classes of the metamodels that have no objects, or `nil` without a metamodel.
    var classesWithoutInstances: [String]?

    /// The namespace URIs of the metamodels that the model was read with.
    var metamodels: [String]

    /// The lines of the measurements in a text report.
    var lines: [String] {
        let indent = StatisticsVocabulary.indent
        var lines = [
            "Objects: \(objects)",
            "Root objects: \(rootObjects)",
            "Classes instantiated: \(classesInstantiated)",
            StatisticsVocabulary.objectsPerClassHeading,
        ]
        lines += classes.map { indent + "\($0.name): \($0.count)" }
        lines += [
            "Maximum containment depth: \(maximumContainmentDepth)",
            "Attribute values: \(attributeValues)",
            "Containment links: \(containmentLinks)",
            "Cross-references: \(crossReferences)",
            indent + "Into other documents: \(externalReferences)",
            indent + "Unresolved: \(unresolvedReferences)",
        ]
        if let classesWithoutInstances {
            lines.append("Concrete classes without instances: \(classesWithoutInstances.count)")
            lines += classesWithoutInstances.map { indent + $0 }
        }
        return lines
    }
}
