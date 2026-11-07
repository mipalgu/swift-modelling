//
// VerificationTools.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Finds and runs the external tools that check the exports.
///
/// The tools are optional: each is named by an environment variable, and the checks that need a
/// tool are skipped when its variable is not set.
///
/// | Variable | Tool |
/// | --- | --- |
/// | `ALLOY_JAR` | the Alloy 6 distribution jar, run headless with its `exec` command |
/// | `TLA2TOOLS_JAR` | the TLA+ tools jar, providing SANY and TLC |
/// | `LEAN` | the `lean` executable of a Lean 4 toolchain |
/// | `EVENTB_AST_JAR` | the Rodin Event-B formula library `org.eventb.core.ast` |
/// | `JAVA` | the Java executable, `java` on the search path by default |
enum VerificationTools {
    /// The environment variable that names the Alloy jar.
    static let alloyJar = "ALLOY_JAR"
    /// The environment variable that names the TLA+ tools jar.
    static let tlaToolsJar = "TLA2TOOLS_JAR"
    /// The environment variable that names the Lean executable.
    static let lean = "LEAN"
    /// The environment variable that names the Event-B formula library jar.
    static let eventBJar = "EVENTB_AST_JAR"
    /// The environment variable that names the Java executable.
    static let java = "JAVA"

    /// The longest time a tool may run before it is stopped.
    static let timeout: TimeInterval = 900

    /// The value of an environment variable that names an existing file.
    ///
    /// - Parameter name: The name of the variable.
    /// - Returns: The path, or `nil` if the variable is unset or the file does not exist.
    static func path(_ name: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[name], !value.isEmpty,
            FileManager.default.fileExists(atPath: value)
        else { return nil }
        return value
    }

    /// Whether a tool is available.
    ///
    /// - Parameter name: The environment variable that names the tool.
    /// - Returns: `true` if the variable names an existing file.
    static func isAvailable(_ name: String) -> Bool { path(name) != nil }

    /// The arguments that start the Java virtual machine without a graphical user interface.
    static var javaPrefix: [String] {
        [ProcessInfo.processInfo.environment[java] ?? "java", "-Djava.awt.headless=true"]
    }

    /// Creates an empty scratch directory for a check.
    ///
    /// The directory is left in the temporary directory after the check, for inspection.
    ///
    /// - Parameter name: A name that identifies the check.
    /// - Returns: The new directory.
    static func scratchDirectory(_ name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("verification-\(name)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Writes exported files into a directory.
    ///
    /// - Parameters:
    ///   - files: The text of each file by relative path.
    ///   - directory: The directory.
    static func write(_ files: [String: String], to directory: URL) throws {
        for (path, text) in files {
            let url = directory.appendingPathComponent((path as NSString).lastPathComponent)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// Runs a tool and collects its output.
    ///
    /// The tool is stopped, by its process identifier, if it runs longer than ``timeout``.
    ///
    /// - Parameters:
    ///   - arguments: The executable, by path or name on the search path, and its arguments.
    ///   - directory: The working directory.
    ///   - environment: Further environment variables.
    /// - Returns: The exit status and the combined standard output and error.
    static func run(_ arguments: [String], in directory: URL, environment: [String: String] = [:]) throws
        -> (status: Int32, output: String)
    {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        let output = directory.appendingPathComponent("tool-output-\(UUID().uuidString).txt")
        FileManager.default.createFile(atPath: output.path, contents: nil)
        let handle = try FileHandle(forWritingTo: output)
        defer { try? handle.close() }
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if process.isRunning {
            kill(process.processIdentifier, SIGTERM)
            process.waitUntilExit()
        }
        let text = (try? String(contentsOf: output, encoding: .utf8)) ?? ""
        return (process.terminationStatus, text)
    }
}
