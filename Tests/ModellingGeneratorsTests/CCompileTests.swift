import Foundation
import Testing

@testable import ModellingGenerators

/// Compiles generated C with the C compiler of the system.
///
/// Each test generates a fixture and compiles its files in a scratch directory below the temporary directory, with
/// the output directory as the search path for includes. Every source file has to compile as C11 without a warning,
/// every header has to compile on its own as C and as C++, and the fixture `library` also links with a program that
/// exercises the generated model and runs it, once more under the address and undefined behaviour sanitizers.
///
/// The tests run only when `cc` can be found on the search path, and the C++ checks only when `c++` can be too.
@Suite("Compiling generated C", .serialized)
struct CCompileTests {
    /// The path of the check program of the library fixture, relative to the fixtures.
    static let checkPath = "library/c-check/Check.c"

    /// The flags that make the C compiler strict.
    static let cFlags = ["-std=c11", "-Wall", "-Wextra", "-Werror"]

    /// The flags that make the C++ compiler strict.
    static let cxxFlags = ["-std=c++20", "-Wall", "-Wextra", "-Werror"]

    /// The flags that make a program check memory and undefined behaviour.
    static let sanitizerFlags = ["-g", "-fsanitize=address,undefined", "-fno-sanitize-recover=undefined"]

    /// The text that the check program writes when every check passed.
    static let successText = "checks passed"

