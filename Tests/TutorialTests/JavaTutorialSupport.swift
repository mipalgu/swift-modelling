import Foundation
import Subprocess
import Testing

#if canImport(System)
    import System
#else
    import SystemPackage
#endif

/// The model that a run of the Java tutorials works on.
///
/// The tutorials use the public extended library example of the Eclipse Modeling Framework. That model is
/// not part of this repository, so the tests that always run use the self-authored library fixture of the
/// generator tests under the same file name, and the tests that need the real model run only when the
/// environment variable `EMF_REFERENCE_ROOT` names a checkout of the framework.
struct JavaTutorialSubject: Sendable, CustomTestStringConvertible {
    /// The environment variable that names a checkout of the Eclipse Modeling Framework.
    static let referenceRootVariable = "EMF_REFERENCE_ROOT"

    /// The location of the extended library model below a checkout of the framework.
    static let referenceModelPath = "examples/org.eclipse.emf.examples.library/model/extlibrary.ecore"

    /// The file name that the tutorials give to the model in the working directory.
    static let modelFileName = "extlibrary.ecore"

    /// The name of the generator model that the tutorials create beside the model.
    static let genModelFileName = "extlibrary.genmodel"

    /// The Java package that the tutorials give to the root package of the model.
    static let basePackageDirectory = "org/eclipse/emf/examples"

    /// The text that names the subject in test reports.
    let testDescription: String

    /// The model file that is copied into the working directory.
    let source: URL

    /// The name of the root package of the model, which is also the name of its Java package.
    let packageName: String

    /// The number of classes in the model.
    let classCount: Int

    /// The number of files that generating Java for the model writes.
    let fileCount: Int

    /// The signature of a member of `BookImpl` that the tests edit by hand and mark `@generated NOT`.
    let editedSignature: String

    /// The signature of a member of `BookImpl` that the tests damage and expect to be restored.
    let damagedSignature: String

    /// The directory of the Java package of the model, relative to a source directory.
    var packageDirectory: String { "\(Self.basePackageDirectory)/\(packageName)" }

    /// The self-authored library fixture of the generator tests.
    static let fixture = JavaTutorialSubject(
        testDescription: "library fixture",
        source: repositoryRoot.appendingPathComponent(
            "Tests/ModellingGeneratorsTests/Resources/library/model/library.ecore"),
        packageName: "library", classCount: 5, fileCount: 16,
        editedSignature: "public int getPages()", damagedSignature: "public String getIsbn()")

    /// The extended library example, when a checkout of the framework is named by the environment.
    static var extendedLibrary: JavaTutorialSubject? {
        guard let root = referenceRoot else { return nil }
        return JavaTutorialSubject(
            testDescription: "extended library example",
            source: root.appendingPathComponent(referenceModelPath),
            packageName: "extlibrary", classCount: 14, fileCount: 36,
            editedSignature: "public String getTitle()", damagedSignature: "public int getPages()")
    }

    /// The subjects that the current environment can run: the fixture, and the real model if available.
    static var available: [JavaTutorialSubject] { [fixture] + (extendedLibrary.map { [$0] } ?? []) }

