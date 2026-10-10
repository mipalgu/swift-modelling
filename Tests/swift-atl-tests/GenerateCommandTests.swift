import Foundation
import Testing

@Suite("swift-atl generate")
struct GenerateCommandTests {
    /// The base package that the golden files were generated with.
    private static let basePackage = "org.example"

    /// The copyright that the golden files were generated with.
    private static let copyright = "Copyright 2026 Example Pty Ltd"

    /// The options that make the output equal to the golden files, which use the wizard defaults.
    private static let goldenOptions = [
        "--base-package", basePackage, "--copyright", copyright, "--defaults", "wizard",
    ]

    /// The arguments that generate the Java of a fixture into its output directory with the golden options.
    ///
    /// - Parameters:
    ///   - fixture: The fixture to generate from.
    ///   - extra: Further arguments.
    /// - Returns: The arguments of the generate command.
    private static func javaArguments(_ fixture: LibraryFixture, _ extra: [String] = []) -> [String] {
        [fixture.ecore.path, "--language", "java"] + goldenOptions + ["-o", fixture.output.path] + extra
    }

    /// A generated enumeration, relative to the output directory.
    private static let bookCategory = "org/example/library/BookCategory.java"

    // MARK: - Languages

    @Test("lists the languages that exist in the help")
    @MainActor
    func helpListsLanguages() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("Bundled languages: genmodel, c, cpp, java, swift."))
        #expect(!result.stdout.contains("llvm"))
        for option in [
            "--transformations", "--language", "--base-package", "--prefix", "--jdk-level",
            "--template-path", "--force-overwrite", "--diff", "--output",
        ] {
            #expect(result.stdout.contains(option), "\(option) is missing from the help")
        }
    }

    @Test("rejects a language that has no template set and names the available ones")
    @MainActor
    func rejectsUnknownLanguage() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        for language in ["llvm", "cobol"] {
            let result = try await executeSwiftATL(
                command: "generate", arguments: [fixture.ecore.path, "--language", language])

            #expect(!result.succeeded, "\(language) is not a template language")
            #expect(result.stderr.contains("Unsupported target language: \(language)"))
            #expect(result.stderr.contains("genmodel, c, cpp, java, swift"))
        }
    }

    @Test("reports a model that does not exist")
    @MainActor
    func missingModel() async throws {
        let result = try await executeSwiftATL(
            command: "generate", arguments: ["/nonexistent/model.ecore", "--language", "java"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("does not exist"))
    }

    @Test("accepts a language that a template path adds")
    @MainActor
    func templatePathLanguage() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let languages = fixture.scratch.appendingPathComponent("languages")
        let note = languages.appendingPathComponent("note")
        try FileManager.default.createDirectory(at: note, withIntermediateDirectories: true)
        try """
        { "name": "note", "mainModule": "generate", "mainTemplate": "generate" }
        """.write(to: note.appendingPathComponent("templateset.json"), atomically: true, encoding: .utf8)
        try """
        [module generate('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public generate(genModel : GenModel)]
        [file ('outline.txt')]
        [for (genPackage : GenPackage | genModel.genPackages)]
        [genPackage.ecorePackage.name/]
        [for (genClass : GenClass | genPackage.genClasses)]
          [genClass.ecoreClass.name/]
        [/for]
        [/for]
        [/file]
        [/template]
        """.write(to: note.appendingPathComponent("generate.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "note", "--template-path", languages.path, "-o",
                fixture.output.path,
            ])

        #expect(result.succeeded, "\(result.stderr)")
        let outline = try String(
            contentsOf: fixture.output.appendingPathComponent("outline.txt"), encoding: .utf8)
        #expect(outline.hasPrefix("library\n"))
        #expect(outline.contains("  Book\n"))
    }

    // MARK: - Generator models

    @Test("creates a generator model beside the Ecore model")
    @MainActor
    func createsGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "genmodel", "--base-package", Self.basePackage,
                "--prefix", "Lib", "--jdk-level", "11.0", "--copyright", "Example Pty Ltd",
            ])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Wrote"))
        let text = try String(contentsOf: fixture.genModel, encoding: .utf8)
        #expect(text.contains("basePackage=\"org.example\""))
        #expect(text.contains("prefix=\"Lib\""))
        #expect(text.contains("complianceLevel=\"11.0\""))
        #expect(text.contains("Example Pty Ltd"))
    }

    @Test("is the default language and writes to the output directory or file")
    @MainActor
    func genModelOutput() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let directory = fixture.scratch.appendingPathComponent("models")
        let file = fixture.scratch.appendingPathComponent("named.genmodel")

        let toDirectory = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "-o", directory.path])
        let toFile = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "-o", file.path])

        #expect(toDirectory.succeeded, "\(toDirectory.stderr)")
        #expect(toFile.succeeded, "\(toFile.stderr)")
        #expect(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("library.genmodel").path))
        #expect(FileManager.default.fileExists(atPath: file.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.genModel.path))
    }

    @Test("needs an Ecore model for the language genmodel")
    @MainActor
    func genModelNeedsEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        _ = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "--language", "genmodel"])

        let result = try await executeSwiftATL(
            command: "generate", arguments: [fixture.genModel.path, "--language", "genmodel"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("needs an Ecore model"))
    }

    @Test("replaces the bundled transformation with a file or a directory")
    @MainActor
    func replacesTransformation() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let directory = fixture.scratch.appendingPathComponent("transformations")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bundled = try Self.bundledTransformation()
        let customised = try String(contentsOf: bundled, encoding: .utf8)
            .replacingOccurrences(of: "'/'.concat(thisModule.projectName).concat('/src')", with: "'/custom/src'")
        #expect(customised.contains("/custom/src"))
        let file = directory.appendingPathComponent("Ecore2GenModel.atl")
        try customised.write(to: file, atomically: true, encoding: .utf8)

        for location in [file, directory] {
            let output = fixture.scratch.appendingPathComponent("out-\(location.lastPathComponent)")
            let result = try await executeSwiftATL(
                command: "generate",
                arguments: [
                    fixture.ecore.path, "--language", "genmodel", "--transformations", location.path, "-o",
                    output.path,
                ])

            #expect(result.succeeded, "\(result.stderr)")
            let text = try String(
                contentsOf: output.appendingPathComponent("library.genmodel"), encoding: .utf8)
            #expect(text.contains("modelDirectory=\"/custom/src\""))
        }
    }

    @Test("reports a transformation that does not exist or lacks the file")
    @MainActor
    func badTransformation() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let empty = fixture.scratch.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        let missing = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--transformations", fixture.scratch.appendingPathComponent("no.atl").path])
        let noFile = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "--transformations", empty.path])

        #expect(!missing.succeeded)
        #expect(missing.stderr.contains("does not exist"))
        #expect(!noFile.succeeded)
        #expect(noFile.stderr.contains("contains no Ecore2GenModel.atl"))
    }

    // MARK: - Java

    @Test("generates the Java of the library from its Ecore model")
    @MainActor
    func generatesJavaFromEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: Self.javaArguments(fixture))

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.range(of: #"Generated [0-9]+ files in:"#, options: .regularExpression) != nil)
        try Self.expectGoldenTree(in: fixture.output)
        #expect(
            !FileManager.default.fileExists(atPath: fixture.genModel.path),
            "importing on the way leaves no generator model behind")
    }

    @Test("generates the Java of the library from a generator model made by the genmodel language")
    @MainActor
    func generatesJavaFromGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let created = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "genmodel"] + Self.goldenOptions)
        #expect(created.succeeded, "\(created.stderr)")

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.genModel.path, "--language", "java", "-o", fixture.output.path])

        #expect(result.succeeded, "\(result.stderr)")
        try Self.expectGoldenTree(in: fixture.output)
    }

    // MARK: - Code styles

    @Test("writes the eclipse style by default and each style on request")
    @MainActor
    func codeStyles() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let styles: [(arguments: [String], folder: String)] = [
            ([], "expected-java"), (["--code-style", "eclipse"], "expected-java"),
            (["--code-style", "emf"], "expected-java-emf"),
        ]
        for style in styles {
            try? FileManager.default.removeItem(at: fixture.output)
            let result = try await executeSwiftATL(
                command: "generate", arguments: Self.javaArguments(fixture, style.arguments))
            #expect(result.succeeded, "\(result.stderr)")
            let text = try String(
                contentsOf: fixture.output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
            let expected = try String(
                contentsOf: LibraryFixture.fixtureRoot.appendingPathComponent(
                    "library/\(style.folder)/\(Self.bookCategory)"),
                encoding: .utf8)
            #expect(text == expected, "\(style.arguments)")
        }
    }

    @Test("rejects an unknown code style with the styles that exist")
    @MainActor
    func unknownCodeStyle() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate", arguments: Self.javaArguments(fixture, ["--code-style", "tabs"]))

        #expect(!result.succeeded)
        #expect(result.stderr.contains("tabs"))
        #expect(result.stderr.contains("eclipse, emf"))
        #expect(!FileManager.default.fileExists(atPath: fixture.output.path))
    }

    @Test("rejects a code style for the language genmodel")
    @MainActor
    func codeStyleForGenModel() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.ecore.path, "--language", "genmodel", "--code-style", "emf"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("--code-style only applies to a language with a template set"))
        #expect(!FileManager.default.fileExists(atPath: fixture.genModel.path))
    }

    @Test("lists the code styles in the help")
    @MainActor
    func helpListsCodeStyles() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: ["--help"])

        #expect(result.succeeded)
        #expect(result.stdout.contains("--code-style"))
        #expect(result.stdout.contains("java: eclipse (default), emf"))
    }

    @Test("keeps a method marked as not generated when the code is generated again")
    @MainActor
    func keepsHandEdits() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let arguments = Self.javaArguments(fixture)
        _ = try await executeSwiftATL(command: "generate", arguments: arguments)
        let file = fixture.output.appendingPathComponent(Self.bookCategory)
        let edited = try Self.markedAsEdited(String(contentsOf: file, encoding: .utf8))
        try edited.write(to: file, atomically: true, encoding: .utf8)

        let merged = try await executeSwiftATL(command: "generate", arguments: arguments)

        #expect(merged.succeeded, "\(merged.stderr)")
        let text = try String(contentsOf: file, encoding: .utf8)
        #expect(text.contains("equalsIgnoreCase(name)"))
        #expect(text.contains("@generated NOT"))

        let forced = try await executeSwiftATL(
            command: "generate", arguments: arguments + ["--force-overwrite"])

        #expect(forced.succeeded, "\(forced.stderr)")
        #expect(try String(contentsOf: file, encoding: .utf8) == Self.golden(Self.bookCategory))
    }

    @Test("writes beside existing files with the diff option")
    @MainActor
    func diffOption() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let arguments = Self.javaArguments(fixture)
        _ = try await executeSwiftATL(command: "generate", arguments: arguments)
        let file = fixture.output.appendingPathComponent(Self.bookCategory)
        let damaged = try String(contentsOf: file, encoding: .utf8)
            .replacingOccurrences(of: "return literal;", with: "return null;")
        try damaged.write(to: file, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(command: "generate", arguments: arguments + ["--diff"])

        #expect(result.succeeded, "\(result.stderr)")
        #expect(try String(contentsOf: file, encoding: .utf8) == damaged)
        let redirected = fixture.output.appendingPathComponent("org/example/library/.BookCategory.java.new")
        #expect(try String(contentsOf: redirected, encoding: .utf8) == Self.golden(Self.bookCategory))
    }

    @Test("applies the templates of a template path")
    @MainActor
    func templatePath() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let templates = fixture.scratch.appendingPathComponent("templates")
        try FileManager.default.createDirectory(at: templates, withIntermediateDirectories: true)
        try """
        [module Header('http://www.eclipse.org/emf/2002/GenModel')/]
        [template public header(element : OclAny)]/** Customised */[/template]
        """.write(to: templates.appendingPathComponent("Header.mtl"), atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: Self.javaArguments(fixture, ["--template-path", templates.path]))

        #expect(result.succeeded, "\(result.stderr)")
        let text = try String(
            contentsOf: fixture.output.appendingPathComponent(Self.bookCategory), encoding: .utf8)
        #expect(text.hasPrefix("/** Customised */\npackage org.example.library;"))
    }

    @Test("writes below the model directory on request")
    @MainActor
    func modelDirectory() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: Self.javaArguments(fixture, ["--model-directory"]))

        #expect(result.succeeded, "\(result.stderr)")
        #expect(
            FileManager.default.fileExists(
                atPath: fixture.output.appendingPathComponent("library/src/\(Self.bookCategory)").path))
    }

    @Test("shows a line with counts for every file in verbose mode")
    @MainActor
    func verboseProgress() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: Self.javaArguments(fixture, ["--verbose"]))

        #expect(result.succeeded, "\(result.stderr)")
        #expect(result.stdout.contains("Transforming library.ecore"))
        #expect(
            result.stdout.range(of: #"\[={24}\] ([0-9]+)/\1 Generated "#, options: .regularExpression) != nil,
            "the progress bar reaches the total")
        #expect(result.stdout.range(of: #"/[0-9]+ Generated BookCategory\.java"#, options: .regularExpression) != nil)
    }

    @Test("reports a template path that is not a directory")
    @MainActor
    func badTemplatePath() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [
                fixture.ecore.path, "--language", "java", "--template-path",
                fixture.scratch.appendingPathComponent("missing").path,
            ])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("not a directory"))
    }

    @Test("reports an input that is neither an Ecore model nor a generator model")
    @MainActor
    func unsupportedInput() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let other = fixture.scratch.appendingPathComponent("model.xmi")
        try "<x/>".write(to: other, atomically: true, encoding: .utf8)

        let result = try await executeSwiftATL(
            command: "generate", arguments: [other.path, "--language", "java"])

        #expect(!result.succeeded)
        #expect(result.stderr.contains("neither a generator model nor an Ecore model"))
    }

    // MARK: - Generator model defaults

    /// The settings of the wizard preset, as the lines of the generator model.
    private static let wizardLines = [
        #"operationReflection="true""#, #"importOrganizing="true""#,
        #"rootExtendsClass="org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container""#,
    ]

    /// Creates the generator model of the library with extra arguments and reads it.
    private static func genModelText(_ extra: [String]) async throws -> (text: String, result: SubprocessResult) {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let result = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "--language", "genmodel"] + extra)
        return ((try? String(contentsOf: fixture.genModel, encoding: .utf8)) ?? "", result)
    }

    @Test("leaves the root class, operation reflection and import organising at the metamodel defaults")
    @MainActor
    func headlessGenModel() async throws {
        let run = try await Self.genModelText([])
        #expect(run.result.succeeded, "\(run.result.stderr)")
        #expect(!run.text.contains("operationReflection"))
        #expect(!run.text.contains("importOrganizing"))
        #expect(!run.text.contains("rootExtendsClass"))
    }

    @Test("writes the settings of the interactive wizard for --defaults wizard")
    @MainActor
    func wizardGenModel() async throws {
        let run = try await Self.genModelText(["--defaults", "wizard"])
        #expect(run.result.succeeded, "\(run.result.stderr)")
        for line in Self.wizardLines { #expect(run.text.contains(line), "Missing \(line)") }
    }

    @Test("lets each flag override the preset")
    @MainActor
    func flagsOverridePreset() async throws {
        let wizard = try await Self.genModelText([
            "--defaults", "wizard", "--no-operation-reflection", "--no-import-organizing",
            "--root-extends-class", "org.example.Root",
        ])
        #expect(wizard.result.succeeded, "\(wizard.result.stderr)")
        #expect(!wizard.text.contains("operationReflection"))
        #expect(!wizard.text.contains("importOrganizing"))
        #expect(wizard.text.contains(#"rootExtendsClass="org.example.Root""#))
        let headless = try await Self.genModelText([
            "--defaults", "headless", "--operation-reflection", "--import-organizing",
        ])
        #expect(headless.result.succeeded, "\(headless.result.stderr)")
        #expect(headless.text.contains(#"operationReflection="true""#))
        #expect(headless.text.contains(#"importOrganizing="true""#))
        #expect(!headless.text.contains("rootExtendsClass"))
    }

    @Test("writes explicit imports into the Java when imports are organised")
    @MainActor
    func organisedImports() async throws {
        let factory = "org/example/library/impl/LibraryFactoryImpl.java"
        let plain = try LibraryFixture.make()
        defer { plain.remove() }
        let organised = try LibraryFixture.make()
        defer { organised.remove() }
        let base = ["--base-package", Self.basePackage]
        let one = try await executeSwiftATL(
            command: "generate",
            arguments: [plain.ecore.path, "--language", "java", "-o", plain.output.path] + base)
        let two = try await executeSwiftATL(
            command: "generate",
            arguments: [organised.ecore.path, "--language", "java", "-o", organised.output.path, "--import-organizing"] + base)
        #expect(one.succeeded && two.succeeded, "\(one.stderr)\(two.stderr)")
        let plainText = try String(contentsOf: plain.output.appendingPathComponent(factory), encoding: .utf8)
        let organisedText = try String(contentsOf: organised.output.appendingPathComponent(factory), encoding: .utf8)
        #expect(plainText.contains("import org.example.library.*;"))
        #expect(!organisedText.contains("import org.example.library.*;"))
        #expect(organisedText.contains("import org.example.library.Book;"))
    }

    @Test("rejects the defaults options for a generator model")
    @MainActor
    func defaultsNeedEcore() async throws {
        let fixture = try LibraryFixture.make()
        defer { fixture.remove() }
        let created = try await executeSwiftATL(
            command: "generate", arguments: [fixture.ecore.path, "--language", "genmodel"])
        #expect(created.succeeded)
        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [fixture.genModel.path, "--language", "java", "--no-import-organizing"])
        #expect(!result.succeeded)
        #expect(result.stderr.contains("only apply to an Ecore model"))
    }

    @Test("rejects a preset that does not exist")
    @MainActor
    func unknownPreset() async throws {
        let run = try await Self.genModelText(["--defaults", "interactive"])
        #expect(!run.result.succeeded)
        #expect(run.result.stderr.contains("interactive"))
        #expect(run.result.stderr.contains("wizard"))
    }

    @Test("documents the defaults options in the help")
    @MainActor
    func helpListsDefaults() async throws {
        let result = try await executeSwiftATL(command: "generate", arguments: ["--help"])
        #expect(result.succeeded)
        for option in [
            "--defaults", "--root-extends-class", "--operation-reflection", "--no-operation-reflection",
            "--import-organizing", "--no-import-organizing", "headless", "wizard",
        ] {
            #expect(result.stdout.contains(option), "Missing \(option)")
        }
    }

    @Test("writes plain relative references when the model is reached through a symbolic link")
    @MainActor
    func genModelThroughSymbolicLink() async throws {
        let fixture = try LibraryFixture.make()
        let holder = try createTemporaryDirectory()
        defer {
            fixture.remove()
            cleanupTemporaryDirectory(holder)
        }
        let link = holder.appendingPathComponent("linked")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.project)

        let result = try await executeSwiftATL(
            command: "generate",
            arguments: [link.appendingPathComponent("model/library.ecore").path, "--language", "genmodel"])

        #expect(result.succeeded, "\(result.stderr)")
        let text = try String(contentsOf: fixture.genModel, encoding: .utf8)
        #expect(text.contains("<foreignModel>library.ecore</foreignModel>"))
        #expect(text.contains(#"ecoreClass="library.ecore#//Book""#))
        #expect(!text.contains(".."))
    }

    // MARK: - Support

    /// The text of a committed golden file.
    private static func golden(_ path: String) throws -> String {
        try String(contentsOf: LibraryFixture.expectedJava.appendingPathComponent(path), encoding: .utf8)
    }

    /// Expects that every golden file was generated with identical text.
    private static func expectGoldenTree(in output: URL) throws {
        let expected = LibraryFixture.files(below: LibraryFixture.expectedJava)
        let generated = LibraryFixture.files(below: output)
        #expect(!expected.isEmpty)
        for path in expected {
            #expect(generated.contains(path), "\(path) was not generated")
            let actual = try? String(contentsOf: output.appendingPathComponent(path), encoding: .utf8)
            #expect(actual == (try golden(path)), "\(path) differs from the golden file")
        }
    }

    /// Marks a method of the enumeration as maintained by hand and changes its body.
    private static func markedAsEdited(_ text: String) throws -> String {
        let method = try #require(text.range(of: "public static BookCategory getByName"))
        let tag = try #require(
            text.range(of: "@generated", options: .backwards, range: text.startIndex..<method.lowerBound))
        var edited = text
        edited.replaceSubrange(tag, with: "@generated NOT")
        return edited.replacingOccurrences(
            of: "if (result.getName().equals(name))", with: "if (result.getName().equalsIgnoreCase(name))")
    }

    /// The bundled transformation in the source tree.
    private static func bundledTransformation() throws -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/ModellingGenerators/Transformations/Ecore2GenModel.atl")
    }
}
