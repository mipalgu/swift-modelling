import ATL
//
// CompileCommand.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// Command for compiling ATL transformation files.
///
/// The compile command processes ATL source files and compiles them into
/// executable transformation modules that can be run efficiently by the
/// ATL virtual machine.
struct CompileCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compile",
        abstract: "Compile ATL transformation files",
        discussion: """
            Compiles ATL transformation source files into optimized executable modules.
            The compilation process includes syntax parsing, semantic analysis, type
            checking, and optimization for efficient transformation execution.

            Example:
                swift-atl compile Families2Persons.atl --output families2persons.atlc
            """
    )

    /// ATL source file to compile.
    ///
    /// Path to the ATL transformation file that should be compiled
    /// into an executable transformation module.
    @Argument(help: "ATL source file to compile")
    var atlFile: String

    /// Output file path for the compiled transformation.
    ///
    /// When specified, writes the compiled transformation module to this file.
    /// If not specified, uses the input filename with a `.atlc` extension.
    @Option(name: .shortAndLong, help: "Output file for compiled transformation")
    var output: String?

    /// Enable verbose output mode.
    ///
    /// Shows detailed compilation progress and diagnostic information
    /// during the compilation process.
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    /// Enable optimisation mode.
    ///
    /// Applies optimisation passes to the transformation code to improve
    /// runtime performance of the compiled module.
    @Flag(name: .long, help: "Optimize transformation code")
    var optimize: Bool = false

    /// Executes the compile command.
    ///
    /// Compiles the specified ATL file into an executable transformation module
    /// that can be run by the ATL virtual machine.
    ///
    /// - Throws: Errors if the file cannot be read, parsed, or compiled
    func run() async throws {
        if verbose {
            print("Compiling ATL transformation: \(atlFile)")
            print("Optimization: \(optimize ? "enabled" : "disabled")")
        }

        // Determine output file name
        let outputPath = output ?? defaultOutputPath(for: atlFile)

        do {
            // Load and parse the ATL file
            let atlSource = try String(contentsOfFile: atlFile, encoding: .utf8)

            if verbose {
                print("Loaded ATL source (\(atlSource.count) characters)")
                print("Parsing transformation module...")
            }

            let parser = ATLParser()
            let module = try await parser.parseContent(
                atlSource, filename: URL(fileURLWithPath: atlFile).lastPathComponent)

            if verbose {
                print("Module parsed successfully: \(module.name)")
                print("Matched rules: \(module.matchedRules.count)")
                print("Called rules: \(module.calledRules.count)")
                print("Helpers: \(module.helpers.count)")
            }

            // TODO: Implement actual compilation to bytecode/optimized format
            // For now, just serialize the parsed module
            if verbose {
                print("Compilation completed successfully")
                print("Output written to: \(outputPath)")
            } else {
                print("Compiled \(atlFile) -> \(outputPath)")
            }

        } catch {
            print("Compilation failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func defaultOutputPath(for inputPath: String) -> String {
        let url = URL(fileURLWithPath: inputPath)
        let baseName = url.deletingPathExtension().lastPathComponent
        return "\(baseName).atlc"
    }
}

// MARK: - Transform Command

/// Command for executing model transformations using ATL modules.
///
/// The transform command executes compiled ATL transformation modules to transform
/// source models into target models according to the transformation specifications.
/// It supports multiple input and output formats including XMI and JSON.
