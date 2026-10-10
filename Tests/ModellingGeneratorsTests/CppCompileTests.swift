import Foundation
import Testing

@testable import ModellingGenerators

/// Compiles generated C++ with the compiler of the system.
///
/// Every header of a fixture is compiled on its own, as the only content of a translation unit, with the strict
/// warnings of the language turned into errors. A translation unit that includes all headers of a fixture and uses
/// its factories and package descriptions is linked with a second one that includes the same headers, to show that
/// the header-only code defines no symbol twice. The library fixture also has a program that exercises the generated
/// classes; it runs plainly and under the address and undefined behaviour sanitizers.
///
/// The tests run only when a compiler named `c++` can be found on the search path. Everything is written below the
/// temporary directory.
@Suite("Compiling generated C++", .serialized)
struct CppCompileTests {
    /// The warnings and the language version that all code must compile with.
    static let strictFlags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", "-pedantic"]

    /// The flags that turn on the sanitizers.
    static let sanitizerFlags = ["-fsanitize=address,undefined", "-g"]

    /// The folder of the fixture that holds the check program, below the fixture.
    static let checkFolder = "cpp-check"

    /// The files of the check program: the main program and a second translation unit.
    static let checkFiles = ["Check.cpp", "Other.cpp"]

    /// The text that the check program writes when it succeeds.
    static let successText = "checks passed"

    /// The location of the C++ compiler, if one can be found on the search path.
    static let compiler: URL? = {
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
            let name = "c++.exe"
        #else
            let separator: Character = ":"
            let name = "c++"
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }()

    /// Whether the compiler can build programs with the sanitizers.
    static let sanitizersWork: Bool = {
        guard let compiler, let scratch = try? scratchDirectory() else { return false }
        defer { try? FileManager.default.removeItem(at: scratch) }
        do {
            try "int main() { return 0; }\n".write(
                to: scratch.appendingPathComponent("probe.cpp"), atomically: true, encoding: .utf8)
            return try run(compiler, sanitizerFlags + ["probe.cpp", "-o", "probe"], in: scratch).status == 0
        } catch {
            return false
        }
    }()

    /// Runs a program and collects its output.
    ///
    /// - Parameters:
    ///   - executable: The program to run.
    ///   - arguments: The arguments of the program.
    ///   - directory: The directory to run in.
    /// - Returns: The exit status and the text that the program wrote.
    static func run(_ executable: URL, _ arguments: [String], in directory: URL) throws -> (
        status: Int32, output: String
    ) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// Creates an empty directory below the temporary directory.
    ///
    /// - Returns: The directory; the caller removes it.
    static func scratchDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-cpp-compile")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// The headers a generation wrote, relative to the output directory.
    static func headers(of generated: GeneratedProject) -> [String] {
        generated.generatedPaths().filter { $0.hasSuffix(".hpp") }
    }

    /// Writes one translation unit for each header, which does nothing but include it.
    ///
    /// - Parameters:
    ///   - headers: The headers to include.
    ///   - directory: The directory to write to.
    /// - Returns: The file names of the translation units.
    static func writeUnits(for headers: [String], to directory: URL) throws -> [String] {
        var names: [String] = []
        for (index, header) in headers.enumerated() {
            let name = "unit\(index).cpp"
            try "#include \"\(header)\"\n".write(
                to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
            names.append(name)
        }
        return names
    }

    /// The statements that use the factory and the package description of every package of a generation.
    ///
    /// - Parameter generated: The generated project.
    /// - Returns: The statements, one for each package.
    static func packageStatements(of generated: GeneratedProject) throws -> [String] {
        var statements: [String] = []
        for path in generated.generatedPaths() where path.hasSuffix("Factory.hpp") {
            let lines = try generated.text(path).components(separatedBy: "\n")
            let namespaceLine = try #require(lines.first { $0.hasPrefix("namespace ") && $0.hasSuffix(" {") })
            let classLine = try #require(lines.first { $0.hasPrefix("class ") && $0.hasSuffix("Factory final {") })
            let namespace = String(namespaceLine.dropFirst("namespace ".count).dropLast(" {".count))
            let factory = String(classLine.dropFirst("class ".count).dropLast(" final {".count))
            let package = String(factory.dropLast("Factory".count)) + "Package"
            statements.append(
                "    if (\(namespace)::\(factory)::instance().create(\"\") != nullptr) return 1;\n"
                    + "    if (\(namespace)::\(package)::instance().info().name.empty()) return 2;\n")
        }
        return statements
    }

    /// Compiles every header on its own, then links a program that includes them all with a second unit.
    ///
    /// - Parameters:
    ///   - generated: The generated project.
    ///   - name: What the project is called in failure reports.
    ///   - flags: More flags for both steps.
    static func compileAndLink(_ generated: GeneratedProject, name: String, flags: [String] = []) throws {
        let compiler = try #require(Self.compiler)
        let scratch = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: scratch) }
        let headers = headers(of: generated)
        #expect(!headers.isEmpty)

