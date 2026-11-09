//
// OutputEncodingCommandTests.swift
// swift-ecore-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Tests for `--output-encoding` and the `output-encoding` key of the configuration file in the
/// `swift-ecore` commands that write files.
///
/// Files are written in UTF-8 unless the command line or the configuration file names another
/// encoding. XML names the encoding in its declaration and refers to a character that the
/// encoding cannot hold by number; plain text cannot hold such a character, and the file is
/// then not written; JSON is always UTF-8, with a warning. Standard output is not affected.
@Suite("swift-ecore - output encodings", .serialized)
struct OutputEncodingCommandTests {
    /// The name of the configuration file.
    static let configurationFile = ".swift-modelling.json"

    /// The option that names the encoding of written files.
    static let option = "--output-encoding"

    /// The start of the warning that a JSON file was written in UTF-8.
    static let jsonWarning = "JSON is always written in UTF-8, not ISO-8859-1"

    /// The XML declaration of a document in ISO-8859-1.
    static let latin1Declaration = #"<?xml version="1.0" encoding="ISO-8859-1"?>"#

    /// A metamodel whose class name holds a character outside US-ASCII but inside ISO-8859-1,
    /// and whose annotation holds a character outside ISO-8859-1.
    static let metamodel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="shop" \
        nsURI="http://www.example.org/shop" nsPrefix="shop">
          <eClassifiers xsi:type="ecore:EClass" name="Caf\u{E9}">
            <eAnnotations source="http://www.example.org/notes">
              <details key="currency" value="\u{20AC}"/>
            </eAnnotations>
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" \
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>

        """

    /// A revision of ``metamodel`` with another attribute.
    static let revision = metamodel.replacingOccurrences(
        of: "  </eClassifiers>",
        with: """
                <eStructuralFeatures xsi:type="ecore:EAttribute" name="seats" \
            eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
              </eClassifiers>
            """)

    /// A model of ``metamodel`` whose root object sets a feature that its class does not define,
    /// so that validation reports the class by name.
    static let invalidModel = """
        <?xml version="1.0" encoding="UTF-8"?>
        <shop:Caf\u{E9} xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:shop="http://www.example.org/shop" seats="3"/>

