//
// ParseCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import ArgumentParser
import Foundation

/// Command for parsing ATL transformation files.
///
/// The parse command processes ATL source files and provides detailed information
/// about their structure, including modules, rules, helpers, and expressions.
/// It validates syntax and provides comprehensive parsing diagnostics.
struct ParseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse and analyze ATL transformation files",
        discussion: """
            Parses ATL transformation source files and displays detailed information
            about their structure. Performs syntax validation and provides comprehensive
            diagnostics about modules, rules, helpers, and expressions.

            Examples:
                swift-atl parse Families2Persons.atl --verbose
                swift-atl parse *.atl --output parsing-report.txt
                swift-atl parse transformation.atl --format json
            """
    )

    @Argument(help: "ATL source files to parse")
    var atlFiles: [String] = []

    @Option(name: .shortAndLong, help: "Output format (text, json, xml)")
    var format: String = "text"

    @Option(name: .shortAndLong, help: "Output file for parsing results")
    var output: String?

    @Option(name: .long, help: "Metamodel search path (can be specified multiple times)")
    var metamodelPath: [String] = []

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(name: .long, inversion: .prefixedEnableDisable, help: "Stop after metamodel loading errors")
    var stopAfterErrors: Bool = false

    @Flag(name: .long, help: "Show detailed module structure")
    var showStructure: Bool = false

    @Flag(name: .long, help: "Show rule details")
    var showRules: Bool = false

    @Flag(name: .long, help: "Show helper details")
    var showHelpers: Bool = false

    func run() async throws {
        guard !atlFiles.isEmpty else {
            throw ValidationError("No ATL files specified")
        }

        if verbose {
            print("Parsing \(atlFiles.count) ATL file(s)")
            print("Output format: \(format)")
            if let outputPath = output {
                print("Output will be written to: \(outputPath)")
            }
        }

        var results: [ParseResult] = []

        for atlFile in atlFiles {
            do {
                if verbose {
                    print("Processing: \(atlFile)")
                }

                let parseResult = try await parseATLFile(atlFile)
                results.append(parseResult)

                if !verbose && output == nil {
                    print("Parsed \(atlFile): \(parseResult.summary)")
                }

            } catch {
                let errorResult = ParseResult(
                    filename: atlFile,
                    success: false,
                    module: nil,
                    parseTime: 0,
                    error: error.localizedDescription
                )
                results.append(errorResult)

                if verbose {
                    print("Error parsing \(atlFile): \(error.localizedDescription)")
                } else {
                    print("Failed to parse \(atlFile): \(error.localizedDescription)")
                }
            }
        }

        // Generate output
        let outputContent = try generateParseOutput(results: results, format: format)

        if let outputPath = output {
            try outputContent.write(
                to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            if verbose {
                print("Results written to: \(outputPath)")
            } else {
                print("Parse results written to \(outputPath)")
            }
        } else if verbose || results.count > 1 {
            print(outputContent)
        }
    }

    private func parseATLFile(_ filePath: String) async throws -> ParseResult {
        let startTime = Date()

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw ValidationError("File not found: \(filePath)")
        }

        let atlSource = try String(contentsOfFile: filePath, encoding: .utf8)

        if verbose {
            print("  Source size: \(atlSource.count) characters")
        }

        // Build search paths similar to TransformCommand
        var searchPaths: [String] = []
        var hasUserSpecifiedPaths = false

        // Priority 1: CLI arguments
        if !metamodelPath.isEmpty {
            searchPaths.append(contentsOf: metamodelPath)
            hasUserSpecifiedPaths = true
        }

        // Priority 2: ECOREPATH environment variable
        if let ecorepath = ProcessInfo.processInfo.environment["ECOREPATH"], !ecorepath.isEmpty {
            let paths = ecorepath.split(separator: ":").map(String.init)
            searchPaths.append(contentsOf: paths)
            hasUserSpecifiedPaths = true
        }

        // Only add default search paths if user hasn't specified any
        if !hasUserSpecifiedPaths {
            let atlDirectory = URL(fileURLWithPath: filePath).deletingLastPathComponent().path

            // Default priority 1: ATL file's directory
            searchPaths.append(atlDirectory)

            // Default priority 2: Common metamodel directories relative to ATL file
            let atlParentDir = URL(fileURLWithPath: atlDirectory).deletingLastPathComponent().path
            let commonPaths = [
                "\(atlParentDir)", // Parent of ATL directory
                "\(atlParentDir)/Resources", // Common Resources directory
                "\(atlDirectory)/../Resources", // Resources at same level
                "\(atlDirectory)/../../Resources" // Resources two levels up (for test structures)
            ]
            for path in commonPaths {
                let normalized = URL(fileURLWithPath: path).standardizedFileURL.path
                if !searchPaths.contains(normalized) {
                    searchPaths.append(normalized)
                }
            }

            // Default priority 3: Current working directory
            let currentDirectory = FileManager.default.currentDirectoryPath
            if currentDirectory != atlDirectory {
                searchPaths.append(currentDirectory)
            }
        }

        let parser = ATLParser()
        let module = try await parser.parseContent(
            atlSource,
            filename: URL(fileURLWithPath: filePath).lastPathComponent,
            searchPaths: searchPaths,
            continueAfterErrors: !stopAfterErrors)

        let parseTime = Date().timeIntervalSince(startTime)

        if verbose {
            print("  Parse time: \(String(format: "%.3f", parseTime * 1000))ms")
            print("  Module: \(module.name)")
            print("  Source metamodels: \(module.sourceMetamodels.keys.joined(separator: ", "))")
            print("  Target metamodels: \(module.targetMetamodels.keys.joined(separator: ", "))")
            print("  Matched rules: \(module.matchedRules.count)")
            print("  Called rules: \(module.calledRules.count)")
            print("  Helpers: \(module.helpers.count)")
        }

        return ParseResult(
            filename: filePath,
            success: true,
            module: module,
            parseTime: parseTime,
            error: nil
        )
    }

    private func generateParseOutput(results: [ParseResult], format: String) throws -> String {
        switch format.lowercased() {
        case "json":
            return try generateJSONOutput(results)
        case "xml":
            return generateXMLOutput(results)
        default:
            return generateTextOutput(results)
        }
    }

    private func generateTextOutput(_ results: [ParseResult]) -> String {
        var output = "ATL Parsing Results\n"
        output += "==================\n\n"

        let successful = results.filter { $0.success }
        let failed = results.filter { !$0.success }

        output += "Summary: \(successful.count) successful, \(failed.count) failed\n"

        if !successful.isEmpty {
            let totalParseTime = successful.reduce(0) { $0 + $1.parseTime }
            let avgParseTime = totalParseTime / Double(successful.count)
            output += "Average parse time: \(String(format: "%.3f", avgParseTime * 1000))ms\n"
        }

        output += "\n"

        for result in results {
            output += "File: \(result.filename)\n"
            if result.success, let module = result.module {
                output += "  Status: SUCCESS\n"
                output += "  Parse time: \(String(format: "%.3f", result.parseTime * 1000))ms\n"
                output += "  Module: \(module.name)\n"

                if showStructure {
                    output += "  Source metamodels:\n"
                    for (alias, package) in module.sourceMetamodels {
                        output += "    \(alias): \(package.name) (\(package.nsURI))\n"
                    }
                    output += "  Target metamodels:\n"
                    for (alias, package) in module.targetMetamodels {
                        output += "    \(alias): \(package.name) (\(package.nsURI))\n"
                    }
                }

                if showRules {
                    output += "  Matched rules (\(module.matchedRules.count)):\n"
                    for rule in module.matchedRules {
                        output += "    \(rule.name): \(rule.sourcePattern.type) -> "
                        output += rule.targetPatterns.map { $0.type }.joined(separator: ", ")
                        output += "\n"
                    }
                    output += "  Called rules (\(module.calledRules.count)):\n"
                    for (name, rule) in module.calledRules {
                        output += "    \(name): \(rule.parameters.count) parameters, "
                        output += "\(rule.targetPatterns.count) target patterns\n"
                    }
                }

                if showHelpers {
                    output += "  Helpers (\(module.helpers.count)):\n"
                    for (name, helper) in module.helpers {
                        let contextInfo = helper.contextType.map { " [\($0)]" } ?? ""
                        output += "    \(name)\(contextInfo): \(helper.returnType)\n"
                    }
                }
            } else {
                output += "  Status: FAILED\n"
                if let error = result.error {
                    output += "  Error: \(error)\n"
                }
            }
            output += "\n"
        }

        return output
    }

    private func generateJSONOutput(_ results: [ParseResult]) throws -> String {
        let jsonData = try JSONSerialization.data(
            withJSONObject: results.map { $0.toJSONRepresentation() }, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    private func generateXMLOutput(_ results: [ParseResult]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<atl-parse-results>\n"

        for result in results {
            xml += "  <result>\n"
            xml += "    <filename>\(xmlEscape(result.filename))</filename>\n"
            xml += "    <success>\(result.success)</success>\n"
            xml += "    <parse-time>\(result.parseTime)</parse-time>\n"

            if let module = result.module {
                xml += "    <module>\n"
                xml += "      <name>\(xmlEscape(module.name))</name>\n"
                xml += "      <matched-rules>\(module.matchedRules.count)</matched-rules>\n"
                xml += "      <called-rules>\(module.calledRules.count)</called-rules>\n"
                xml += "      <helpers>\(module.helpers.count)</helpers>\n"
                xml += "    </module>\n"
            }

            if let error = result.error {
                xml += "    <error>\(xmlEscape(error))</error>\n"
            }

            xml += "  </result>\n"
        }

        xml += "</atl-parse-results>\n"
        return xml
    }

    private func xmlEscape(_ string: String) -> String {
        return
            string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
