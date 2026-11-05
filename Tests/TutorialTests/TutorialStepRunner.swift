//
// TutorialStepRunner.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Subprocess

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// Why the harness cannot replay the tutorials in the current environment.
enum TutorialReplayError: Error, CustomStringConvertible {
    /// No shell of ``TutorialReplayConfiguration/shellCandidates`` exists.
    case shellNotFound

    /// The platform cannot run the shell scripts of the tutorials.
    case unsupportedPlatform

    /// A description of the error for test reports.
    var description: String {
        switch self {
        case .shellNotFound:
            return "No shell found at \(TutorialReplayConfiguration.shellCandidates.joined(separator: " or "))"
        case .unsupportedPlatform:
            return "\(TutorialReplayConfiguration.windowsReason)"
        }
    }
}

/// The outcome of running one Terminal script.
struct ScriptRun: Sendable {
    /// The exit status of the shell, or `nil` if it ended by a signal.
    let exitStatus: Int32?

    /// A description of how the shell ended, such as `exited with status 64`.
    let termination: String

    /// Whether the script ran longer than ``TutorialReplayConfiguration/stepTimeout`` and was stopped.
    let timedOut: Bool

    /// The combined standard output and standard error of the script, as far as it was kept.
    let output: String

    /// Whether the script finished with exit status 0.
    var succeeded: Bool { exitStatus == 0 && !timedOut }
}

/// The environment in which the Terminal scripts of the tutorials run.
///
/// The search path starts with a directory of wrappers: for every tool of
/// ``TutorialReplayConfiguration/toolNames`` that this build produces, a wrapper runs the
/// executable of this build and records the invocation, and for every other tool a stand-in
/// reports the tool as missing and exits with status 127, as the shell does for an unknown command.
/// A wrapper copies the standard error of the tool into the log directory named by
/// ``TutorialReplayConfiguration/toolLogVariable`` before passing it on, so that a failure stays
/// visible even when a script sends the standard error elsewhere. The build products directory,
/// the directories of the base system and the remaining directories of the search path of the
/// test process follow. An installed release of a tool, for example from a package manager, can
/// therefore neither shadow nor stand in for the tools of this build, while other commands that a
/// tutorial uses, such as `java`, `jq` or `dot`, stay available.
struct TutorialReplayEnvironment: Sendable {
    /// The shell that runs the scripts.
    let shell: String

    /// The directory that holds the executables of this build.
    let productsDirectory: URL

    /// The directory that holds the wrappers and stand-ins of the tools.
    let toolsDirectory: URL

    /// The search path for the scripts.
    let searchPath: String

    /// The environment shared by the tests of this target, prepared once.
    static let shared = Result { try TutorialReplayEnvironment() }

    /// Finds the shell and the build products, writes the wrappers and composes the search path.
    ///
    /// - Throws: ``TutorialReplayError`` if no shell exists, ``TestError`` if the build products
    ///   cannot be found, or an error if the wrappers cannot be written.
    init() throws {
        guard TutorialReplayConfiguration.canReplayShellScripts else { throw TutorialReplayError.unsupportedPlatform }
        guard
            let shell = TutorialReplayConfiguration.shellCandidates.first(where: {
                FileManager.default.isExecutableFile(atPath: $0)
            })
        else { throw TutorialReplayError.shellNotFound }
        self.shell = shell
        productsDirectory = URL(fileURLWithPath: try swiftEcoreExecutablePath()).deletingLastPathComponent()
        toolsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(TutorialReplayConfiguration.workingDirectoryName)
            .appendingPathComponent(TutorialReplayConfiguration.toolsDirectoryName + "-" + UUID().uuidString)
        try Self.writeWrappers(in: toolsDirectory, products: productsDirectory, shell: shell)
        let inherited = (ProcessInfo.processInfo.environment[TutorialReplayConfiguration.searchPathVariable] ?? "")
            .split(separator: TutorialReplayConfiguration.searchPathSeparator).map(String.init)
        searchPath = Self.searchPath(tools: toolsDirectory.path, products: productsDirectory.path, inherited: inherited)
    }

