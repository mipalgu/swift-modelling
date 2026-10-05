import Foundation
import MTL
import Testing

@testable import ModellingGenerators

/// The code styles of the Java template set: layout as data, chosen by name.
@Suite("Java code styles")
struct JavaCodeStyleTests {
    /// The style that applies without a choice.
    static let defaultStyle = "eclipse"

    /// The style that matches the layout of the Eclipse Modeling Framework repository.
    static let repositoryStyle = "emf"

    /// The names of both styles, for tests that run in each.
    static let styleNames = [defaultStyle, repositoryStyle]

    /// Files of the library whose members are all regenerated when the style changes.
    static let unmixedFiles = [
        "org/example/library/LibraryFactory.java", "org/example/library/impl/LibraryFactoryImpl.java",
        "org/example/library/impl/BookImpl.java", "org/example/library/Book.java",
    ]

    /// The fixtures with expectations in both styles.
    static let bothStyleFixtures = ["library", "families", "enumerations"]

    /// The folder of the expectations in the repository style, below the fixture.
    static let repositoryExpectationFolder = "expected-java-emf"

    /// The import options for the library fixture.
    static let libraryOptions = GenModelImportOptions(
        basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd", defaults: .wizard)

    /// The path of the library enumeration in the generated output.
    static let bookCategory = "org/example/library/BookCategory.java"

    /// The path of the library implementation class in the generated output.
    static let libraryImpl = "org/example/library/impl/LibraryImpl.java"

    /// Generates the library fixture in a style.
    ///
    /// - Parameter style: The name of the style, or `nil` for the default.
    /// - Returns: The generated project.
    @MainActor
    static func library(style: String?) async throws -> GeneratedProject {
        let generated = try await GeneratedProject.make("library", stem: "library", options: libraryOptions)
        try await generated.generate(options: GenerationOptions(codeStyle: style))
        return generated
    }

    /// The whitespace-separated tokens of a text.
    static func tokens(_ text: String) -> [Substring] {
        text.split(whereSeparator: \.isWhitespace)
    }

    /// The lines of a text that consist of an opening brace only.
    static func ownLineOpeners(_ text: String) -> [Substring] {
        text.split(separator: "\n").filter { $0.trimmingCharacters(in: .whitespaces) == "{" }
    }

    /// The lines of a text that start with a tab.
    static func tabIndented(_ text: String) -> [Substring] {
        text.split(separator: "\n").filter { $0.hasPrefix("\t") }
    }

    /// The lines of a text that start with a space.
    static func spaceIndented(_ text: String) -> [Substring] {
        text.split(separator: "\n").filter { $0.hasPrefix(" ") && !$0.hasPrefix(" *") }
    }

    // MARK: - Descriptor

    @Test("The Java template set offers the eclipse and emf styles and defaults to eclipse")
    func descriptorOffersStyles() throws {
        let set = try TemplateSet.assemble(language: "java")
        defer { set.remove() }
        #expect(set.descriptor.styleNames == [Self.defaultStyle, Self.repositoryStyle].sorted())
        #expect(set.descriptor.defaultStyle == Self.defaultStyle)
        let eclipse = try #require(set.descriptor.styles[Self.defaultStyle])
        #expect(eclipse.openerPlacement == .sameLine)
        #expect(eclipse.targetIndent == "\t")
        let emf = try #require(set.descriptor.styles[Self.repositoryStyle])
        #expect(emf.layoutConfiguration.isIdentity)
        #expect(eclipse.files == emf.files)
    }

    @Test("The bundled styles are listed for the help")
    func bundledStyles() {
        let entry = TemplateSet.bundledCodeStyles().first { $0.language == "java" }
        #expect(entry?.styles == [Self.defaultStyle, Self.repositoryStyle].sorted())
        #expect(entry?.defaultStyle == Self.defaultStyle)
    }

    @Test("A descriptor without styles decodes and offers no layout")
    func descriptorWithoutStyles() throws {
        let json = #"{"name": "plain", "mainModule": "m", "mainTemplate": "t"}"#
        let descriptor = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(json.utf8))
        #expect(descriptor.styles.isEmpty)
        #expect(descriptor.defaultStyle == nil)
        #expect(try descriptor.layoutConfiguration(forStyle: nil) == nil)
    }