    /// The checkout of the Eclipse Modeling Framework that the environment names, if any.
    static var referenceRoot: URL? {
        guard let path = ProcessInfo.processInfo.environment[referenceRootVariable], !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    /// The root of this repository.
    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

/// The files that the Java tutorials show, and the means to run the commands that they show.
enum JavaTutorial {
    /// Whether the shell snippets of the tutorials can run on this platform.
    static var shellAvailable: Bool {
        #if os(Windows)
            return false
        #else
            return FileManager.default.isExecutableFile(atPath: "/bin/sh")
        #endif
    }

    /// The directory that holds the code files of the tutorials.
    static var codeRoot: URL {
        JavaTutorialSubject.repositoryRoot
            .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Resources/Code")
    }

    /// The directory that holds the tutorial files.
    static var tutorialRoot: URL {
        JavaTutorialSubject.repositoryRoot
            .appendingPathComponent("Sources/SwiftModelling/SwiftModelling.docc/Tutorials/Java-CLI")
    }

    /// The directory of the code files of one tutorial.
    ///
    /// - Parameter tutorial: The number of the tutorial.
    /// - Returns: The directory.
    static func codeDirectory(_ tutorial: Int) -> URL {
        codeRoot.appendingPathComponent("Java-Tutorial-0\(tutorial)")
    }

    /// The code file of one step of a tutorial.
    ///
    /// - Parameters:
    ///   - tutorial: The number of the tutorial.
    ///   - step: The number of the step, as it appears in the name of the file.
    /// - Returns: The location of the file.
    static func file(_ tutorial: Int, _ step: Int) throws -> URL {
        let prefix = "java-0\(tutorial)-step-" + (step < 10 ? "0\(step)" : "\(step)") + "-"
        let directory = codeDirectory(tutorial)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        let match = try #require(names.first { $0.hasPrefix(prefix) }, "no file for \(prefix)")
        return directory.appendingPathComponent(match)
    }

    /// The text of the code file of one step.
    ///
    /// - Parameters:
    ///   - tutorial: The number of the tutorial.
    ///   - step: The number of the step.
    /// - Returns: The contents of the file.
    static func text(_ tutorial: Int, _ step: Int) throws -> String {
        try String(contentsOf: file(tutorial, step), encoding: .utf8)
    }

    /// The directory that holds the executables that the tests run.
    static func toolDirectory() throws -> URL {
        URL(fileURLWithPath: try swiftEcoreExecutablePath()).deletingLastPathComponent()
    }

    /// Collapses every run of white space to one space, so that code compares independently of its layout.
    ///
    /// - Parameter text: The text to normalise.
    /// - Returns: The text with single spaces between its words.
    static func normalised(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

/// The outcome of a command that ran in a working directory.
struct JavaTutorialRun: Sendable {
    /// The exit status.
    let status: Int32

    /// The text that the command wrote on its standard output.
    let output: String

    /// The text that the command wrote on its standard error.
    let error: String

    /// Whether the command succeeded.
    var succeeded: Bool { status == 0 }
}

/// A scratch directory in which the commands of the tutorials run, as they would in the reader's directory.
struct JavaTutorialWorkspace: Sendable {
    /// The directory that the commands run in.
    let directory: URL

    /// The subject whose model was copied into the directory.
    let subject: JavaTutorialSubject

    /// Creates a directory and copies the model of the subject into it under its tutorial name.
    ///
    /// - Parameter subject: The model to work on.
    init(_ subject: JavaTutorialSubject) throws {
        self.subject = subject
        directory = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appendingPathComponent("swift-modelling-tutorial-tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: subject.source, to: directory.appendingPathComponent(JavaTutorialSubject.modelFileName))
    }

    /// Removes the directory.
    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// The location of a path in the directory.
    ///
    /// - Parameter path: The path relative to the directory.
    /// - Returns: The location.
    func url(_ path: String) -> URL { directory.appendingPathComponent(path) }

    /// Whether a file exists in the directory.
    func exists(_ path: String) -> Bool { FileManager.default.fileExists(atPath: url(path).path) }

    /// The text of a file in the directory.
    func read(_ path: String) throws -> String { try String(contentsOf: url(path), encoding: .utf8) }

    /// Writes a file in the directory.
    func write(_ text: String, to path: String) throws {
        try FileManager.default.createDirectory(
            at: url(path).deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url(path), atomically: true, encoding: .utf8)
    }

    /// The paths of the files below a directory, relative to it and sorted.
    func files(below path: String) -> [String] {
        let base = url(path).resolvingSymlinksInPath().path
        let enumerator = FileManager.default.enumerator(atPath: base)
        var found: [String] = []
        while let name = enumerator?.nextObject() as? String {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: "\(base)/\(name)", isDirectory: &isDirectory),
                !isDirectory.boolValue
            {
                found.append(name)
            }
        }
        return found.sorted()
    }

    /// Runs a shell command in the directory, with the tools of this package on the search path.
    ///
    /// - Parameter command: The text of the command, exactly as a tutorial shows it.
    /// - Returns: The outcome.
    func shell(_ command: String) async throws -> JavaTutorialRun {
        let tools = try JavaTutorial.toolDirectory().path
        let existing = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"
        let result = try await Subprocess.run(
            .path(FilePath("/bin/sh")),
            arguments: Arguments(["-c", command]),
            environment: .inherit.updating(["PATH": "\(tools):\(existing)"]),
            workingDirectory: FilePath(directory.path),
            output: .string(limit: 1_048_576),
            error: .string(limit: 1_048_576))
        let status: Int32
        if case .exited(let code) = result.terminationStatus { status = Int32(code) } else { status = -1 }
        return JavaTutorialRun(
            status: status, output: result.standardOutput ?? "", error: result.standardError ?? "")
    }

    /// Runs the code file of a tutorial step as a shell command.
    ///
    /// - Parameters:
    ///   - tutorial: The number of the tutorial.
    ///   - step: The number of the step.
    /// - Returns: The outcome.
    func run(_ tutorial: Int, _ step: Int) async throws -> JavaTutorialRun {
        try await shell(JavaTutorial.text(tutorial, step))
    }

    /// Runs the code file of a tutorial step and requires it to succeed.
    ///
    /// - Parameters:
    ///   - tutorial: The number of the tutorial.
    ///   - step: The number of the step.
    /// - Returns: The outcome.
    @discardableResult
    func require(_ tutorial: Int, _ step: Int) async throws -> JavaTutorialRun {
        let result = try await run(tutorial, step)
        #expect(result.succeeded, "tutorial \(tutorial) step \(step) failed: \(result.error)")
        return result
    }
}
