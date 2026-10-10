import Foundation
import Testing

@Suite("swift-ecore generate - Java from generator models")
struct JavaGenerateCommandTests {
    /// The fixtures shared with the generator library tests.
    private static let fixtureRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources")

    /// The generated enumeration of the library fixture, relative to the output directory.
    private static let bookCategory = "org/example/library/BookCategory.java"

    /// The files that generating the library fixture must at least write, relative to the output directory.
    private static let expectedLibraryFiles = [
        bookCategory,
        "org/example/library/Book.java",
        "org/example/library/Library.java",
        "org/example/library/impl/BookImpl.java",
        "org/example/library/impl/LibraryImpl.java",
        "org/example/library/LibraryPackage.java",
        "org/example/library/impl/LibraryPackageImpl.java",
        "org/example/library/LibraryFactory.java",
        "org/example/library/impl/LibraryFactoryImpl.java",
    ]

    /// Copies the library fixture into a scratch directory and writes its generator model.
    ///
    /// - Returns: The scratch directory, the project directory and the generator model.
    @MainActor
    private func libraryProject() async throws -> (scratch: URL, project: URL, genModel: URL) {
        let scratch = try createTemporaryDirectory()
        let project = scratch.appendingPathComponent("library")
        try FileManager.default.copyItem(
            at: Self.fixtureRoot.appendingPathComponent("library"), to: project)
        for expectation in ["expected", "expected-java"] {
            try? FileManager.default.removeItem(at: project.appendingPathComponent(expectation))
        }
        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                project.appendingPathComponent("model/library.ecore").path, "--base-package", "org.example",
                "--copyright", "Copyright 2026 Example Pty Ltd",
            ])
        #expect(created.succeeded)
        return (scratch, project, project.appendingPathComponent("model/library.genmodel"))
    }

    private func expectedBookCategory(folder: String = "expected-java") throws -> String {
        try String(
            contentsOf: Self.fixtureRoot.appendingPathComponent(
                "library/\(folder)/\(Self.bookCategory)"),
            encoding: .utf8)
    }

    @Test("generates Java that matches the reviewed expectation")
    @MainActor
    func generatesJava() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])

        #expect(result.succeeded)
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        for expected in Self.expectedLibraryFiles {
            #expect(
                FileManager.default.fileExists(atPath: output.appendingPathComponent(expected).path),
                "\(expected) was not generated")
        }
        #expect(
            try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
                == expectedBookCategory())
    }

    @Test("imports an Ecore model on the way")
    @MainActor
    func generatesFromEcore() async throws {
        let (scratch, project, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", project.appendingPathComponent("model/library.ecore").path, "-o",
                output.path,
            ])

        #expect(result.succeeded)
        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("library/BookCategory.java").path))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectoryLayout() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--model-directory"])

        #expect(result.succeeded)
        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("library/src/\(Self.bookCategory)").path))
    }

    @Test("keeps hand edits unless the overwrite is forced")
    @MainActor
    func mergeAndForce() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let file = output.appendingPathComponent(Self.bookCategory)
        _ = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])

        var edited = try String(contentsOf: file, encoding: .utf8)
        let closing = try #require(edited.range(of: "}", options: .backwards))
        edited.replaceSubrange(closing, with: "\n  public int answer()\n  {\n    return 42;\n  }\n}")
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let merged = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])
        #expect(merged.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8).contains("public int answer()"))

        let forced = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--force-overwrite"])
        #expect(forced.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == expectedBookCategory())
    }

    @Test("writes beside existing files with the diff option")
    @MainActor
    func diffOption() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let file = output.appendingPathComponent(Self.bookCategory)
        _ = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])
        let damaged = try String(contentsOf: file, encoding: .utf8)
            .replacingOccurrences(of: "return literal;", with: "return null;")
        try damaged.write(to: file, atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--diff"])

        #expect(result.succeeded)
        #expect(try String(contentsOf: file, encoding: .utf8) == damaged)
        let redirected = output.appendingPathComponent("org/example/library/.BookCategory.java.new")
        #expect(try String(contentsOf: redirected, encoding: .utf8) == expectedBookCategory())
    }

    @Test("applies the templates of a template path")
    @MainActor
    func templatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let templates = scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny)]/** Customised */[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", genModel.path, "-o", output.path, "--template-path", templates.path,
            ])

        #expect(result.succeeded)
        let text = try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
        #expect(text.hasPrefix("/** Customised */\npackage org.example.library;"))
    }

    @Test("shows a progress bar with counts in verbose mode")
    @MainActor
    func verboseProgress() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--verbose"])

        #expect(result.succeeded)
        #expect(
            result.stdout.range(of: #"\[={24}\] ([0-9]+)/\1 Generated "#, options: .regularExpression) != nil,
            "the progress bar reaches the total")
        #expect(result.stdout.range(of: #"/[0-9]+ Generated BookCategory\.java"#, options: .regularExpression) != nil)
        #expect(result.stdout.contains("Assembling the java templates"))
    }

    @Test("reports an unknown language with the known ones")
    @MainActor
    func unknownLanguage() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "cobol", genModel.path, "-o", scratch.appendingPathComponent("x").path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("cobol"))
        #expect(result.stderr.contains("java"))
    }

    // MARK: - Code styles

    @Test("writes the eclipse style by default and each style on request")
    @MainActor
    func codeStyles() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let styles: [(arguments: [String], folder: String)] = [
            ([], "expected-java"), (["--code-style", "eclipse"], "expected-java"),
            (["--code-style", "emf"], "expected-java-emf"),
        ]
        for (index, style) in styles.enumerated() {
            let output = scratch.appendingPathComponent("java\(index)")
            let result = try await executeSwiftEcore(
                command: "generate",
                arguments: ["--language", "java", genModel.path, "-o", output.path] + style.arguments)
            #expect(result.succeeded, "\(result.stderr)")
            let text = try String(contentsOf: output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
            #expect(text == (try expectedBookCategory(folder: style.folder)), "\(style.arguments)")
        }
        let tabs = try expectedBookCategory()
        let spaces = try expectedBookCategory(folder: "expected-java-emf")
        #expect(tabs != spaces)
        #expect(tabs.contains("\n\t/**") && !spaces.contains("\t"))
    }

    @Test("rejects an unknown code style with the styles that exist")
    @MainActor
    func unknownCodeStyle() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "java", genModel.path, "-o", output.path, "--code-style", "tabs"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("tabs"))
        #expect(result.stderr.contains("eclipse, emf"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("rejects a code style for a template set that offers none")
    @MainActor
    func codeStyleForSetWithoutStyles() async throws {
        let (scratch, project, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("cpp")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "cpp", project.appendingPathComponent("model/library.ecore").path,
                "-o", output.path, "--code-style", "emf",
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("emf"))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("lists the code styles in the help")
    @MainActor
    func helpListsCodeStyles() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--code-style"))
        #expect(result.stdout.contains("java: eclipse (default), emf"))
    }

    @Test("reports a language without a template set, also for a generator model")
    @MainActor
    func languageWithoutTemplateSetWithGenModel() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: ["--language", "llvm", genModel.path, "-o", scratch.appendingPathComponent("x").path])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("Unsupported language: llvm"))
        #expect(result.stderr.contains("c, cpp, java, swift"))
    }

    @Test("reports a template path that is not a directory")
    @MainActor
    func badTemplatePath() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let missing = scratch.appendingPathComponent("missing")

        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", genModel.path, "-o", scratch.appendingPathComponent("x").path,
                "--template-path", missing.path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not a directory"))
    }

    // MARK: - Generator model defaults

    /// The factory implementation of the library fixture, relative to the output directory.
    private static let factoryImplementation = "library/impl/LibraryFactoryImpl.java"

    /// Generates the Java of the library Ecore model with extra arguments and reads the factory implementation.
    ///
    /// - Parameter extra: The arguments after the model.
    /// - Returns: The text of the factory implementation, or `nil` if the command failed, and the result.
    @MainActor
    private func factoryImplementation(_ extra: [String]) async throws -> (text: String?, result: SubprocessResult) {
        let (scratch, project, _) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", project.appendingPathComponent("model/library.ecore").path, "-o",
                output.path,
            ] + extra)
        let text = try? String(
            contentsOf: output.appendingPathComponent(Self.factoryImplementation), encoding: .utf8)
        return (text, result)
    }

    @Test("imports the interface package with a wildcard by default")
    @MainActor
    func wildcardImportByDefault() async throws {
        let run = try await factoryImplementation([])
        #expect(run.result.succeeded, "\(run.result.stderr)")
        let text = try #require(run.text)
        #expect(text.contains("import library.*;"))
        #expect(!text.contains("import library.Book;"))
    }

    @Test("writes explicit imports with --defaults wizard or --import-organizing")
    @MainActor
    func explicitImports() async throws {
        for arguments in [["--defaults", "wizard"], ["--import-organizing"]] {
            let run = try await factoryImplementation(arguments)
            #expect(run.result.succeeded, "\(run.result.stderr)")
            let text = try #require(run.text)
            #expect(!text.contains("import library.*;"), "\(arguments)")
            #expect(text.contains("import library.Book;"), "\(arguments)")
        }
    }

    @Test("lets --no-import-organizing override the wizard preset")
    @MainActor
    func overridesPreset() async throws {
        let run = try await factoryImplementation(["--defaults", "wizard", "--no-import-organizing"])
        #expect(run.result.succeeded, "\(run.result.stderr)")
        let text = try #require(run.text)
        #expect(text.contains("import library.*;"))
    }

    @Test("rejects the defaults options for a generator model")
    @MainActor
    func defaultsNeedEcore() async throws {
        let (scratch, _, genModel) = try await libraryProject()
        defer { cleanupTemporaryDirectory(scratch) }
        let result = try await executeSwiftEcore(
            command: "generate",
            arguments: [
                "--language", "java", genModel.path, "--defaults", "wizard", "-o",
                scratch.appendingPathComponent("x").path,
            ])
        #expect(!result.succeeded)
        #expect(result.stderr.contains("only apply to an Ecore model"))
    }

    @Test("documents the defaults options in the generate help")
    @MainActor
    func helpListsDefaults() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])
        #expect(result.succeeded)
        for option in [
            "--defaults", "--root-extends-class", "--operation-reflection", "--no-operation-reflection",
            "--import-organizing", "--no-import-organizing",
        ] {
            #expect(result.stdout.contains(option), "Missing \(option)")
        }
    }
}