    /// Writes a wrapper for every tool that the products directory holds and a stand-in for every other tool.
    ///
    /// - Parameters:
    ///   - directory: The directory to write the wrappers into, created if needed.
    ///   - products: The directory that holds the executables of this build.
    ///   - shell: The shell that runs the wrappers.
    /// - Throws: An error if a wrapper cannot be written.
    static func writeWrappers(in directory: URL, products: URL, shell: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for tool in TutorialReplayConfiguration.toolNames {
            let executable = products.appendingPathComponent(tool).path
            let exists = FileManager.default.isExecutableFile(atPath: executable)
            let wrapper = directory.appendingPathComponent(tool)
            try wrapperScript(for: tool, executable: exists ? executable : nil, shell: shell)
                .write(to: wrapper, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: wrapper.path)
        }
    }

    /// The text of the wrapper of a tool, or of the stand-in for a tool that this build does not produce.
    ///
    /// When the log variable names an existing directory, the wrapper creates a start file there
    /// named after the tool, copies the standard error of the tool into a companion file with the
    /// extension ``TutorialReplayConfiguration/toolLogStandardErrorExtension`` while passing it on,
    /// and finally writes the exit status and the arguments into a companion file with the
    /// extension ``TutorialReplayConfiguration/toolLogStatusExtension``. Standard input and standard
    /// output pass through unchanged, and the wrapper exits with the status of the tool. A stand-in
    /// records and reports ``TutorialReplayConfiguration/missingToolMessage`` and exits with
    /// ``TutorialReplayConfiguration/missingToolStatus``.
    ///
    /// - Parameters:
    ///   - tool: The name of the tool.
    ///   - executable: The executable of this build, or `nil` if this build does not produce the tool.
    ///   - shell: The shell that runs the wrapper.
    /// - Returns: The text of a shell script.
    static func wrapperScript(for tool: String, executable: String?, shell: String) -> String {
        let log = TutorialReplayConfiguration.toolLogVariable
        let errorFile = "\"$record.\(TutorialReplayConfiguration.toolLogStandardErrorExtension)\""
        let statusFile = "\"$record.\(TutorialReplayConfiguration.toolLogStatusExtension)\""
        let header = """
            #!\(shell)
            log_directory="${\(log):-}"
            record=""
            if [ -n "$log_directory" ] && [ -d "$log_directory" ]; then
                record="$(mktemp "$log_directory/\(tool).XXXXXX" 2>/dev/null)" || record=""
            fi

            """
        guard let executable else {
            let message = quoted("\(tool): \(TutorialReplayConfiguration.missingToolMessage)")
            let status = TutorialReplayConfiguration.missingToolStatus
            return header + """
                if [ -n "$record" ]; then
                    printf '%s\\n' \(message) > \(errorFile)
                    { printf '%s\\n' \(status); printf '%s ' "$@"; printf '\\n'; } > \(statusFile)
                fi
                printf '%s\\n' \(message) >&2
                exit \(status)

                """
        }
        let real = quoted(executable)
        return header + """
            if [ -z "$record" ]; then exec \(real) "$@"; fi
            { \(real) "$@" 2>&1 1>&3 3>&- | tee \(errorFile) >&2; status=${PIPESTATUS[0]}; } 3>&1
            { printf '%s\\n' "$status"; printf '%s ' "$@"; printf '\\n'; } > \(statusFile)
            exit "$status"

            """
    }

    /// Quotes a text for the shell.
    ///
    /// - Parameter text: The text to quote.
    /// - Returns: The text in single quotes, with every single quote escaped.
    static func quoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Composes the search path of the scripts.
    ///
    /// - Parameters:
    ///   - tools: The directory of the wrappers and stand-ins of the tools.
    ///   - products: The build products directory.
    ///   - inherited: The directories of the search path of the test process.
    /// - Returns: The wrappers, the products directory, the directories of the base system and the
    ///   inherited directories, each once.
    static func searchPath(tools: String, products: String, inherited: [String]) -> String {
        var directories = [tools, products] + TutorialReplayConfiguration.systemSearchPath
        for directory in inherited where !directory.isEmpty && !directories.contains(directory) {
            directories.append(directory)
        }
        return directories.joined(separator: String(TutorialReplayConfiguration.searchPathSeparator))
    }

