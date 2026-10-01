import Foundation
import Testing

@testable import ModellingGenerators

/// Compiles the generated interfaces and implementation classes against the EMF runtime.
///
/// The classes refer to the package interface of their model, which another template writes. These tests
/// give the compiler a stand-in package interface in the temporary output directory only, with just the
/// constants that the generated classes name, so that the classes compile on their own. The tests run
/// only when `EMF_RUNTIME_CLASSPATH` names the runtime jars and a Java compiler can be found.
@Suite("Compiling generated classes")
struct JavaClassCompileTests {
    /// The names of the package interfaces that generated sources import, with their packages.
    ///
    /// - Parameter sources: The text of the generated sources.
    /// - Returns: The qualified names of the package interfaces.
    static func packageInterfaces(in sources: [String]) -> Set<String> {
        var result = Set<String>()
        let pattern = #"import ([A-Za-z0-9_.]+\.[A-Za-z0-9_]+Package);"#
        for source in sources {
            for match in source.matches(of: try! Regex(pattern)) {
                if let name = match.output[1].substring { result.insert(String(name)) }
            }
        }
        return result
    }

    /// Writes a stand-in for a package interface with the constants that the sources use.
    ///
    /// - Parameters:
    ///   - qualifiedName: The qualified name of the package interface.
    ///   - sources: The text of the generated sources.
    ///   - directory: The directory that receives the file.
    /// - Returns: The location of the written file.
    static func writeStandIn(_ qualifiedName: String, sources: [String], into directory: URL) throws -> URL {
        let simpleName = String(qualifiedName.split(separator: ".").last ?? "")
        let packageName = qualifiedName.split(separator: ".").dropLast().joined(separator: ".")
        var constants = Set<String>()
        var literals = Set<String>()
        for source in sources {
            for match in source.matches(of: try! Regex("\(simpleName)\\.Literals\\.([A-Z0-9_]+)")) {
                if let name = match.output[1].substring { literals.insert(String(name)) }
            }
            for match in source.matches(of: try! Regex("\(simpleName)\\.([A-Z][A-Z0-9_]+)")) {
                if let name = match.output[1].substring, name != "Literals" { constants.insert(String(name)) }
            }
        }
        var text = "package \(packageName);\n\npublic interface \(simpleName)\n{\n"
        for (index, name) in constants.sorted().enumerated() { text += "  int \(name) = \(index);\n" }
        text += "  interface Literals\n  {\n"
        for name in literals.sorted() {
            let type = name.contains("__") ? "org.eclipse.emf.ecore.EStructuralFeature" : "org.eclipse.emf.ecore.EClass"
            text += "    \(type) \(name) = null;\n"
        }
        text += "  }\n}\n"
        let folder = directory.appendingPathComponent(packageName.replacingOccurrences(of: ".", with: "/"))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("\(simpleName).java")
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    /// Compiles files together with stand-ins for the package interfaces that they import.
    ///
    /// - Parameters:
    ///   - files: The generated sources.
    ///   - scratch: A temporary directory for the stand-ins and the class files.
    ///   - classPath: The class path of the runtime.
    /// - Returns: The exit status of the compiler and its output.
    static func compileWithStandIns(_ files: [URL], scratch: URL, classPath: String) throws -> (Int32, String) {
        let sources = try files.map { try String(contentsOf: $0, encoding: .utf8) }
        let standIns = scratch.appendingPathComponent("standins")
        var all = files
        for name in packageInterfaces(in: sources) {
            all.append(try writeStandIn(name, sources: sources, into: standIns))
        }
        let classes = scratch.appendingPathComponent("classes")
        try FileManager.default.createDirectory(at: classes, withIntermediateDirectories: true)
        return try JavaCompileTests.compile(all, into: classes, classPath: classPath)
    }

    @Test(
        "Generated classes compile against the EMF runtime",
        .enabled(
            if: JavaCompileTests.classPath != nil, "EMF_RUNTIME_CLASSPATH is not set; skipping the compile test"),
        .enabled(if: JavaCompileTests.compiler != nil, "No javac found; skipping the compile test"),
        arguments: JavaGoldenCase.all
    )
    @MainActor
    func compiles(_ golden: JavaGoldenCase) async throws {
        let classPath = try #require(JavaCompileTests.classPath)
        let generated = try await GeneratedProject.make(
            golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate()
        let files = generated.generatedPaths().filter { $0.hasSuffix(".java") }.map { generated.file($0) }
        let (status, text) = try Self.compileWithStandIns(
            files, scratch: generated.project.root.appendingPathComponent("class-compile"), classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }

    @Test(
        "The generated classes of the reference library example compile",
        .enabled(
            if: JavaCompileTests.classPath != nil, "EMF_RUNTIME_CLASSPATH is not set; skipping the compile test"),
        .enabled(if: JavaCompileTests.compiler != nil, "No javac found; skipping the compile test"),
        .enabled(
            if: EMFParityTests.referenceRoot != nil, "EMF_REFERENCE_ROOT is not set; skipping Eclipse parity")
    )
    @MainActor
    func compilesReferenceLibrary() async throws {
        let classPath = try #require(JavaCompileTests.classPath)
        let root = try #require(EMFParityTests.referenceRoot)
        let genModel = root.appendingPathComponent(EMFJavaParityTests.libraryDirectory)
            .appendingPathComponent(EMFJavaParityTests.genModelPath)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-java-class-compile")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: output) }
        let result = try await GenerationPipeline.generate(
            genModelURL: genModel, language: "java", outputDirectory: output)
        let (status, text) = try Self.compileWithStandIns(
            result.files, scratch: output.appendingPathComponent("class-compile"), classPath: classPath)
        #expect(status == 0, "javac failed:\n\(text)")
    }
}
