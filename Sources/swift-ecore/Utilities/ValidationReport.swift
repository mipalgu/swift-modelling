//
// ValidationReport.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A problem that validation found.
struct ValidationFinding: Codable, Sendable, Equatable {
    /// How serious a problem is.
    enum Severity: String, Codable, Sendable, Comparable {
        /// The document does not conform; validation fails.
        case error

        /// The document conforms, but probably not as intended; validation fails in strict mode.
        case warning

        /// A remark that needs no action.
        case information

        /// Orders severities from the most to the least serious.
        static func < (lhs: Severity, rhs: Severity) -> Bool {
            let order: [Severity] = [.error, .warning, .information]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }

    /// How serious the problem is.
    var severity: Severity

    /// The stable identifier of the check that found the problem, such as `model.lowerBound`.
    var code: String

    /// Where the problem is: the fragment of an object or a metamodel element, if known.
    var location: String?

    /// The description of the object or element that has the problem, if known.
    var element: String?

    /// What the problem is.
    var message: String
}

/// An abstract class or interface of a metamodel and the classes that can stand in for it.
struct AbstractClassSummary: Codable, Sendable, Equatable {
    /// The name of the class.
    var name: String

    /// Whether the class is an interface rather than an abstract class.
    var interface: Bool

    /// The names of the concrete classes that extend the class, directly or indirectly.
    var concreteSubclasses: [String]
}

/// What the validate command found in a metamodel or a model.
struct ValidationReport: Codable, Sendable, Equatable {
    /// The name of the validated file.
    var file: String

    /// Whether the file is a metamodel or a model.
    var kind: InspectionReport.Kind

    /// The format in which the file was read, such as `XMI`.
    var format: String

    /// The metamodel files that the model was validated against, as given on the command line.
    var metamodels: [String]

    /// Whether warnings count as errors.
    var strict: Bool

    /// Whether the file passed validation.
    var valid: Bool

    /// The number of errors.
    var errors: Int

    /// The number of warnings.
    var warnings: Int

    /// The problems found, the most serious first and otherwise in document order.
    var findings: [ValidationFinding]

    /// The abstract classes and interfaces of a metamodel, if they were checked.
    var abstractClasses: [AbstractClassSummary]?

    /// The evaluations of the OCL invariants, if the metamodel declares any.
    var constraints: [ConstraintCheck]?

    /// Creates a report from the findings and checks of a validation.
    ///
    /// - Parameters:
    ///   - document: The validated document.
    ///   - metamodelPaths: The metamodel files given on the command line.
    ///   - strict: Whether warnings count as errors.
    ///   - findings: The problems found.
    ///   - abstractClasses: The abstract classes that were checked, if any.
    ///   - constraints: The evaluated invariants, if any.
    init(
        document: ModelDocument, metamodelPaths: [String], strict: Bool, findings: [ValidationFinding],
        abstractClasses: [AbstractClassSummary]?, constraints: [ConstraintCheck]?
    ) {
        file = document.fileName
        kind = document.isMetamodel ? .metamodel : .model
        format = document.formatName
        metamodels = metamodelPaths
        self.strict = strict
        self.findings = findings.enumerated()
            .sorted { ($0.element.severity, $0.offset) < ($1.element.severity, $1.offset) }
            .map(\.element)
        errors = findings.filter { $0.severity == .error }.count
        warnings = findings.filter { $0.severity == .warning }.count
        valid = errors == 0 && (!strict || warnings == 0)
        self.abstractClasses = abstractClasses
        self.constraints = constraints
    }

    /// The report as a JSON document, with sorted keys and indentation.
    ///
    /// - Returns: The JSON text, ending with a line break.
    /// - Throws: The error of the encoder.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self) + "\n"
    }

    /// The report as text, one line per finding and evaluated invariant.
    ///
    /// Satisfied invariants are listed only when `verbose` is set; violated ones always are, as
    /// the line of their evaluation rather than as a separate finding.
    ///
    /// - Parameter verbose: Whether satisfied invariants are listed too.
    /// - Returns: The text, ending with a line break, or empty if there is nothing to report.
    func text(verbose: Bool) -> String {
        var lines: [String] = []
        if let abstractClasses {
            lines.append("Abstract classes and interfaces: \(abstractClasses.count)")
            for summary in abstractClasses {
                let kind = summary.interface ? ModelVocabulary.interfaceFlag : ModelVocabulary.abstractFlag
                let subclasses = summary.concreteSubclasses.isEmpty
                    ? "no concrete subclass" : "concrete subclasses " + summary.concreteSubclasses.joined(separator: ", ")
                lines.append("  \(summary.name) (\(kind)): \(subclasses)")
            }
        }
        if let constraints, !constraints.isEmpty {
            for check in constraints where verbose || check.outcome != .satisfied {
                lines.append(Self.text(of: check))
            }
            let satisfied = constraints.filter { $0.outcome == .satisfied }.count
            lines.append("OCL invariants: \(satisfied) of \(constraints.count) check(s) satisfied")
        }
        for finding in findings where finding.code != ValidationCode.invariant {
            var line = "\(finding.severity.rawValue): "
            if let element = finding.element { line += element }
            if let location = finding.location { line += finding.element == nil ? location : " (\(location))" }
            if finding.element != nil || finding.location != nil { line += ": " }
            lines.append(line + finding.message)
        }
        return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }

    /// The line of one evaluated invariant.
    ///
    /// - Parameter check: The evaluation.
    /// - Returns: For example `Checking constraint: validEmail (Customer 'Tommy Young', //@customers.0) ... violated`.
    static func text(of check: ConstraintCheck) -> String {
        var line = "Checking constraint: \(check.constraint) (\(check.object), \(check.location)) ... \(check.outcome.rawValue)"
        if let detail = check.detail { line += " (\(detail))" }
        return line
    }
}