        """

    /// A repository with the metamodels of the tests and a nested working directory.
    struct Workspace {
        /// The root of the repository.
        let root: URL

        /// The directory the tool runs in, two levels below the root.
        var workingDirectory: URL { root.appendingPathComponent("work/nested") }

        /// The metamodel.
        var metamodel: String { path("shop.ecore") }

        /// The revised metamodel.
        var revision: String { path("revised.ecore") }

        /// A model of the metamodel that validation rejects.
        var invalidModel: String { path("cafe.xmi") }

        /// Creates the repository.
        init() throws {
            root = try createTemporaryDirectory()
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
            try write(OutputEncodingCommandTests.metamodel, to: "shop.ecore")
            try write(OutputEncodingCommandTests.revision, to: "revised.ecore")
            try write(OutputEncodingCommandTests.invalidModel, to: "cafe.xmi")
        }

        /// The path of a file below the root.
        ///
        /// - Parameter name: The path relative to the root.
        /// - Returns: The absolute path.
        func path(_ name: String) -> String { root.appendingPathComponent(name).path }

        /// Writes a file below the root.
        ///
        /// - Parameters:
        ///   - text: The contents of the file.
        ///   - name: The path of the file relative to the root.
        func write(_ text: String, to name: String = OutputEncodingCommandTests.configurationFile) throws {
            try text.write(toFile: path(name), atomically: true, encoding: .utf8)
        }

        /// The bytes of a file below the root, if it exists.
        ///
        /// - Parameter name: The path relative to the root.
        /// - Returns: The bytes, or `nil` if there is no such file.
        func data(_ name: String) -> Data? {
            FileManager.default.contents(atPath: path(name))
        }

        /// Runs a command of `swift-ecore` from the working directory, removing its output first.
        ///
        /// - Parameters:
        ///   - command: The command.
        ///   - arguments: Its arguments.
        ///   - output: The file below the root that the command writes, if any.
        /// - Returns: The result of the command.
        @MainActor
        func run(_ command: String, _ arguments: [String], output: String? = nil) async throws -> SubprocessResult {
            if let output { try? FileManager.default.removeItem(atPath: path(output)) }
            return try await executeSwiftEcore(command: command, arguments: arguments, workingDirectory: workingDirectory)
        }

        /// Removes the repository.
        func remove() { cleanupTemporaryDirectory(root) }
    }

    /// The arguments of the commands that write a text report, with the file they write.
    ///
    /// - Parameter workspace: The repository.
    /// - Returns: Each command, its arguments and the report it writes.
    static func reportCommands(_ workspace: Workspace) -> [(command: String, arguments: [String], output: String)] {
        [
            ("inspect", [workspace.metamodel, "--output", workspace.path("inspect.txt")], "inspect.txt"),
            ("statistics", [workspace.metamodel, "--output", workspace.path("statistics.txt")], "statistics.txt"),
            ("compare", [workspace.metamodel, workspace.revision, "--output", workspace.path("compare.txt")],
             "compare.txt"),
            ("validate", [workspace.invalidModel, "--metamodel", workspace.metamodel, "--report", workspace.path("validate.txt")],
             "validate.txt"),
        ]
    }

    /// Whether data is ISO-8859-1 text that is not valid UTF-8 and holds a text.
    ///
    /// - Parameters:
    ///   - data: The bytes of a file.
    ///   - text: The text that the file holds.
    /// - Returns: `true` if the bytes read as ISO-8859-1 hold the text and are not UTF-8.
    static func isLatin1(_ data: Data?, holding text: String) -> Bool {
        guard let data, let decoded = String(data: data, encoding: .isoLatin1) else { return false }
        return decoded.contains(text) && String(data: data, encoding: .utf8) == nil
    }

    // MARK: - convert and create

    @Test("convert writes UTF-8 by default, byte for byte as with UTF-8 named")
    @MainActor
    func convertDefault() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let implicit = try await workspace.run("convert", [workspace.metamodel, workspace.path("implicit.ecore")])
        let explicit = try await workspace.run(
            "convert", [workspace.metamodel, workspace.path("explicit.ecore"), Self.option, "UTF-8"])

        #expect(implicit.succeeded, "\(implicit.stdout)\(implicit.stderr)")
        #expect(explicit.succeeded, "\(explicit.stdout)\(explicit.stderr)")
        let data = try #require(workspace.data("implicit.ecore"))
        #expect(String(data: data, encoding: .utf8)?.contains("Caf\u{E9}") == true)
        #expect(data == workspace.data("explicit.ecore"))
    }

    @Test("convert writes XML in ISO-8859-1 with its declaration and character references")
    @MainActor
    func convertLatin1() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let result = try await workspace.run(
            "convert", [workspace.metamodel, workspace.path("latin1.ecore"), Self.option, "latin1"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let data = workspace.data("latin1.ecore")
        #expect(Self.isLatin1(data, holding: Self.latin1Declaration))
        #expect(Self.isLatin1(data, holding: #"name="Caf\#u{E9}""#))
        #expect(Self.isLatin1(data, holding: #"value="&#x20AC;""#))
        #expect(result.stdout.contains("Conversion completed"), "\(result.stdout)")
    }

    @Test("convert stops on plain text that the encoding cannot hold, naming the file, and writes nothing")
    @MainActor
    func convertUnrepresentable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let output = workspace.path("shop.km3")

        let result = try await workspace.run(
            "convert", [workspace.metamodel, output, Self.option, "US-ASCII"], output: "shop.km3")

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Cannot write \(output)"), "\(result.stderr)")
        #expect(result.stderr.contains("line "), "\(result.stderr)")
        #expect(result.stderr.contains("column "), "\(result.stderr)")
        #expect(result.stderr.contains("US-ASCII"), "\(result.stderr)")
        #expect(workspace.data("shop.km3") == nil)
    }

    @Test("convert writes JSON in UTF-8 with a warning when another encoding is named")
    @MainActor
    func convertJSON() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let result = try await workspace.run(
            "convert", [workspace.metamodel, workspace.path("shop.json"), Self.option, "ISO-8859-1"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stderr.contains(Self.jsonWarning), "\(result.stderr)")
        let data = try #require(workspace.data("shop.json"))
        #expect(String(data: data, encoding: .utf8)?.contains("Caf\u{E9}") == true)
    }

    @Test("create writes the model in the encoding named, and stops on a name it cannot hold")
    @MainActor
    func create() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let arguments = ["--metamodel", workspace.metamodel, "--root-class", "Caf\u{E9}", "--output"]

        let implicit = try await workspace.run("create", arguments + [workspace.path("implicit.xmi")])
        let explicit = try await workspace.run(
            "create", arguments + [workspace.path("explicit.xmi"), Self.option, "UTF-8"])
        let latin1 = try await workspace.run("create", arguments + [workspace.path("latin1.xmi"), Self.option, "latin1"])
        let ascii = try await workspace.run("create", arguments + [workspace.path("ascii.xmi"), Self.option, "ascii"])

        #expect(implicit.succeeded, "\(implicit.stdout)\(implicit.stderr)")
        #expect(workspace.data("implicit.xmi") != nil)
        #expect(workspace.data("implicit.xmi") == workspace.data("explicit.xmi"))
        #expect(latin1.succeeded, "\(latin1.stdout)\(latin1.stderr)")
        #expect(Self.isLatin1(workspace.data("latin1.xmi"), holding: Self.latin1Declaration))
        #expect(Self.isLatin1(workspace.data("latin1.xmi"), holding: "shop:Caf\u{E9}"))
        #expect(!ascii.succeeded)
        #expect(ascii.stderr.contains("Cannot write \(workspace.path("ascii.xmi"))"), "\(ascii.stderr)")
        #expect(workspace.data("ascii.xmi") == nil)
    }

    // MARK: - Reports

    @Test("reports are written in UTF-8 by default and in the encoding named otherwise")
    @MainActor
    func reports() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        for (command, arguments, output) in Self.reportCommands(workspace) {
            _ = try await workspace.run(command, arguments, output: output)
            let implicit = try #require(workspace.data(output), "\(command)")
            _ = try await workspace.run(command, arguments + [Self.option, "UTF-8"], output: output)
            let explicit = workspace.data(output)
            let latin1 = try await workspace.run(command, arguments + [Self.option, "latin1"], output: output)

            #expect(String(data: implicit, encoding: .utf8)?.contains("Caf\u{E9}") == true, "\(command)")
            #expect(implicit == explicit, "\(command)")
            #expect(Self.isLatin1(workspace.data(output), holding: "Caf\u{E9}"), "\(command): \(latin1.stderr)")
        }
    }

    @Test("a report that the encoding cannot hold is not written, and the error names the file")
    @MainActor
    func reportUnrepresentable() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        for (command, arguments, output) in Self.reportCommands(workspace) {
            let result = try await workspace.run(command, arguments + [Self.option, "US-ASCII"], output: output)

            #expect(!result.succeeded, "\(command)")
            #expect(result.stderr.contains("Cannot write \(workspace.path(output))"), "\(command): \(result.stderr)")
            #expect(result.stderr.contains("column "), "\(command): \(result.stderr)")
            #expect(workspace.data(output) == nil, "\(command)")
        }
    }

    @Test("JSON reports are written in UTF-8 with a warning when another encoding is named")
    @MainActor
    func jsonReports() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        for (command, arguments, output) in Self.reportCommands(workspace) {
            let result = try await workspace.run(
                command, arguments + ["--format", "json", Self.option, "latin1"], output: output)

            #expect(result.stderr.contains(Self.jsonWarning), "\(command): \(result.stderr)")
            let data = try #require(workspace.data(output), "\(command)")
            #expect(String(data: data, encoding: .utf8)?.contains("Caf\u{E9}") == true, "\(command)")
        }
    }

    @Test("standard output is not affected by the encoding")
    @MainActor
    func standardOutput() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let result = try await workspace.run("inspect", [workspace.metamodel, Self.option, "US-ASCII"])

        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        #expect(result.stdout.contains("Caf\u{E9}"), "\(result.stdout)")
    }

    // MARK: - genmodel and generate

    @Test("genmodel writes the generator model in the encoding named")
    @MainActor
    func genModel() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        let arguments = [workspace.metamodel, "--copyright", "\u{A9} \u{20AC}", "--output"]

        let implicit = try await workspace.run("genmodel", arguments + [workspace.path("implicit/shop.genmodel")])
        let explicit = try await workspace.run(
            "genmodel", arguments + [workspace.path("explicit/shop.genmodel"), Self.option, "UTF-8"])
        let latin1 = try await workspace.run(
            "genmodel", arguments + [workspace.path("latin1/shop.genmodel"), Self.option, "latin1"])

        #expect(implicit.succeeded, "\(implicit.stdout)\(implicit.stderr)")
        #expect(explicit.succeeded, "\(explicit.stdout)\(explicit.stderr)")
        #expect(workspace.data("implicit/shop.genmodel") != nil)
        #expect(workspace.data("implicit/shop.genmodel") == workspace.data("explicit/shop.genmodel"))
        #expect(latin1.succeeded, "\(latin1.stdout)\(latin1.stderr)")
        #expect(Self.isLatin1(workspace.data("latin1/shop.genmodel"), holding: Self.latin1Declaration))
        #expect(Self.isLatin1(workspace.data("latin1/shop.genmodel"), holding: "\u{A9} &#x20AC;"))
    }

    @Test("generate writes the code in the encoding named, and stops on a character it cannot hold")
    @MainActor
    func generate() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        func run(_ directory: String, _ extra: [String]) async throws -> (SubprocessResult, [String: Data]) {
            let output = workspace.root.appendingPathComponent(directory)
            let result = try await workspace.run(
                "generate", [workspace.metamodel, "--language", "swift", "--output", output.path] + extra)
            return (result, try Self.files(below: output))
        }

        let (implicitResult, implicit) = try await run("implicit", [])
        let (_, explicit) = try await run("explicit", [Self.option, "UTF-8"])
        let (latin1Result, latin1) = try await run("latin1", [Self.option, "latin1"])
        let (asciiResult, ascii) = try await run("ascii", [Self.option, "US-ASCII"])

        #expect(implicitResult.succeeded, "\(implicitResult.stdout)\(implicitResult.stderr)")
        #expect(!implicit.isEmpty)
        #expect(implicit == explicit)
        #expect(latin1Result.succeeded, "\(latin1Result.stdout)\(latin1Result.stderr)")
        #expect(Set(latin1.keys) == Set(implicit.keys))
        for (path, data) in implicit {
            let text = try #require(String(data: data, encoding: .utf8), "\(path)")
            #expect(latin1[path] == text.data(using: .isoLatin1), "\(path)")
        }
        #expect(!asciiResult.succeeded)
        #expect(asciiResult.stderr.contains("line "), "\(asciiResult.stderr)")
        #expect(asciiResult.stderr.contains("column "), "\(asciiResult.stderr)")
        for (path, data) in ascii {
            #expect(!data.contains { $0 >= 0x80 }, "\(path) was written in part")
        }
    }

    /// The regular files below a directory.
    ///
    /// - Parameter directory: The directory.
    /// - Returns: The bytes of every file, by path relative to the directory.
    static func files(below directory: URL) throws -> [String: Data] {
        var files: [String: Data] = [:]
        let base = directory.standardizedFileURL.resolvingSymlinksInPath().path
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        while let url = enumerator?.nextObject() as? URL {
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            let path = url.standardizedFileURL.resolvingSymlinksInPath().path
            files[String(path.dropFirst(base.count))] = try Data(contentsOf: url)
        }
        return files
    }

    // MARK: - Configuration file and errors

    @Test("the configuration file names the encoding, which the command line overrides")
    @MainActor
    func configuration() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "output-encoding": "latin1" }"#)
        let convert = [workspace.metamodel, workspace.path("out.ecore"), "--force"]
        let report = [workspace.metamodel, "--output", workspace.path("report.txt")]

        _ = try await workspace.run("convert", convert, output: "out.ecore")
        let configured = workspace.data("out.ecore")
        _ = try await workspace.run("convert", convert + [Self.option, "UTF-8"], output: "out.ecore")
        let overridden = workspace.data("out.ecore")
        _ = try await workspace.run("convert", convert + ["--no-config"], output: "out.ecore")
        let ignored = workspace.data("out.ecore")
        _ = try await workspace.run("statistics", report, output: "report.txt")
        let configuredReport = workspace.data("report.txt")
        _ = try await workspace.run("statistics", report + [Self.option, "UTF-8"], output: "report.txt")
        let overriddenReport = workspace.data("report.txt")

        #expect(Self.isLatin1(configured, holding: Self.latin1Declaration))
        #expect(overridden.flatMap { String(data: $0, encoding: .utf8) }?.contains("Caf\u{E9}") == true)
        #expect(ignored == overridden)
        #expect(Self.isLatin1(configuredReport, holding: "Caf\u{E9}"))
        #expect(overriddenReport.flatMap { String(data: $0, encoding: .utf8) }?.contains("Caf\u{E9}") == true)
    }

    @Test("the configuration file names the encoding of generated code and generator models")
    @MainActor
    func configurationOfGenerators() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }
        try workspace.write(#"{ "output-encoding": "latin1" }"#)
        let output = workspace.root.appendingPathComponent("swift")

        let generated = try await workspace.run(
            "generate", [workspace.metamodel, "--language", "swift", "--output", output.path])
        let imported = try await workspace.run(
            "genmodel", [workspace.metamodel, "--output", workspace.path("shop.genmodel")])

        #expect(generated.succeeded, "\(generated.stdout)\(generated.stderr)")
        #expect(try Self.files(below: output).values.contains { Self.isLatin1($0, holding: "Caf\u{E9}") })
        #expect(imported.succeeded, "\(imported.stdout)\(imported.stderr)")
        #expect(Self.isLatin1(workspace.data("shop.genmodel"), holding: Self.latin1Declaration))
    }

    @Test("an unknown encoding is an error of the command line")
    @MainActor
    func invalidName() async throws {
        let workspace = try Workspace()
        defer { workspace.remove() }

        let result = try await workspace.run(
            "convert", [workspace.metamodel, workspace.path("out.ecore"), Self.option, "klingon"], output: "out.ecore")

        #expect(!result.succeeded)
        #expect(result.stderr.contains("klingon"), "\(result.stderr)")
        #expect(workspace.data("out.ecore") == nil)
    }

    @Test("the help of every command that writes files describes --output-encoding")
    @MainActor
    func help() async throws {
        for command in ["convert", "create", "genmodel", "generate", "inspect", "statistics", "compare", "validate"] {
            let result = try await executeSwiftEcore(command: command, arguments: ["--help"])

            #expect(result.succeeded, "\(command)")
            #expect(result.stdout.contains(Self.option), "\(command)")
        }
    }
}