    /// Finds a program on the search path.
    ///
    /// - Parameter name: The name of the program, without the extension of the platform.
    /// - Returns: The location of the program, or `nil` if the search path has none.
    static func executable(_ name: String) -> URL? {
        let search = ProcessInfo.processInfo.environment["PATH"] ?? ""
        #if os(Windows)
            let separator: Character = ";"
            let file = name + ".exe"
        #else
            let separator: Character = ":"
            let file = name
        #endif
        for directory in search.split(separator: separator) {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(file)
            if FileManager.default.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    /// The C compiler, if the search path has one.
    static let cc: URL? = executable("cc")

    /// The C++ compiler, if the search path has one.
    static let cxx: URL? = executable("c++")

    /// The environment variables that make the sanitizers look for leaks where the platform can.
    static var sanitizerEnvironment: [String: String] {
        #if os(Linux)
            return ["ASAN_OPTIONS": "detect_leaks=1"]
        #else
            return [:]
        #endif
    }

    /// Whether the C compiler can build and run a program with the sanitizers.
    static let sanitizersWork: Bool = {
        guard let cc, let scratch = try? makeScratch() else { return false }
        defer { try? FileManager.default.removeItem(at: scratch) }
        let source = scratch.appendingPathComponent("probe.c")
        let program = scratch.appendingPathComponent("probe")
        guard (try? "int main(void) { return 0; }\n".write(to: source, atomically: true, encoding: .utf8)) != nil,
            let built = try? run(cc, sanitizerFlags + [source.path, "-o", program.path], in: scratch),
            built.status == 0,
            let ran = try? run(program, [], in: scratch)
        else { return false }
        return ran.status == 0
    }()

    /// Creates an empty scratch directory below the temporary directory.
    ///
    /// - Returns: The location of the directory; the caller removes it.
    static func makeScratch() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-c-compile")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Runs a program and collects its output.
    ///
    /// - Parameters:
    ///   - executable: The program to run.
    ///   - arguments: The arguments of the program.
    ///   - directory: The directory to run in.
    ///   - environment: Variables to add to the environment of the program.
    /// - Returns: The exit status and the text that the program wrote.
    static func run(
        _ executable: URL, _ arguments: [String], in directory: URL, environment: [String: String] = [:]
    ) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        if !environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// The name of the file that holds the object code of a source file.
    ///
    /// - Parameter path: The path of the source file relative to the output directory.
    /// - Returns: A file name without directories.
    static func objectName(_ path: String) -> String {
        path.replacingOccurrences(of: "/", with: "_") + ".o"
    }

    /// Compiles every source file of a generated project to object code.
    ///
    /// - Parameters:
    ///   - generated: The generated project.
    ///   - compiler: The C compiler.
    ///   - scratch: The directory for the object files.
    ///   - flags: The flags to compile with.
    /// - Returns: The object files, and the report of each source file that failed to compile.
    static func compileSources(
        of generated: GeneratedProject, with compiler: URL, in scratch: URL, flags: [String]
    ) throws -> (objects: [URL], failures: [String]) {
        var objects: [URL] = []
        var failures: [String] = []
        for path in generated.generatedPaths() where path.hasSuffix(".c") {
            let object = scratch.appendingPathComponent(objectName(path))
            let result = try run(
                compiler,
                flags + ["-I", generated.output.path, "-c", generated.file(path).path, "-o", object.path],
                in: scratch)
            if result.status == 0 {
                objects.append(object)
            } else {
                failures.append("\(path) does not compile:\n\(result.output.suffix(4000))")
            }
        }
        return (objects, failures)
    }

    /// Writes a source file that includes headers, each twice to show that the guard works.
    ///
    /// - Parameters:
    ///   - headers: The paths of the headers relative to the output directory.
    ///   - name: The name of the file to write.
    ///   - scratch: The directory to write to.
    /// - Returns: The location of the file.
    static func writeIncluder(of headers: [String], named name: String, in scratch: URL) throws -> URL {
        let text = headers.map { "#include \"\($0)\"\n#include \"\($0)\"\n" }.joined()
        let file = scratch.appendingPathComponent(name)
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    @Test(
        "Every source file compiles as C11 without a warning",
        .enabled(if: cc != nil, "No cc found on the search path; skipping the compile test"),
        arguments: CGoldenCase.all
    )
    @MainActor
    func sourcesCompile(_ golden: CGoldenCase) async throws {
        let cc = try #require(Self.cc)
        let generated = try await generateC(golden)
        let scratch = try Self.makeScratch()
        defer {
            generated.remove()
            try? FileManager.default.removeItem(at: scratch)
        }
        let compiled = try Self.compileSources(of: generated, with: cc, in: scratch, flags: Self.cFlags)
        #expect(compiled.failures.isEmpty, "\(compiled.failures.joined(separator: "\n"))")
        #expect(compiled.objects.count == generated.generatedPaths().filter { $0.hasSuffix(".c") }.count)
    }

    @Test(
        "Every header compiles on its own as C, and all headers of a model together as well",
        .enabled(if: cc != nil, "No cc found on the search path; skipping the compile test"),
        arguments: CGoldenCase.all
    )
    @MainActor
    func headersCompileAsC(_ golden: CGoldenCase) async throws {
        let cc = try #require(Self.cc)
        let generated = try await generateC(golden)
        let scratch = try Self.makeScratch()
        defer {
            generated.remove()
            try? FileManager.default.removeItem(at: scratch)
        }
        let headers = generated.generatedPaths().filter { $0.hasSuffix(".h") }
        var includers = headers.map { [$0] }
        includers.append(headers.reversed())
        for (number, group) in includers.enumerated() {
            let file = try Self.writeIncluder(of: group, named: "includer\(number).c", in: scratch)
            let result = try Self.run(
                cc, Self.cFlags + ["-I", generated.output.path, "-fsyntax-only", file.path], in: scratch)
            #expect(result.status == 0, "\(group.joined(separator: ", ")) do not compile as C:\n\(result.output.suffix(4000))")
        }
    }

    @Test(
        "Every header compiles on its own as C++, and all headers of a model together as well",
        .enabled(if: cc != nil && cxx != nil, "No c++ found on the search path; skipping the compile test"),
        arguments: CGoldenCase.all
    )
    @MainActor
    func headersCompileAsCPlusPlus(_ golden: CGoldenCase) async throws {
        let cxx = try #require(Self.cxx)
        let generated = try await generateC(golden)
        let scratch = try Self.makeScratch()
        defer {
            generated.remove()
            try? FileManager.default.removeItem(at: scratch)
        }
        let headers = generated.generatedPaths().filter { $0.hasSuffix(".h") }
        var includers = headers.map { [$0] }
        includers.append(headers.reversed())
        for (number, group) in includers.enumerated() {
            let file = try Self.writeIncluder(of: group, named: "includer\(number).cpp", in: scratch)
            let result = try Self.run(
                cxx, Self.cxxFlags + ["-I", generated.output.path, "-fsyntax-only", file.path], in: scratch)
            #expect(result.status == 0, "\(group.joined(separator: ", ")) do not compile as C++:\n\(result.output.suffix(4000))")
        }
    }

    @Test(
        "The generated library links with its check program, which passes",
        .enabled(if: cc != nil, "No cc found on the search path; skipping the compile test")
    )
    @MainActor
    func checkProgramPasses() async throws {
        let cc = try #require(Self.cc)
        let golden = try #require(CGoldenCase.named("library"))
        let generated = try await generateC(golden)
        let scratch = try Self.makeScratch()
        defer {
            generated.remove()
            try? FileManager.default.removeItem(at: scratch)
        }
        let compiled = try Self.compileSources(of: generated, with: cc, in: scratch, flags: Self.cFlags)
        #expect(compiled.failures.isEmpty, "\(compiled.failures.joined(separator: "\n"))")
        let check = scratch.appendingPathComponent("Check.o")
        let built = try Self.run(
            cc,
            Self.cFlags + [
                "-I", generated.output.path, "-c", Fixtures.url(of: Self.checkPath).path, "-o", check.path,
            ], in: scratch)
        #expect(built.status == 0, "the check program does not compile:\n\(built.output.suffix(4000))")
        let program = scratch.appendingPathComponent("check")
        let linked = try Self.run(
            cc, (compiled.objects + [check]).map(\.path) + ["-o", program.path], in: scratch)
        #expect(linked.status == 0, "the check program does not link:\n\(linked.output.suffix(4000))")
        guard built.status == 0, linked.status == 0 else { return }

        let ran = try Self.run(program, [], in: scratch)
        #expect(ran.status == 0, "the check of the generated model failed:\n\(ran.output.suffix(4000))")
        #expect(ran.output.contains(Self.successText))
    }

    @Test(
        "The check program passes under the address and undefined behaviour sanitizers",
        .enabled(if: cc != nil, "No cc found on the search path; skipping the sanitizer test"),
        .enabled(if: sanitizersWork, "The sanitizers do not work with this compiler; skipping the sanitizer test")
    )
    @MainActor
    func checkProgramIsClean() async throws {
        let cc = try #require(Self.cc)
        let golden = try #require(CGoldenCase.named("library"))
        let generated = try await generateC(golden)
        let scratch = try Self.makeScratch()
        defer {
            generated.remove()
            try? FileManager.default.removeItem(at: scratch)
        }
        let sources = generated.generatedPaths().filter { $0.hasSuffix(".c") }.map { generated.file($0).path }
        let program = scratch.appendingPathComponent("check-sanitized")
        let built = try Self.run(
            cc,
            Self.cFlags + Self.sanitizerFlags + ["-I", generated.output.path]
                + sources + [Fixtures.url(of: Self.checkPath).path, "-o", program.path],
            in: scratch)
        #expect(built.status == 0, "the sanitized check program does not build:\n\(built.output.suffix(4000))")
        guard built.status == 0 else { return }

        let ran = try Self.run(program, [], in: scratch, environment: Self.sanitizerEnvironment)
        #expect(ran.status == 0, "the sanitized check of the generated model failed:\n\(ran.output.suffix(4000))")
        #expect(ran.output.contains(Self.successText))
    }

    @Test("The includer text names every header twice, to show that the guard works")
    func includerText() throws {
        let scratch = try Self.makeScratch()
        defer { try? FileManager.default.removeItem(at: scratch) }
        let file = try Self.writeIncluder(of: ["a/a.h", "b.h"], named: "includer.c", in: scratch)
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(text == "#include \"a/a.h\"\n#include \"a/a.h\"\n#include \"b.h\"\n#include \"b.h\"\n")
        #expect(Self.objectName("company/people/people.c") == "company_people_people.c.o")
    }
}