        let units = try writeUnits(for: headers, to: scratch)
        let syntax = try run(
            compiler, strictFlags + flags + ["-fsyntax-only", "-I", generated.output.path] + units, in: scratch)
        #expect(syntax.status == 0, "\(name): a header does not compile on its own:\n\(syntax.output.prefix(4000))")

        let includes = headers.map { "#include \"\($0)\"\n" }.joined()
        let main =
            includes + "#include <iostream>\n\nint second();\n\nint main() {\n"
            + (try packageStatements(of: generated)).joined()
            + "    std::cout << \"ok \" << second() << \"\\n\";\n    return 0;\n}\n"
        try main.write(to: scratch.appendingPathComponent("main.cpp"), atomically: true, encoding: .utf8)
        try (includes + "\nint second() { return 2; }\n").write(
            to: scratch.appendingPathComponent("second.cpp"), atomically: true, encoding: .utf8)
        let build = try run(
            compiler,
            strictFlags + flags + ["-I", generated.output.path, "main.cpp", "second.cpp", "-o", "program"],
            in: scratch)
        #expect(build.status == 0, "\(name): two units do not link:\n\(build.output.prefix(4000))")
        guard build.status == 0 else { return }
        let program = try run(scratch.appendingPathComponent("program"), [], in: scratch)
        #expect(program.status == 0 && program.output.contains("ok 2"), "\(name): the program failed:\n\(program.output)")
    }

    /// Builds the check program of the library fixture against its generated headers and runs it.
    ///
    /// - Parameters:
    ///   - generated: The generated library project.
    ///   - flags: More flags for the build.
    static func buildAndRunCheck(_ generated: GeneratedProject, flags: [String] = []) throws {
        let compiler = try #require(Self.compiler)
        let scratch = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: scratch) }
        for file in checkFiles {
            try FileManager.default.copyItem(
                at: try Fixtures.url(of: "library/\(checkFolder)/\(file)"), to: scratch.appendingPathComponent(file))
        }
        let build = try run(
            compiler, strictFlags + flags + ["-I", generated.output.path] + checkFiles + ["-o", "check"], in: scratch)
        #expect(build.status == 0, "the check program does not build:\n\(build.output.prefix(4000))")
        guard build.status == 0 else { return }
        let check = try run(scratch.appendingPathComponent("check"), [], in: scratch)
        #expect(check.status == 0, "the check of the generated model failed:\n\(check.output.prefix(4000))")
        #expect(check.output.contains(successText))
    }

    @Test(
        "Every header compiles on its own, and two units that include them all link",
        .enabled(if: compiler != nil, "No c++ found on the search path; skipping the compile test"),
        arguments: CppGoldenCase.all
    )
    @MainActor
    func compiles(_ golden: CppGoldenCase) async throws {
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        try Self.compileAndLink(generated, name: golden.fixture)
    }

    @Test(
        "The models with every kind of feature and with several packages compile and link",
        .enabled(if: compiler != nil, "No c++ found on the search path; skipping the compile test"),
        arguments: CppExtraModel.all
    )
    @MainActor
    func compilesExtraModels(_ model: CppExtraModel) async throws {
        let generated = try await model.generate()
        defer { generated.remove() }
        try Self.compileAndLink(generated, name: model.name)
    }

    @Test(
        "The generated library passes its check program",
        .enabled(if: compiler != nil, "No c++ found on the search path; skipping the compile test")
    )
    @MainActor
    func checkProgram() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        try Self.buildAndRunCheck(generated)
    }

    @Test(
        "The generated library passes its check program under the sanitizers",
        .enabled(if: compiler != nil && sanitizersWork, "The compiler cannot build with sanitizers; skipping")
    )
    @MainActor
    func checkProgramWithSanitizers() async throws {
        let golden = try #require(CppGoldenCase.named("library"))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        try Self.buildAndRunCheck(generated, flags: Self.sanitizerFlags)
    }

    @Test(
        "The models with reserved names and many inheritance paths build under the sanitizers",
        .enabled(if: compiler != nil && sanitizersWork, "The compiler cannot build with sanitizers; skipping")
    )
    @MainActor
    func linksWithSanitizers() async throws {
        let golden = try #require(CppGoldenCase.named("cnames"))
        let generated = try await generateCpp(golden)
        defer { generated.remove() }
        try Self.compileAndLink(generated, name: golden.fixture, flags: Self.sanitizerFlags)
        for model in CppExtraModel.all {
            let extra = try await model.generate()
            defer { extra.remove() }
            try Self.compileAndLink(extra, name: model.name, flags: Self.sanitizerFlags)
        }
    }

    @Test("The check program and its second unit are part of the fixture")
    func checkFilesExist() throws {
        for file in Self.checkFiles {
            let text = try String(
                contentsOf: Fixtures.url(of: "library/\(Self.checkFolder)/\(file)"), encoding: .utf8)
            #expect(!text.isEmpty)
            #expect(!text.contains("\u{2014}"), "\(file) has an em-dash")
        }
        #expect(
            try String(contentsOf: Fixtures.url(of: "library/\(Self.checkFolder)/Check.cpp"), encoding: .utf8)
                .contains(Self.successText))
    }
}
