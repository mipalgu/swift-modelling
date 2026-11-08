//
// ImportErrorTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Grammar and signature texts with a syntax error, which their readers report as errors.
private enum BrokenImports {
    /// An ASDL module with a constructor whose fields lack their closing parenthesis.
    static let asdl = (name: "Arith.asdl", text: "module Arith {\n  expr = Num(int n | Add(expr l, expr r)\n}\n")

    /// A Langium grammar whose rule is not terminated and uses an undefined rule.
    static let langium = (name: "Arith.langium", text: "grammar Arith\nentry Model: value=ID\n")

    /// An SDF3 grammar whose template is not closed.
    static let sdf3 = (name: "Arith.sdf3", text: "module Arith\ncontext-free syntax\n  Exp.Add = <<Exp> + ")

    /// Every broken text.
    static let all = [asdl, langium, sdf3]
}

/// A Stratego signature that refers to lexical sorts it does not define, which is only a warning.
private let signature = """
    module signatures/Arith-sig

    signature
      sorts Exp
      constructors
        Num : INT -> Exp
        Var : ID -> Exp
        Add : Exp * Exp -> Exp

    """

/// Writes a file into a new temporary directory.
///
/// - Parameters:
///   - name: The name of the file.
///   - text: The contents of the file.
/// - Returns: The directory and the file.
private func write(_ name: String, _ text: String) throws -> (directory: URL, file: URL) {
    let directory = try createTemporaryDirectory()
    let file = directory.appendingPathComponent(name)
    try text.write(to: file, atomically: true, encoding: .utf8)
    return (directory, file)
}

@Suite("swift-ecore - Import errors")
struct ImportErrorTests {
    @Test("inspect, validate, statistics and query fail on a grammar that cannot be read", arguments: BrokenImports.all)
    @MainActor
    func readingCommandsFail(_ broken: (name: String, text: String)) async throws {
        let (directory, file) = try write(broken.name, broken.text)
        defer { cleanupTemporaryDirectory(directory) }
        let commands: [(String, [String])] = [
            ("inspect", [file.path]), ("validate", [file.path]), ("statistics", [file.path]),
            ("query", [file.path, "--query", "classes"]), ("compare", [file.path, file.path]),
        ]
        for (command, arguments) in commands {
            let result = try await executeSwiftEcore(command: command, arguments: arguments)

            #expect(result.exitCode == 1, "\(command): \(result.stdout)\(result.stderr)")
            #expect(result.stderr.hasPrefix("error: \(file.path): line "), "\(command): \(result.stderr)")
            #expect(result.stderr.contains("Error: Failed to read \(file.path): "), "\(command): \(result.stderr)")
            #expect(!result.stdout.contains("Validation completed successfully"), "\(command): \(result.stdout)")
        }
    }

    @Test("convert fails on a grammar that cannot be read and writes nothing", arguments: BrokenImports.all)
    @MainActor
    func convertFails(_ broken: (name: String, text: String)) async throws {
        let (directory, file) = try write(broken.name, broken.text)
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("Arith.ecore")

        let result = try await executeSwiftEcore(command: "convert", arguments: [file.path, output.path])

        #expect(result.exitCode == 1, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.hasPrefix("error: \(file.path): line "), "\(result.stderr)")
        #expect(result.stderr.contains("Error: Failed to read \(file.path): "), "\(result.stderr)")
        #expect(!result.stdout.contains("Conversion completed"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("a file that cannot be read counts as invalid among several")
    @MainActor
    func batchValidation() async throws {
        let (directory, file) = try write(BrokenImports.asdl.name, BrokenImports.asdl.text)
        defer { cleanupTemporaryDirectory(directory) }
        let valid = directory.appendingPathComponent("Arith-sig.str")
        try signature.write(to: valid, atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(command: "validate", arguments: [file.path, valid.path])

        #expect(result.exitCode == 1, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("error: Failed to read \(file.path): 1 error(s)\n"), "\(result.stdout)")
        #expect(result.stdout.contains("\(file.path): invalid (1 error(s), 0 warning(s))"), "\(result.stdout)")
        #expect(result.stdout.contains("\(valid.path): valid"), "\(result.stdout)")
    }

    @Test("warnings of a reader do not change the exit status")
    @MainActor
    func warningsStayWarnings() async throws {
        let (directory, file) = try write("Arith-sig.str", signature)
        defer { cleanupTemporaryDirectory(directory) }

        let inspect = try await executeSwiftEcore(command: "inspect", arguments: [file.path])
        let validate = try await executeSwiftEcore(command: "validate", arguments: [file.path])

        #expect(inspect.succeeded, "\(inspect.stdout)\(inspect.stderr)")
        #expect(inspect.stderr.contains("warning: \(file.path): line "), "\(inspect.stderr)")
        #expect(!inspect.stderr.contains("error: "))
        #expect(validate.succeeded, "\(validate.stdout)\(validate.stderr)")
        #expect(validate.stdout.hasSuffix("Validation completed successfully\n"))
    }

    @Test("convert recognises a Stratego signature by its contents")
    @MainActor
    func convertRecognisesSignature() async throws {
        let (directory, file) = try write("Arith-sig.str", signature)
        defer { cleanupTemporaryDirectory(directory) }
        let output = directory.appendingPathComponent("Arith.ecore")

        let result = try await executeSwiftEcore(command: "convert", arguments: [file.path, output.path])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout == "Conversion completed: \(output.path)\n")
        let ecore = try String(contentsOf: output, encoding: .utf8)
        #expect(ecore.contains(#"name="Add""#))
        let unknown = directory.appendingPathComponent("notes.txt")
        try "plain text".write(to: unknown, atomically: true, encoding: .utf8)
        let rejected = try await executeSwiftEcore(
            command: "convert", arguments: [unknown.path, directory.appendingPathComponent("notes.ecore").path])
        #expect(rejected.exitCode == 1)
        #expect(rejected.stderr.contains("Error: Unsupported input format: txt"), "\(rejected.stderr)")
    }

    @Test("the help of --sdf3-labels says that the labels name features")
    @MainActor
    func sdf3LabelsHelp() async throws {
        let result = try await executeSwiftEcore(command: "convert", arguments: ["--help"])

        let help = result.stdout.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        #expect(help.contains("--sdf3-labels/--no-sdf3-labels Whether the labels of an SDF3 grammar name the features"), "\(help)")
        #expect(!help.contains("name the classes of the metamodel"))
    }
}
