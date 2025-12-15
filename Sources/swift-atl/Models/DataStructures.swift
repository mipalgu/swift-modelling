//
// DataStructures.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ATL
import Foundation

// MARK: - Parse Result

/// Result of parsing an ATL transformation file.
///
/// Contains comprehensive information about the parsing operation,
/// including the parsed module structure, timing metrics, and any
/// error information if parsing failed.
struct ParseResult {
    /// Name of the file that was parsed.
    let filename: String

    /// Whether parsing completed successfully.
    let success: Bool

    /// The parsed ATL module, if parsing succeeded.
    let module: ATLModule?

    /// Time taken to parse the file, in seconds.
    let parseTime: TimeInterval

    /// Error message if parsing failed.
    let error: String?

    /// Generates a concise summary of the parse result.
    ///
    /// For successful parses, includes module name and rule/helper counts.
    /// For failures, includes the error message.
    ///
    /// - Returns: A formatted summary string
    /// Generates a concise summary of the analysis result.
    ///
    /// Includes key metrics such as lines of code, rule counts,
    /// and helper counts when available.
    ///
    /// - Returns: A formatted summary string
    var summary: String {
        if success, let module = module {
            return
                "\(module.name) (rules: \(module.matchedRules.count + module.calledRules.count), helpers: \(module.helpers.count))"
        } else {
            return "FAILED - \(error ?? "Unknown error")"
        }
    }

    /// Converts the parse result to a JSON-compatible dictionary.
    ///
    /// Creates a dictionary representation suitable for JSON serialisation,
    /// including all relevant parsing information and metrics.
    ///
    /// - Returns: A dictionary that can be serialised to JSON
    /// Converts the analysis result to a JSON-compatible dictionary.
    ///
    /// Creates a dictionary representation suitable for JSON serialisation,
    /// including all metrics, analyses, and identified patterns.
    ///
    /// - Returns: A dictionary that can be serialised to JSON
    func toJSONRepresentation() -> [String: Any] {
        var json: [String: Any] = [
            "filename": filename,
            "success": success,
            "parseTime": parseTime,
        ]

        if let module = module {
            json["module"] = [
                "name": module.name,
                "matchedRules": module.matchedRules.count,
                "calledRules": module.calledRules.count,
                "helpers": module.helpers.count,
                "sourceMetamodels": Array(module.sourceMetamodels.keys),
                "targetMetamodels": Array(module.targetMetamodels.keys),
            ]
        }

        if let error = error {
            json["error"] = error
        }

        return json
    }
}

// MARK: - Validation Result

/// Result of validating an ATL transformation file.
///
/// Contains validation errors and warnings discovered during
/// comprehensive analysis of the transformation syntax and semantics.
struct ValidationResult {
    /// Name of the file that was validated.
    let filename: String

    /// Time taken to validate the file, in seconds.
    let validationTime: TimeInterval

    /// List of validation errors found.
    let errors: [ValidationIssue]

    /// List of validation warnings found.
    let warnings: [ValidationIssue]

    /// Whether the file is valid (has no errors).
    var isValid: Bool { errors.isEmpty }
}

/// Represents a single validation issue found during analysis.
///
/// Contains detailed information about the issue type, location,
/// and descriptive message for diagnostic purposes.
struct ValidationIssue {
    /// Type of validation issue.
    let type: IssueType

    /// Descriptive message explaining the issue.
    let message: String

    /// Line number where the issue occurs, if available.
    let line: Int?

    /// Column number where the issue occurs, if available.
    let column: Int?

    /// Classification of validation issues.
    enum IssueType {
        /// A critical issue that prevents valid transformation.
        case error
        /// A potential issue that should be reviewed.
        case warning
    }
}

// MARK: - Test Result

/// Result of testing an ATL transformation file.
///
/// Contains information about test execution success,
/// timing metrics, and any error details.
struct TestResult {
    /// Name of the file that was tested.
    let filename: String

    /// Whether all tests passed successfully.
    let passed: Bool

    /// Time taken to run the tests, in seconds.
    let testTime: TimeInterval

    /// Error message if tests failed.
    let error: String?
}

/// Errors that can occur during test execution.
enum TestError: Error {
    /// Test execution exceeded the configured timeout limit.
    case timeout
}

// MARK: - Analysis Result

