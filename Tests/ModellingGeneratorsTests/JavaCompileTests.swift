import Foundation
import Testing

@testable import ModellingGenerators

/// Compiles generated Java against the EMF runtime.
///
/// The test runs only when the environment variable `EMF_RUNTIME_CLASSPATH` names the runtime jars
/// (`Scripts/fetch-emf-runtime.sh` prints a suitable value) and a Java compiler can be found,
/// either through `JAVAC` or as `javac` on the search path.
@Suite("Compiling generated Java")
struct JavaCompileTests {
    /// The environment variable that names the class path of the EMF runtime.
    static let classPathVariable = "EMF_RUNTIME_CLASSPATH"

    /// The environment variable that names the Java compiler.
    static let compilerVariable = "JAVAC"

    /// The language level that the compiler is asked for.
    static let release = "17"

    /// The class path of the runtime, if the environment names one.
    static let classPath: String? = ProcessInfo.processInfo.environment[classPathVariable]
        .flatMap { $0.isEmpty ? nil : $0 }

    /// The location of the Java compiler, if one can be found.
    static var compiler: URL? {
        if let path = ProcessInfo.processInfo.environment[compilerVariable], !path.isEmpty {
            return URL(fileURLWithPath: path)
        }
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
            let name = "javac.exe"
        #else
            let separator: Character = ":"
            let name = "javac"
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// Runs the compiler on Java files.
    ///
    /// - Parameters:
    ///   - files: The files to compile.
    ///   - directory: The directory that receives the class files.
    ///   - classPath: The class path of the runtime.
    /// - Returns: The exit status and the text that the compiler wrote.
    static func compile(_ files: [URL], into directory: URL, classPath: String) throws -> (Int32, String) {
        guard let compiler else { return (-1, "no Java compiler found") }
        let process = Process()
        process.executableURL = compiler
        process.arguments =
            ["-Xlint:none", "--release", release, "-encoding", "UTF-8", "-cp", classPath, "-d", directory.path]
            + files.map(\.path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    @Test(
        "Generated enumerations compile against the EMF runtime",
        .enabled(if: classPath != nil, "EMF_RUNTIME_CLASSPATH is not set; skipping the compile test"),
        .enabled(if: compiler != nil, "No javac found; skipping the compile test"),
        arguments: JavaGoldenCase.all
    )
    @MainActor
    func compiles(_ golden: JavaGoldenCase) async throws {
        let classPath = try #require(Self.classPath)
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate()

        let classes = generated.project.root.appendingPathComponent("classes")
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        let files = generated.generatedPaths().map { generated.file($0) }
        let (status, text) = try Self.compile(files, into: classes, classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }

    @Test(
        "The extended library enumeration compiles against the EMF runtime",
        .enabled(if: classPath != nil, "EMF_RUNTIME_CLASSPATH is not set; skipping the compile test"),
        .enabled(if: compiler != nil, "No javac found; skipping the compile test"),
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func compilesReferenceLibrary() async throws {
        let classPath = try #require(Self.classPath)
        let root = try #require(EMFParityTests.referenceRoot)
        let genModel = root.appendingPathComponent(EMFJavaParityTests.libraryDirectory)
            .appendingPathComponent(EMFJavaParityTests.genModelPath)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-compile")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        let result = try await GenerationPipeline.generate(
            genModelURL: genModel, language: "java", outputDirectory: output)
        let classes = output.appendingPathComponent("classes")
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        let (status, text) = try Self.compile(result.files, into: classes, classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }
}