@Suite("swift-ecore - from Ecore to Java through the command line")
struct JavaChainTests {
    /// The directory that holds the Java files that generating the library fixture must produce.
    private static let expectedJava = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ModellingGeneratorsTests/Resources/library/expected-java")

    /// The files below a directory, relative to it and sorted.
    static func files(below directory: URL) -> [String] {
        let base = directory.standardizedFileURL.path
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        else { return [] }
        var paths: [String] = []
        for case let url as URL in enumerator {
            let isFile = (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isFile { paths.append(String(url.standardizedFileURL.path.dropFirst(base.count + 1))) }
        }
        return paths.sorted()
    }

    /// Copies the library model into a scratch directory.
    private func libraryModel() throws -> (scratch: URL, ecore: URL) {
        let scratch = try createTemporaryDirectory()
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ModellingGeneratorsTests/Resources/library/model/library.ecore")
        let project = scratch.appendingPathComponent("library/model")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let ecore = project.appendingPathComponent("library.ecore")
        try FileManager.default.copyItem(at: source, to: ecore)
        return (scratch, ecore)
    }

    @Test("genmodel then generate produces exactly the golden files")
    @MainActor
    func genModelThenGenerate() async throws {
        let (scratch, ecore) = try libraryModel()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")

        let created = try await executeSwiftEcore(
            command: "genmodel",
            arguments: [
                ecore.path, "--base-package", "org.example", "--copyright", "Copyright 2026 Example Pty Ltd",
                "--defaults", "wizard",
            ])
        #expect(created.succeeded, "\(created.stderr)")
        let genModel = ecore.deletingPathExtension().appendingPathExtension("genmodel")
        let generated = try await executeSwiftEcore(
            command: "generate", arguments: ["--language", "java", genModel.path, "-o", output.path])
        #expect(generated.succeeded, "\(generated.stderr)")

        let expected = Self.files(below: Self.expectedJava)
        #expect(!expected.isEmpty)
        #expect(Self.files(below: output) == expected)
        for path in expected {
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            let golden = try String(contentsOf: Self.expectedJava.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == golden, "\(path) differs from the golden file")
        }
    }

    @Test("generating again keeps a method marked as not generated")
    @MainActor
    func keepsNotGenerated() async throws {
        let (scratch, ecore) = try libraryModel()
        defer { cleanupTemporaryDirectory(scratch) }
        let output = scratch.appendingPathComponent("java")
        let arguments = ["--language", "java", ecore.path, "-o", output.path]
        _ = try await executeSwiftEcore(command: "generate", arguments: arguments)
        let file = output.appendingPathComponent("library/BookCategory.java")
        let original = try String(contentsOf: file, encoding: .utf8)
        let method = try #require(original.range(of: "public static BookCategory getByName"))
        let tag = try #require(
            original.range(of: "@generated", options: .backwards, range: original.startIndex..<method.lowerBound))
        var edited = original
        edited.replaceSubrange(tag, with: "@generated NOT")
        edited = edited.replacingOccurrences(
            of: "if (result.getName().equals(name))", with: "if (result.getName().equalsIgnoreCase(name))")
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let again = try await executeSwiftEcore(command: "generate", arguments: arguments)

        #expect(again.succeeded, "\(again.stderr)")
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(text.contains("equalsIgnoreCase(name)"))
        #expect(text.contains("@generated NOT"))
    }

    @Test("lists the languages of the template sets in the help")
    @MainActor
    func helpListsLanguages() async throws {
        let result = try await executeSwiftEcore(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Languages with a template set: c, cpp, java, swift"))
        #expect(!result.stdout.contains("llvm"))
    }
}