/// Result of analysing an ATL transformation file.
///
/// Contains comprehensive metrics about transformation complexity,
/// rule and helper analysis, and identified patterns.
struct AnalysisResult {
    /// Name of the file that was analysed.
    let filename: String

    /// Time taken to analyse the file, in seconds.
    var analysisTime: TimeInterval

    /// Complexity metrics for the transformation.
    var complexity: ComplexityMetrics?

    /// Analysis of transformation rules.
    var ruleAnalysis: RuleAnalysis?

    /// Analysis of helper functions.
    var helperAnalysis: HelperAnalysis?

    /// Identified transformation patterns.
    var patterns: [String] = []

    var summary: String {
        var parts: [String] = []
        if let complexity = complexity {
            parts.append("\(complexity.linesOfCode) LOC")
            parts.append("\(complexity.totalRules) rules")
            parts.append("\(complexity.totalHelpers) helpers")
        }
        return parts.isEmpty ? "analyzed" : parts.joined(separator: ", ")
    }

    func toJSONRepresentation() -> [String: Any] {
        var json: [String: Any] = [
            "filename": filename,
            "analysisTime": analysisTime,
            "patterns": patterns,
        ]

        if let complexity = complexity {
            json["complexity"] = [
                "linesOfCode": complexity.linesOfCode,
                "commentLines": complexity.commentLines,
                "totalRules": complexity.totalRules,
                "totalHelpers": complexity.totalHelpers,
                "cyclomaticComplexity": complexity.cyclomaticComplexity,
                "maintainabilityIndex": complexity.maintainabilityIndex,
            ]
        }

        if let ruleAnalysis = ruleAnalysis {
            json["ruleAnalysis"] = [
                "matchedRules": ruleAnalysis.matchedRules,
                "calledRules": ruleAnalysis.calledRules,
                "uniqueSourceTypes": ruleAnalysis.uniqueSourceTypes,
                "uniqueTargetTypes": ruleAnalysis.uniqueTargetTypes,
                "averageTargetPatterns": ruleAnalysis.averageTargetPatterns,
            ]
        }

        if let helperAnalysis = helperAnalysis {
            json["helperAnalysis"] = [
                "totalHelpers": helperAnalysis.totalHelpers,
                "contextHelpers": helperAnalysis.contextHelpers,
                "uniqueReturnTypes": helperAnalysis.uniqueReturnTypes,
                "averageParameters": helperAnalysis.averageParameters,
            ]
        }

        return json
    }
}

/// Metrics for measuring transformation complexity.
///
/// Contains various measurements that indicate the complexity
/// and maintainability of an ATL transformation.
struct ComplexityMetrics {
    /// Total number of lines of code.
    let linesOfCode: Int

    /// Number of comment lines.
    let commentLines: Int

    /// Total number of transformation rules.
    let totalRules: Int

    /// Total number of helper functions.
    let totalHelpers: Int

    /// Cyclomatic complexity score.
    let cyclomaticComplexity: Int

    /// Maintainability index (0-100, higher is better).
    let maintainabilityIndex: Double
}

/// Analysis metrics for transformation rules.
///
/// Provides detailed statistics about the rules defined
/// in an ATL transformation module.
struct RuleAnalysis {
    /// Number of matched (automatic) rules.
    let matchedRules: Int

    /// Number of called (lazy) rules.
    let calledRules: Int

    /// Number of unique source element types.
    let uniqueSourceTypes: Int

    /// Number of unique target element types.
    let uniqueTargetTypes: Int

    /// Average number of target patterns per rule.
    let averageTargetPatterns: Double
}

/// Analysis metrics for helper functions.
///
/// Provides detailed statistics about the helper functions
/// defined in an ATL transformation module.
struct HelperAnalysis {
    /// Total number of helper functions.
    let totalHelpers: Int

    /// Number of helpers with context types.
    let contextHelpers: Int

    /// Number of unique return types across helpers.
    let uniqueReturnTypes: Int

    /// Average number of parameters per helper.
    let averageParameters: Double
}

// MARK: - Model Format

/// Supported model file formats for transformation operations.
///
/// Represents the different file formats that can be used for loading
/// and saving models during ATL transformations.
enum ModelFormat {
    /// XMI format (XML Metadata Interchange).
    case xmi

    /// JSON format for model representation.
    case json

    /// Human-readable description of the format.
    ///
    /// - Returns: A string describing the format
    var description: String {
        switch self {
        case .xmi: return "XMI"
        case .json: return "JSON"
        }
    }
}