    @Test("A style maps onto a layout configuration, with missing members at their defaults")
    func styleMapsToLayout() throws {
        let json = """
            {"name": "plain", "mainModule": "m", "mainTemplate": "t",
             "styles": {
               "wide": {"sourceIndent": "  ", "targetIndent": "    ", "openerPlacement": "sameLine",
                        "files": ["*.src"], "openerToken": "(", "lineComments": ["--"],
                        "blockComments": [{"start": "<<", "end": ">>"}], "quotes": "\\"",
                        "terminators": ".;"},
               "bare": {}
             },
             "defaultStyle": "bare"}
            """
        let descriptor = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(json.utf8))
        let wide = try #require(try descriptor.layoutConfiguration(forStyle: "wide"))
        #expect(wide.sourceIndent == "  ")
        #expect(wide.targetIndent == "    ")
        #expect(wide.openerPlacement == .sameLine)
        #expect(wide.filePatterns == ["*.src"])
        #expect(wide.syntax.opener == "(")
        #expect(wide.syntax.lineComments == ["--"])
        #expect(wide.syntax.blockComments == [.init(start: "<<", end: ">>")])
        #expect(wide.syntax.quotes == ["\""])
        #expect(wide.syntax.terminators == [".", ";"])
        let bare = try #require(try descriptor.layoutConfiguration(forStyle: nil))
        #expect(bare == MTLLayoutConfiguration())
        #expect(bare.isIdentity)
    }

    @Test("An unknown style is reported with the styles that exist")
    func unknownStyleInDescriptor() throws {
        let json = #"{"name": "plain", "mainModule": "m", "mainTemplate": "t", "styles": {"b": {}, "a": {}}}"#
        let descriptor = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(json.utf8))
        #expect(throws: GenerationError.unknownCodeStyle("c", "plain", ["a", "b"])) {
            try descriptor.layoutConfiguration(forStyle: "c")
        }
        let message = GenerationError.unknownCodeStyle("c", "plain", ["a", "b"]).description
        #expect(message.contains("'c'") && message.contains("a, b") && message.contains("plain"))
        #expect(GenerationError.unknownCodeStyle("c", "plain", []).description.hasSuffix("none"))
    }

    @Test("A default style that is not declared makes the descriptor invalid")
    func undeclaredDefaultStyle() {
        let json = #"{"name": "plain", "mainModule": "m", "mainTemplate": "t", "styles": {}, "defaultStyle": "x"}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(json.utf8))
        }
    }

    @Test("An opener token of more than one character makes the descriptor invalid")
    func invalidOpenerToken() {
        let json = #"{"name": "p", "mainModule": "m", "mainTemplate": "t", "styles": {"s": {"openerToken": "{{"}}}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(json.utf8))
        }
    }

    // MARK: - Pipeline

    @Test("A template set of any language converts its layout by a declared style")
    @MainActor
    func customLanguageStyle() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.libraryOptions)
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"""
            {"name": "blocks", "mainModule": "main", "mainTemplate": "main",
             "styles": {"tidy": {"sourceIndent": "  ", "targetIndent": "\t", "openerPlacement": "sameLine",
                                 "files": ["*.blk"]}},
             "defaultStyle": "tidy"}
            """#, to: "blocks/templateset.json")
        try scratch.write(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('one.blk')]
            outer
            {
              inner
              {
                body;
              }
            }
            [/file]
            [file ('two.txt')]
            outer
            {
              body;
            }
            [/file]
            [/template]
            """, to: "blocks/main.mtl")
        let paths = GenerationOptions(templatePaths: [scratch.url])
        try await generated.generate(language: "blocks", options: paths)
        #expect(try generated.text("one.blk") == "outer {\n\tinner {\n\t\tbody;\n\t}\n}\n")
        #expect(try generated.text("two.txt") == "outer\n{\n  body;\n}\n")

        try FileManager.default.removeItem(at: generated.output)
        var untidy = paths
        untidy.codeStyle = "tidy"
        try await generated.generate(language: "blocks", options: untidy)
        #expect(try generated.text("one.blk") == "outer {\n\tinner {\n\t\tbody;\n\t}\n}\n")

        untidy.codeStyle = "other"
        await #expect(throws: GenerationError.unknownCodeStyle("other", "blocks", ["tidy"])) {
            try await generated.generate(language: "blocks", options: untidy)
        }
    }

    @Test("A style requested of a template set without styles is rejected before anything is written")
    @MainActor
    func setWithoutStyles() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.libraryOptions)
        let scratch = try ScratchDirectory()
        defer {
            generated.remove()
            scratch.remove()
        }
        try scratch.write(
            #"{"name": "plain", "mainModule": "main", "mainTemplate": "main"}"#, to: "plain/templateset.json")
        try scratch.write(
            """
            [module main('http://www.eclipse.org/emf/2002/GenModel')/]
            [template public main(genModel : GenModel)]
            [file ('one.txt')]
            {
              body
            }
            [/file]
            [/template]
            """, to: "plain/main.mtl")
        var options = GenerationOptions(templatePaths: [scratch.url])
        try await generated.generate(language: "plain", options: options)
        #expect(try generated.text("one.txt") == "{\n  body\n}\n")
        try FileManager.default.removeItem(at: generated.output)

        options.codeStyle = Self.defaultStyle
        await #expect(throws: GenerationError.unknownCodeStyle(Self.defaultStyle, "plain", [])) {
            try await generated.generate(language: "plain", options: options)
        }
        #expect(!FileManager.default.fileExists(atPath: generated.output.path))
    }

    @Test("An unknown style is reported with the available styles before anything is written")
    @MainActor
    func unknownStyle() async throws {
        let generated = try await GeneratedProject.make("library", stem: "library", options: Self.libraryOptions)
        defer { generated.remove() }
        let expected = GenerationError.unknownCodeStyle("tabs", "java", [Self.defaultStyle, Self.repositoryStyle].sorted())
        await #expect(throws: expected) {
            try await generated.generate(options: GenerationOptions(codeStyle: "tabs"))
        }
        #expect(!FileManager.default.fileExists(atPath: generated.output.path))
    }

    // MARK: - Layout of the generated Java

    @Test("The default style is eclipse: tabs and the opening brace on the preceding line")
    @MainActor
    func defaultIsEclipse() async throws {
        let defaulted = try await Self.library(style: nil)
        let explicit = try await Self.library(style: Self.defaultStyle)
        defer {
            defaulted.remove()
            explicit.remove()
        }
        #expect(defaulted.generatedPaths() == explicit.generatedPaths())
        for path in defaulted.generatedPaths() where path.hasSuffix(".java") {
            let text = try defaulted.text(path)
            #expect(text == (try explicit.text(path)), "\(path) differs between the default and eclipse")
            #expect(Self.ownLineOpeners(text).isEmpty, "\(path) has an opening brace on its own line")
            #expect(Self.spaceIndented(text).isEmpty, "\(path) has lines indented with spaces")
            #expect(!Self.tabIndented(text).isEmpty || text.split(separator: "\n").count < 12, "\(path) has no tabs")
        }
        let text = try defaulted.text(Self.bookCategory)
        #expect(text.contains("public enum BookCategory implements Enumerator {\n"))
        #expect(text.contains("\n\t/**\n\t * The '<em><b>"))
    }

    @Test("The emf style keeps two-space indentation and braces on their own line")
    @MainActor
    func repositoryStyleLayout() async throws {
        let generated = try await Self.library(style: Self.repositoryStyle)
        defer { generated.remove() }
        let text = try generated.text(Self.bookCategory)
        #expect(text.contains("public enum BookCategory implements Enumerator\n{\n"))
        #expect(text.contains("\n  /**\n   * The '<em><b>"))
        for path in generated.generatedPaths() where path.hasSuffix(".java") {
            #expect(Self.tabIndented(try generated.text(path)).isEmpty, "\(path) has tabs")
        }
    }

    @Test("The styles differ only in whitespace, token for token", arguments: bothStyleFixtures)
    @MainActor
    func stylesDifferOnlyInWhitespace(_ fixture: String) async throws {
        let golden = try #require(JavaGoldenCase.all.first { $0.fixture == fixture })
        let generate = { (style: String) async throws -> GeneratedProject in
            let generated = try await GeneratedProject.make(golden.fixture, stem: golden.stem, options: golden.options)
            try await generated.generate(options: GenerationOptions(codeStyle: style))
            return generated
        }
        let eclipse = try await generate(Self.defaultStyle)
        let emf = try await generate(Self.repositoryStyle)
        defer {
            eclipse.remove()
            emf.remove()
        }
        #expect(eclipse.generatedPaths() == emf.generatedPaths())
        var differing = 0
        for path in eclipse.generatedPaths() where path.hasSuffix(".java") {
            let tabbed = try eclipse.text(path)
            let spaced = try emf.text(path)
            #expect(Self.tokens(tabbed) == Self.tokens(spaced), "\(path) differs beyond whitespace")
            if tabbed != spaced { differing += 1 }
        }
        #expect(differing > 0)
    }

    @Test("The reviewed expectations of the emf style match", arguments: bothStyleFixtures)
    @MainActor
    func repositoryStyleGoldenFiles(_ fixture: String) async throws {
        let golden = try #require(JavaGoldenCase.all.first { $0.fixture == fixture })
        let generated = try await GeneratedProject.make(golden.fixture, stem: golden.stem, options: golden.options)
        defer { generated.remove() }
        try await generated.generate(options: GenerationOptions(codeStyle: Self.repositoryStyle))
        let missing = Set(golden.allFiles).subtracting(generated.generatedPaths())
        #expect(missing.isEmpty, "missing generated files: \(missing.sorted())")
        for path in golden.allFiles {
            try GoldenFiles.check(
                try generated.text(path), against: "\(fixture)/\(Self.repositoryExpectationFolder)/\(path)", path)
        }
    }

    @Test("Files that are not Java are written the same in every style")
    @MainActor
    func otherFilesAreUnchanged() async throws {
        let generate = { (style: String) async throws -> GeneratedProject in
            let generated = try await GeneratedProject.make("library", stem: "library", options: Self.libraryOptions)
            try await generated.generate(options: GenerationOptions(includeSourceRoot: true, codeStyle: style))
            return generated
        }
        let eclipse = try await generate(Self.defaultStyle)
        let emf = try await generate(Self.repositoryStyle)
        defer {
            eclipse.remove()
            emf.remove()
        }
        let others = eclipse.generatedPaths().filter { !$0.hasSuffix(".java") }
        #expect(!others.isEmpty)
        for path in others { #expect(try eclipse.text(path) == (try emf.text(path)), "\(path) differs") }
    }

    // MARK: - Regeneration

    /// Marks a method as maintained by hand and gives it another body, without changing its layout.
    static func editByHand(_ text: String) -> String {
        JavaRegenerationTests.editByHand(text)
    }

    @Test("A member marked as not generated survives regeneration in either style", arguments: [defaultStyle, repositoryStyle])
    @MainActor
    func keepsHandEditsInStyle(_ style: String) async throws {
        let generated = try await Self.library(style: style)
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        let edited = Self.editByHand(original)
        #expect(edited != original)
        try edited.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(codeStyle: style))
        #expect(try generated.text(Self.bookCategory) == edited)
    }

    @Test("A damaged generated member is regenerated in the style of the tree", arguments: [defaultStyle, repositoryStyle])
    @MainActor
    func regeneratesDamagedMembers(_ style: String) async throws {
        let generated = try await Self.library(style: style)
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        let damaged = original.replacingOccurrences(of: "return literal;", with: "return \"damaged\";")
        #expect(damaged != original)
        try damaged.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(codeStyle: style))
        #expect(try generated.text(Self.bookCategory) == original)
    }

    @Test("Regenerating in the same style leaves unchanged files alone", arguments: [defaultStyle, repositoryStyle])
    @MainActor
    func regenerationIsStable(_ style: String) async throws {
        let generated = try await Self.library(style: style)
        defer { generated.remove() }
        let before = try generated.generatedPaths().map { try generated.text($0) }
        try await generated.generate(options: GenerationOptions(codeStyle: style))
        #expect(try generated.generatedPaths().map { try generated.text($0) } == before)
    }

    @Test(
        "Switching the style of an existing tree regenerates generated members and keeps the others as they are",
        arguments: [(defaultStyle, repositoryStyle), (repositoryStyle, defaultStyle)])
    @MainActor
    func switchingStyles(from: String, to: String) async throws {
        let generated = try await Self.library(style: from)
        defer { generated.remove() }
        let original = try generated.text(Self.bookCategory)
        let edited = Self.editByHand(original)
        try edited.write(to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)

        try await generated.generate(options: GenerationOptions(codeStyle: to))
        let switched = try generated.text(Self.bookCategory)

        let reference = try await Self.library(style: to)
        defer { reference.remove() }
        let fresh = try reference.text(Self.bookCategory)
        #expect(Self.tokens(switched) == Self.tokens(edited), "no member is lost or duplicated")
        #expect(switched != edited, "generated members take the new layout")
        #expect(switched != fresh, "the member kept by hand keeps its layout")
        let keptLine = "if (result.getName().equalsIgnoreCase(name))"
        let kept = try #require(switched.range(of: keptLine))
        let lineStart = switched[..<kept.lowerBound].lastIndex(of: "\n").map { switched.index(after: $0) } ?? switched.startIndex
        let fromIndent = to == Self.defaultStyle ? "    " : "\t"
        #expect(switched[lineStart...].hasPrefix(fromIndent), "the kept member is still in the old style")

        // Files that were not edited take the new style, and none loses or duplicates a member.
        for path in reference.generatedPaths() where path.hasSuffix(".java") && path != Self.bookCategory {
            #expect(Self.tokens(try generated.text(path)) == Self.tokens(try reference.text(path)), "\(path)")
        }
        for path in Self.unmixedFiles {
            #expect(try generated.text(path) == (try reference.text(path)), "\(path) takes the new style")
        }
    }

    @Test("Forcing the overwrite after switching the style converts the whole tree", arguments: [(defaultStyle, repositoryStyle)])
    @MainActor
    func forcedSwitch(from: String, to: String) async throws {
        let generated = try await Self.library(style: from)
        defer { generated.remove() }
        try Self.editByHand(try generated.text(Self.bookCategory)).write(
            to: generated.file(Self.bookCategory), atomically: true, encoding: .utf8)
        try await generated.generate(options: GenerationOptions(forceOverwrite: true, codeStyle: to))
        let reference = try await Self.library(style: to)
        defer { reference.remove() }
        for path in reference.generatedPaths() {
            #expect(try generated.text(path) == (try reference.text(path)), "\(path) differs")
        }
    }
}
