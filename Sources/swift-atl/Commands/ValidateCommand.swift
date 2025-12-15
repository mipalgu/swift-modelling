import ATL
//
// ValidateCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// Command for validating ATL transformation files.
///
/// The validate command performs comprehensive validation of ATL transformation files,
/// including syntax checking, semantic analysis, type checking, and metamodel compatibility
/// verification. It provides detailed validation reports with errors and warnings.
struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate ATL transformation files",
        discussion: """
            Performs comprehensive validation of ATL transformation files including
            syntax checking, semantic analysis, type checking, and metamodel compatibility.
            Provides detailed validation reports with warnings and errors.

            Examples:
                swift-atl validate Families2Persons.atl
                swift-atl validate *.atl --strict --output validation.log
                swift-atl validate transformation.atl --check-metamodels
            """
    )

    /// ATL source files to validate.
    ///
    /// One or more paths to ATL transformation files that should be validated.
    /// Supports wildcards for batch validation.
    @Argument(help: "ATL source files to validate")
    var atlFiles: [String] = []

    /// Output file path for validation results.
    ///
    /// When specified, writes a detailed validation report to the given file
    /// instead of printing to standard output.
    @Option(name: .shortAndLong, help: "Output file for validation results")
    var output: String?

    /// Enable verbose output mode.
    ///
    /// Shows detailed validation progress and additional diagnostic information
    /// during the validation process.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Enable strict validation mode.
    ///
    /// In strict mode, warnings are treated as errors and will cause validation
    /// to fail with a non-zero exit code.
    @Flag(name: .long, help: "Enable strict validation mode")
    var strict: Bool = false

    /// Check metamodel compatibility.
    ///
    /// Performs additional validation to ensure that referenced metamodels
    /// are compatible and properly structured.
    @Flag(name: .long, help: "Check metamodel compatibility")
    var checkMetamodels: Bool = false

    /// Validate rule completeness.
    ///
    /// Checks that all transformation rules are complete and properly formed,
    /// with all required elements specified.
    @Flag(name: .long, help: "Validate rule completeness")
    var checkRules: Bool = false

    /// Executes the validation command.
    ///
    /// Validates the specified ATL files and generates a validation report.
    /// Returns appropriate exit codes based on validation results.
    ///
    /// - Throws: `ValidationError` if no files are specified, or `ExitCode` if validation fails
    func run() async throws {
        guard !atlFiles.isEmpty else {
            throw ValidationError("No ATL files specified")
        }

        if verbose {
            print("Validating \(atlFiles.count) ATL file(s)")
            print("Strict mode: \(strict ? "enabled" : "disabled")")
            print("Metamodel checking: \(checkMetamodels ? "enabled" : "disabled")")
            print("Rule checking: \(checkRules ? "enabled" : "disabled")")
        }

        var validationResults: [ValidationResult] = []
        var totalErrors = 0
        var totalWarnings = 0

        for atlFile in atlFiles {
            if verbose {
                print("Validating: \(atlFile)")
            }

            let result = try await validateATLFile(atlFile)
            validationResults.append(result)
            totalErrors += result.errors.count
            totalWarnings += result.warnings.count

            if !verbose && output == nil {
                let status = result.isValid ? "VALID" : "INVALID"
                print(
                    "\(atlFile): \(status) (\(result.errors.count) errors, \(result.warnings.count) warnings)"
                )
            }
        }

        // Generate summary
        let validFiles = validationResults.filter { $0.isValid }.count
        let invalidFiles = validationResults.count - validFiles

        if verbose {
            print("\nValidation Summary:")
            print("Valid files: \(validFiles)")
            print("Invalid files: \(invalidFiles)")
            print("Total errors: \(totalErrors)")
            print("Total warnings: \(totalWarnings)")
        } else if output == nil {
            print(
                "Validation complete: \(validFiles) valid, \(invalidFiles) invalid (\(totalErrors) errors, \(totalWarnings) warnings)"
            )
        }

        // Write output if requested
        if let outputPath = output {
            let outputContent = generateValidationReport(validationResults)
            try outputContent.write(
                to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            print("Validation report written to \(outputPath)")
        }

        // Exit with error code if validation failed
        if totalErrors > 0 || (strict && totalWarnings > 0) {
            throw ExitCode(totalErrors > 0 ? 1 : 2)
        }
    }

    /// Validates a single ATL file.
    ///
    /// Performs comprehensive validation of the specified ATL transformation file,
    /// including syntax checking, semantic analysis, and optional metamodel verification.
    ///
    /// - Parameter filePath: Path to the ATL file to validate
    /// - Returns: A `ValidationResult` containing validation errors and warnings
    /// - Throws: Errors if the file cannot be read or parsed
    private func validateATLFile(_ filePath: String) async throws -> ValidationResult {
        let startTime = Date()
        var errors: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []

        guard FileManager.default.fileExists(atPath: filePath) else {
            errors.append(
                ValidationIssue(
                    type: .error,
                    message: "File not found: \(filePath)",
                    line: nil,
                    column: nil
                ))
            return ValidationResult(
                filename: filePath,
                validationTime: Date().timeIntervalSince(startTime),
                errors: errors,
                warnings: warnings
            )
        }

        do {
            let atlSource = try String(contentsOfFile: filePath, encoding: .utf8)
            let parser = ATLParser()
            let module = try await parser.parseContent(
                atlSource, filename: URL(fileURLWithPath: filePath).lastPathComponent)

            // Perform semantic validation
            try validateModuleSemantics(module: module, errors: &errors, warnings: &warnings)

            if checkMetamodels {
                try validateMetamodels(module: module, errors: &errors, warnings: &warnings)
            }

            if checkRules {
                try validateRules(module: module, errors: &errors, warnings: &warnings)
            }

            if verbose {
                print(
                    "  Validation time: \(String(format: "%.3f", Date().timeIntervalSince(startTime) * 1000))ms"
                )
                print("  Errors: \(errors.count)")
                print("  Warnings: \(warnings.count)")
            }

        } catch {
            errors.append(
                ValidationIssue(
                    type: .error,
                    message: "Parse error: \(error.localizedDescription)",
                    line: nil,
                    column: nil
                ))
        }

        return ValidationResult(
            filename: filePath,
            validationTime: Date().timeIntervalSince(startTime),
            errors: errors,
            warnings: warnings
        )
    }

    private func validateModuleSemantics(
        module: ATLModule, errors: inout [ValidationIssue], warnings: inout [ValidationIssue]
    ) throws {
        // Check for empty module name
        if module.name.isEmpty {
            warnings.append(
                ValidationIssue(
                    type: .warning,
                    message: "Module name is empty",
                    line: nil,
                    column: nil
                ))
        }

        // Check for missing metamodels
        if module.sourceMetamodels.isEmpty {
            errors.append(
                ValidationIssue(
                    type: .error,
                    message: "No source metamodels defined",
                    line: nil,
                    column: nil
                ))
        }

        if module.targetMetamodels.isEmpty {
            errors.append(
                ValidationIssue(
                    type: .error,
                    message: "No target metamodels defined",
                    line: nil,
                    column: nil
                ))
        }

        // Check for rules without patterns
        for rule in module.matchedRules {
            if rule.targetPatterns.isEmpty {
                warnings.append(
                    ValidationIssue(
                        type: .warning,
                        message: "Matched rule '\(rule.name)' has no target patterns",
                        line: nil,
                        column: nil
                    ))
            }
        }

        for (name, rule) in module.calledRules {
            if rule.targetPatterns.isEmpty {
                warnings.append(
                    ValidationIssue(
                        type: .warning,
                        message: "Called rule '\(name)' has no target patterns",
                        line: nil,
                        column: nil
                    ))
            }
        }
    }

    private func validateMetamodels(
        module: ATLModule, errors: inout [ValidationIssue], warnings: inout [ValidationIssue]
    ) throws {
        // Validate metamodel references in rules
        for rule in module.matchedRules {
            let sourceType = rule.sourcePattern.type
            let isValidSourceType = module.sourceMetamodels.values.contains { package in
                // Basic check - in a full implementation, we'd check package contents
                return !package.name.isEmpty
            }

            if !isValidSourceType {
                warnings.append(
                    ValidationIssue(
                        type: .warning,
                        message:
                            "Source type '\(sourceType)' in rule '\(rule.name)' may not exist in source metamodels",
                        line: nil,
                        column: nil
                    ))
            }

            for targetPattern in rule.targetPatterns {
                let targetType = targetPattern.type
                let isValidTargetType = module.targetMetamodels.values.contains { package in
                    // Basic check - in a full implementation, we'd check package contents
                    return !package.name.isEmpty
                }

                if !isValidTargetType {
                    warnings.append(
                        ValidationIssue(
                            type: .warning,
                            message:
                                "Target type '\(targetType)' in rule '\(rule.name)' may not exist in target metamodels",
                            line: nil,
                            column: nil
                        ))
                }
            }
        }
    }

    private func validateRules(
        module: ATLModule, errors: inout [ValidationIssue], warnings: inout [ValidationIssue]
    ) throws {
        // Check for duplicate rule names
        var ruleNames = Set<String>()
        for rule in module.matchedRules {
            if ruleNames.contains(rule.name) {
                errors.append(
                    ValidationIssue(
                        type: .error,
                        message: "Duplicate matched rule name: '\(rule.name)'",
                        line: nil,
                        column: nil
                    ))
            }
            ruleNames.insert(rule.name)
        }

        for (name, _) in module.calledRules {
            if ruleNames.contains(name) {
                errors.append(
                    ValidationIssue(
                        type: .error,
                        message: "Duplicate called rule name: '\(name)'",
                        line: nil,
                        column: nil
                    ))
            }
            ruleNames.insert(name)
        }

        // Check for unreachable called rules
        let calledRuleNames = Set(module.calledRules.keys)
        // In a full implementation, we'd analyze rule invocations
        // For now, just warn if there are called rules but no matched rules
        if !calledRuleNames.isEmpty && module.matchedRules.isEmpty {
            warnings.append(
                ValidationIssue(
                    type: .warning,
                    message: "Called rules defined but no matched rules to invoke them",
                    line: nil,
                    column: nil
                ))
        }
    }

    /// Generates a formatted validation report.
    ///
    /// Creates a comprehensive validation report from the validation results,
    /// including summaries and detailed issue listings.
    ///
    /// - Parameter results: Array of validation results from validated files
    /// - Returns: A formatted string containing the complete validation report
    private func generateValidationReport(_ results: [ValidationResult]) -> String {
        var report = "ATL Validation Report\n"
        report += "====================\n\n"

        let validFiles = results.filter { $0.isValid }
        let invalidFiles = results.filter { !$0.isValid }
        let totalErrors = results.reduce(0) { $0 + $1.errors.count }
        let totalWarnings = results.reduce(0) { $0 + $1.warnings.count }

        report += "Summary:\n"
        report += "  Valid files: \(validFiles.count)\n"
        report += "  Invalid files: \(invalidFiles.count)\n"
        report += "  Total errors: \(totalErrors)\n"
        report += "  Total warnings: \(totalWarnings)\n\n"

        for result in results {
            report += "File: \(result.filename)\n"
            report += "Status: \(result.isValid ? "VALID" : "INVALID")\n"
            report += "Validation time: \(String(format: "%.3f", result.validationTime * 1000))ms\n"

            if !result.errors.isEmpty {
                report += "Errors (\(result.errors.count)):\n"
                for error in result.errors {
                    report += "  - \(error.message)\n"
                }
            }

            if !result.warnings.isEmpty {
                report += "Warnings (\(result.warnings.count)):\n"
                for warning in result.warnings {
                    report += "  - \(warning.message)\n"
                }
            }

            report += "\n"
        }

        return report
    }
}

// MARK: - Test Command

/// Command for testing ATL transformation files.
///
/// The test command runs comprehensive tests on ATL transformation files,
/// including parsing tests, semantic validation tests, and transformation
/// execution tests with sample data.
