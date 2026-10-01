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

    /// The prefixes of the packages that the runtime provides, whose types need no stand-ins.
    static let runtimePrefixes = ["java.", "javax.", "org.eclipse.emf.ecore.", "org.eclipse.emf.common."]

    /// Writes stand-ins for the model types that the generated files refer to but that no template has written yet.
    ///
    /// Package and factory files refer to the interface and the implementation of every class. While those are
    /// written by other templates, the stand-ins let the generated files be compiled alone. A notice names every stand-in. The stand-ins
    /// are written below the given directory only, never to the generated output.
    ///
    /// - Parameters:
    ///   - files: The generated Java files.
    ///   - directory: The directory that receives the stand-in sources.
    /// - Returns: The stand-in sources that were written.
    static func writeStandIns(for files: [URL], in directory: URL) throws -> [URL] {
        let generated = Set(try files.map { try declaredType(of: $0) })
        var wanted: [String: Bool] = [:]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            let package = try declaredType(of: file).split(separator: ".").dropLast().joined(separator: ".")
            for match in text.matches(of: /import ([\w.]+);/) {
                let name = String(match.output.1)
                if !runtimePrefixes.contains(where: { name.hasPrefix($0) }) { wanted[name] = name.hasSuffix("Factory") }
            }
            for match in text.matches(of: /\b([a-z]\w*(?:\.[a-z]\w*)+\.[A-Z]\w*)\.class\b/) {
                let name = String(match.output.1)
                if !runtimePrefixes.contains(where: { name.hasPrefix($0) }) { wanted[name] = false }
            }
            for match in text.matches(of: /\b(\w+Factory) get\w+\(\);/) {
                wanted[package + "." + String(match.output.1)] = true
            }
            for match in text.matches(of: /\bnew (\w+Impl)\(\)/) {
                wanted[package + "." + String(match.output.1)] = false
            }
        }
        var written: [URL] = []
        for (name, isFactory) in wanted.sorted(by: { $0.key < $1.key }) where !generated.contains(name) {
            let parts = name.split(separator: ".")
            let simple = String(parts.last ?? "")
            let package = parts.dropLast().joined(separator: ".")
            let body: String
            if isFactory {
                body = "public interface \(simple) extends org.eclipse.emf.ecore.EFactory { \(simple) eINSTANCE = null; }"
            } else if simple.hasSuffix("Impl") && package.hasSuffix(".impl") {
                body =
                    "public class \(simple) extends org.eclipse.emf.ecore.impl.MinimalEObjectImpl.Container "
                    + "implements \(package.dropLast(".impl".count)).\(simple.dropLast("Impl".count)) { }"
            } else {
                body = "public interface \(simple) extends org.eclipse.emf.ecore.EObject { }"
            }
            let url = directory.appendingPathComponent(name.replacingOccurrences(of: ".", with: "/") + ".java")
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "package \(package);\n\n\(body)\n".write(to: url, atomically: true, encoding: .utf8)
            written.append(url)
        }
        if !written.isEmpty {
            print(
                "NOTE: compiling with stand-ins for types that no template writes yet: "
                    + written.map(\.lastPathComponent).joined(separator: ", "))
        }
        return written
    }

    /// The qualified name of the type that a Java file declares, taken from its package line and file name.
    ///
    /// - Parameter file: A generated Java file.
    /// - Returns: The qualified name.
    static func declaredType(of file: URL) throws -> String {
        let text = try String(contentsOf: file, encoding: .utf8)
        let package = text.firstMatch(of: /(?m)^package ([\w.]+);/).map { String($0.output.1) } ?? ""
        return package + "." + file.deletingPathExtension().lastPathComponent
    }

    @Test(
        "Generated files compile against the EMF runtime",
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
        let files = generated.generatedPaths().filter { $0.hasSuffix(".java") }.map { generated.file($0) }
        let standIns = try Self.writeStandIns(
            for: files, in: generated.project.root.appendingPathComponent("stand-ins"))
        let (status, text) = try Self.compile(files + standIns, into: classes, classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }

    @Test(
        "The extended library files compile against the EMF runtime",
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
        let files = result.files.filter { $0.pathExtension == "java" }
        let standIns = try Self.writeStandIns(for: files, in: output.appendingPathComponent("stand-ins"))
        let (status, text) = try Self.compile(files + standIns, into: classes, classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }
}