    /// Runs a script with the shell in a working directory, stopping it after a time limit.
    ///
    /// The shell runs in a process group of its own, so that stopping it after
    /// ``TutorialReplayConfiguration/stepTimeout`` also stops the commands it started. Standard
    /// input is empty.
    ///
    /// - Parameters:
    ///   - script: The script to run.
    ///   - directory: The working directory.
    ///   - toolLog: The directory in which the wrappers record the tool invocations of the run.
    ///   - timeout: How long the script may run.
    /// - Returns: The outcome of the run.
    /// - Throws: An error if the shell cannot be started.
    func run(
        script: URL, in directory: URL, toolLog: URL,
        timeout: Duration = TutorialReplayConfiguration.stepTimeout
    ) async throws -> ScriptRun {
        #if os(Windows)
            throw TutorialReplayError.unsupportedPlatform
        #else
            var options = PlatformOptions()
            options.processGroupID = 0
            let environment = Environment.inherit.updating([
                Environment.Key(stringLiteral: TutorialReplayConfiguration.searchPathVariable): searchPath,
                Environment.Key(stringLiteral: TutorialReplayConfiguration.toolLogVariable): toolLog.path,
            ])
            let result = try await withProcessSlot {
                try await Subprocess.run(
                    .path(FilePath(shell)),
                    arguments: Arguments(TutorialReplayConfiguration.shellOptions + [script.path]),
                    environment: environment,
                    workingDirectory: FilePath(directory.path),
                    platformOptions: options,
                    input: .none,
                    output: .sequence,
                    error: .combinedWithOutput
                ) { execution in
                    try await Self.collect(execution, timeout: timeout)
                }
            }
            let (output, timedOut) = result.closureOutput
            switch result.terminationStatus {
            case .exited(let code):
                return ScriptRun(
                    exitStatus: Int32(code), termination: "exited with status \(code)", timedOut: timedOut,
                    output: output)
            case .signaled(let signal):
                return ScriptRun(
                    exitStatus: nil, termination: "ended by signal \(signal)", timedOut: timedOut, output: output)
            }
        #endif
    }

    #if !os(Windows)
        /// Collects the output of a running script, stopping its process group after a time limit.
        ///
        /// - Parameters:
        ///   - execution: The running script, with standard error merged into standard output.
        ///   - timeout: How long the script may run.
        /// - Returns: The output, and whether the script was stopped.
        /// - Throws: An error if the output cannot be read.
        private static func collect(
            _ execution: Execution<NoInput, SequenceOutput, CombinedErrorOutput>, timeout: Duration
        ) async throws -> (String, Bool) {
            enum Event: Sendable {
                case collected(String)
                case elapsed
            }
            let output = execution.standardOutput
            return try await withThrowingTaskGroup(of: Event.self) { group in
                group.addTask { .collected(try await read(output)) }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    return .elapsed
                }
                if case .collected(let text)? = try await group.next() {
                    group.cancelAll()
                    return (text, false)
                }
                try? execution.send(signal: .kill, toProcessGroup: true)
                group.addTask {
                    try await Task.sleep(for: TutorialReplayConfiguration.terminationGracePeriod)
                    return .elapsed
                }
                let remainder = try await group.next()
                group.cancelAll()
                if case .collected(let text)? = remainder { return (text, true) }
                return ("", true)
            }
        }
    #endif

    /// Reads an output sequence to its end, keeping at most ``TutorialReplayConfiguration/outputByteLimit`` bytes.
    ///
    /// - Parameter output: The output of a running process.
    /// - Returns: The kept output, decoded as UTF-8.
    /// - Throws: An error if the output cannot be read.
    private static func read(_ output: SubprocessOutputSequence) async throws -> String {
        var bytes: [UInt8] = []
        for try await buffer in output {
            let room = TutorialReplayConfiguration.outputByteLimit - bytes.count
            guard room > 0 else { continue }
            buffer.withUnsafeBytes { bytes.append(contentsOf: $0.prefix(room)) }
        }
        return String(decoding: bytes, as: UTF8.self)
    }
}
