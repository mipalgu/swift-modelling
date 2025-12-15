//
// AnalyzeCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import Foundation

/// Command for analysing ATL transformation files.
///
/// The analyse command performs comprehensive analysis of ATL transformation files,
/// computing complexity metrics, identifying patterns, and generating detailed
/// analysis reports for transformation quality assessment.
struct AnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze ATL transformation files",
        discussion: """
            Provides comprehensive analysis of ATL transformation files including
            complexity metrics, rule analysis, helper function analysis, and
            transformation pattern detection.

            Examples:
                swift-atl analyze Families2Persons.atl
                swift-atl analyze *.atl --metrics complexity,rules,helpers
                swift-atl analyze transformation.atl --output analysis.json
            """
    )

    @Argument(help: "ATL source files to analyze")
    var atlFiles: [String] = []

    @Option(name: .long, help: "Analysis metrics to compute (complexity,rules,helpers,patterns)")
    var metrics: String = "all"

    @Option(name: .shortAndLong, help: "Output file for analysis results")
    var output: String?

    @Option(name: .shortAndLong, help: "Output format (text, json)")
    var format: String = "text"

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    func run() async throws {
        guard !atlFiles.isEmpty else {
            throw ValidationError("No ATL files specified")
        }

        let metricsToCompute = parseMetrics(metrics)

        if verbose {
            print("Analyzing \(atlFiles.count) ATL file(s)")
            print("Metrics: \(metricsToCompute.joined(separator: ", "))")
            print("Output format: \(format)")
        }

        var analysisResults: [AnalysisResult] = []

        for atlFile in atlFiles {
            if verbose {
                print("Analyzing: \(atlFile)")
            }

            let result = try await analyzeATLFile(atlFile, metrics: metricsToCompute)
            analysisResults.append(result)

            if !verbose && output == nil {
                print("\(atlFile): \(result.summary)")
            }
        }

        // Generate output
        let outputContent = try generateAnalysisOutput(results: analysisResults, format: format)

        if let outputPath = output {
            try outputContent.write(
                to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            print("Analysis results written to \(outputPath)")
        } else if verbose || analysisResults.count > 1 {
            print(outputContent)
        }
    }

    private func parseMetrics(_ metricsString: String) -> [String] {
        if metricsString.lowercased() == "all" {
            return ["complexity", "rules", "helpers", "patterns"]
        }
        return metricsString.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
    }

    private func analyzeATLFile(_ filePath: String, metrics: [String]) async throws
        -> AnalysisResult
    {
        let startTime = Date()

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ValidationError("File not found: \(filePath)")
        }

        let atlSource = try String(contentsOfFile: filePath, encoding: .utf8)
        let parser = ATLParser()
        let module = try await parser.parseContent(
            atlSource, filename: URL(fileURLWithPath: filePath).lastPathComponent)

        var analysis = AnalysisResult(filename: filePath, analysisTime: 0)

        if metrics.contains("complexity") {
            analysis.complexity = analyzeComplexity(module: module, source: atlSource)
        }

        if metrics.contains("rules") {
            analysis.ruleAnalysis = analyzeRules(module: module)
        }

        if metrics.contains("helpers") {
            analysis.helperAnalysis = analyzeHelpers(module)
        }

        if metrics.contains("patterns") {
            analysis.patterns = identifyPatterns(module)
        }

        analysis.analysisTime = Date().timeIntervalSince(startTime)

        if verbose {
            print("  Analysis time: \(String(format: "%.3f", analysis.analysisTime * 1000))ms")
        }

        return analysis
    }

    private func analyzeComplexity(module: ATLModule, source: String) -> ComplexityMetrics {
        let lines = source.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let commentLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("--") }

        return ComplexityMetrics(
            linesOfCode: nonEmptyLines.count,
            commentLines: commentLines.count,
            totalRules: module.matchedRules.count + module.calledRules.count,
            totalHelpers: module.helpers.count,
            cyclomaticComplexity: calculateCyclomaticComplexity(module: module),
            maintainabilityIndex: calculateMaintainabilityIndex(
                linesOfCode: nonEmptyLines.count,
                commentRatio: Double(commentLines.count) / Double(lines.count))
        )
    }

    private func calculateCyclomaticComplexity(module: ATLModule) -> Int {
        // Simplified cyclomatic complexity calculation
        // In practice, this would analyze expressions and control flow
        var complexity = 1  // Base complexity
        complexity += module.matchedRules.count
        complexity += module.calledRules.count
        return complexity
    }

    private func calculateMaintainabilityIndex(linesOfCode: Int, commentRatio: Double) -> Double {
        // Simplified maintainability index calculation
        // Real calculation would include Halstead metrics and cyclomatic complexity
        let baseIndex = 100.0
        let locPenalty = Double(linesOfCode) * 0.1
        let commentBonus = commentRatio * 20.0
        return max(0, baseIndex - locPenalty + commentBonus)
    }

    private func analyzeRules(module: ATLModule) -> RuleAnalysis {
        var sourceTypes = Set<String>()
        var targetTypes = Set<String>()

        for rule in module.matchedRules {
            sourceTypes.insert(rule.sourcePattern.type)
            for pattern in rule.targetPatterns {
                targetTypes.insert(pattern.type)
            }
        }

        return RuleAnalysis(
            matchedRules: module.matchedRules.count,
            calledRules: module.calledRules.count,
            uniqueSourceTypes: sourceTypes.count,
            uniqueTargetTypes: targetTypes.count,
            averageTargetPatterns: module.matchedRules.isEmpty
                ? 0
                : Double(module.matchedRules.reduce(0) { $0 + $1.targetPatterns.count })
                    / Double(module.matchedRules.count)
        )
    }

    /// Analyses transformation rules in an ATL module.
    ///
    /// Examines matched and called rules to compute rule-specific metrics
    /// including rule counts and type usage statistics.
    ///
    /// - Parameter module: The ATL module to analyse
    /// - Returns: A `RuleAnalysis` object containing rule metrics
    /// Analyses helper functions in an ATL module.
    ///
    /// Examines helper definitions to compute helper-specific metrics
    /// including counts, parameter statistics, and return type analysis.
    ///
    /// - Parameter module: The ATL module to analyse
    /// - Returns: A `HelperAnalysis` object containing helper metrics
    private func analyzeHelpers(_ module: ATLModule) -> HelperAnalysis {
        var contextTypes = Set<String>()
        var returnTypes = Set<String>()
        var totalParameters = 0

        for (_, helper) in module.helpers {
            if let contextType = helper.contextType {
                contextTypes.insert(contextType)
            }
            returnTypes.insert(helper.returnType)
            totalParameters += helper.parameters.count
        }

        return HelperAnalysis(
            totalHelpers: module.helpers.count,
            contextHelpers: contextTypes.count,
            uniqueReturnTypes: returnTypes.count,
            averageParameters: module.helpers.isEmpty
                ? 0 : Double(totalParameters) / Double(module.helpers.count)
        )
    }

    /// Identifies transformation patterns in an ATL module.
    ///
    /// Detects common transformation patterns and potential anti-patterns
    /// that may affect transformation quality or performance.
    ///
    /// - Parameter module: The ATL module to analyse
    /// - Returns: An array of identified pattern descriptions
    private func identifyPatterns(_ module: ATLModule) -> [String] {
        var patterns: [String] = []

        if module.matchedRules.count > module.calledRules.count {
            patterns.append("Transformation-heavy (more matched rules than called rules)")
        }

        if module.helpers.count > module.matchedRules.count {
            patterns.append("Helper-heavy (more helpers than rules)")
        }

        if module.sourceMetamodels.count > 1 {
            patterns.append("Multi-source transformation")
        }

        if module.targetMetamodels.count > 1 {
            patterns.append("Multi-target transformation")
        }

        return patterns.isEmpty ? ["Standard transformation pattern"] : patterns
    }

    private func generateAnalysisOutput(results: [AnalysisResult], format: String) throws -> String
    {
        switch format.lowercased() {
        case "json":
            let jsonData = try JSONSerialization.data(
                withJSONObject: results.map { $0.toJSONRepresentation() }, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? ""
        default:
            return generateAnalysisReport(results)
        }
    }

    /// Generates a formatted analysis report.
    ///
    /// Creates a comprehensive analysis report from the analysis results,
    /// including metrics summaries and pattern identifications.
    ///
    /// - Parameter results: Array of analysis results from analysed files
    /// - Returns: A formatted string containing the complete analysis report
    private func generateAnalysisReport(_ results: [AnalysisResult]) -> String {
        var output = "ATL Analysis Results\n"
        output += "====================\n\n"

        for result in results {
            output += "File: \(result.filename)\n"
            output += "Analysis time: \(String(format: "%.3f", result.analysisTime * 1000))ms\n"

            if let complexity = result.complexity {
                output += "\nComplexity Metrics:\n"
                output += "  Lines of code: \(complexity.linesOfCode)\n"
                output += "  Comment lines: \(complexity.commentLines)\n"
                output += "  Total rules: \(complexity.totalRules)\n"
                output += "  Total helpers: \(complexity.totalHelpers)\n"
                output += "  Cyclomatic complexity: \(complexity.cyclomaticComplexity)\n"
                output +=
                    "  Maintainability index: \(String(format: "%.1f", complexity.maintainabilityIndex))\n"
            }

            if let ruleAnalysis = result.ruleAnalysis {
                output += "\nRule Analysis:\n"
                output += "  Matched rules: \(ruleAnalysis.matchedRules)\n"
                output += "  Called rules: \(ruleAnalysis.calledRules)\n"
                output += "  Unique source types: \(ruleAnalysis.uniqueSourceTypes)\n"
                output += "  Unique target types: \(ruleAnalysis.uniqueTargetTypes)\n"
                output +=
                    "  Average target patterns: \(String(format: "%.1f", ruleAnalysis.averageTargetPatterns))\n"
            }

            if let helperAnalysis = result.helperAnalysis {
                output += "\nHelper Analysis:\n"
                output += "  Total helpers: \(helperAnalysis.totalHelpers)\n"
                output += "  Context helpers: \(helperAnalysis.contextHelpers)\n"
                output += "  Unique return types: \(helperAnalysis.uniqueReturnTypes)\n"
                output +=
                    "  Average parameters: \(String(format: "%.1f", helperAnalysis.averageParameters))\n"
            }

            if !result.patterns.isEmpty {
                output += "\nDetected Patterns:\n"
                for pattern in result.patterns {
                    output += "  - \(pattern)\n"
                }
            }

            output += "\n"
        }

        return output
    }
}

// MARK: - Compile Command

/// Command for compiling ATL transformation files to executable modules.
///
/// The compile command processes ATL source files and produces compiled transformation
/// modules that can be executed efficiently by the ATL virtual machine. Compilation
/// includes syntax analysis, type checking, and optimization for performance.
