//
// EndToEndTests.swift
// swift-xtend-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import swift_xtend

/// Runs the built swift-xtend executable as a reader would.
@Suite("swift-xtend end to end", .serialized)
struct EndToEndTests {
    /// The arguments that load the library model with its metamodel.
    static let library = ["--model", "library.xmi", "--metamodel", "Library.ecore"]

    // MARK: - run

    @Test("run prints a string result")
    func runString() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(["run", "Report.xtend", "--method", "describe"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.output == "City Library has 3 books\n")
        }
    }

    @Test("run finds the metamodel beside nothing: it needs --metamodel to type the model")
    func runWithoutMetamodelFails() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "describe", "--model", "library.xmi"], in: directory)
            #expect(!run.succeeded)
            #expect(run.status == 1)
        }
    }

    @Test("run prints lists and numbers")
    func runCollections() async throws {
        try await withFixtures { directory in
            let titles = try await runSwiftXtend(["run", "Report.xtend", "-n", "titles"] + Self.library, in: directory)
            #expect(titles.output == "[Dune, Emma, Ulysses]\n")
            let count = try await runSwiftXtend(["run", "Report.xtend", "--method", "count"] + Self.library, in: directory)
            #expect(count.output == "3\n")
        }
    }

    @Test("run prints a model object by class and name")
    func runObject() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(["run", "Report.xtend", "--method", "firstBook"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.output == "Book(Dune)\n")
        }
    }

    @Test("run takes literal arguments of several types")
    func runLiterals() async throws {
        try await withFixtures { directory in
            let sum = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "add", "--argument", "2", "--argument", "40"], in: directory)
            #expect(sum.output == "42\n")
            let scaled = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "scale", "--argument", "1.5", "--argument", "true"], in: directory)
            #expect(scaled.output == "3.0\n")
            let greeting = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "greet", "--argument", "Ada"], in: directory)
            #expect(greeting.output == "Hello, Ada!\n")
            let filtered = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "longBooks", "--argument", "400"] + Self.library, in: directory)
            #expect(filtered.output == "[Dune, Ulysses]\n")
        }
    }

    @Test("run passes an object chosen by name, all instances, and the resource")
    func runBindings() async throws {
        try await withFixtures { directory in
            let byClass = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "pageCount", "--object", "Emma"] + Self.library, in: directory)
            #expect(byClass.output == "320\n")
            let all = try await runSwiftXtend(["run", "Report.xtend", "--method", "allBooks"] + Self.library, in: directory)
            #expect(all.output == "3\n")
            let resource = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "resourceRoots"] + Self.library, in: directory)
            #expect(resource.output == "1\n")
        }
    }

    @Test("run passes a dispatch method the first object of the common type of its cases")
    func runDispatch() async throws {
        try await withFixtures { directory in
            let first = try await runSwiftXtend(
                ["run", Fixture.labels, "--method", "label"] + Self.library, in: directory)
            #expect(first.output == "library City Library\n", "\(first.error)")
            let named = try await runSwiftXtend(
                ["run", Fixture.labels, "--method", "label", "--object", "Emma"] + Self.library, in: directory)
            #expect(named.output == "book Emma\n", "\(named.error)")
            let withArgument = try await runSwiftXtend(
                ["run", Fixture.labels, "--method", "weigh", "--argument", "2", "--object", "Dune"] + Self.library,
                in: directory)
            #expect(withArgument.output == "824\n", "\(withArgument.error)")
            let library = try await runSwiftXtend(
                ["run", Fixture.labels, "--method", "weigh", "--argument", "2"] + Self.library, in: directory)
            #expect(library.output == "6\n", "\(library.error)")
        }
    }

    @Test("run prints program output and nothing for a method without a result")
    func runPrintAndVoid() async throws {
        try await withFixtures { directory in
            let say = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "say", "--argument", "hi"], in: directory)
            #expect(say.succeeded, "\(say.error)")
            #expect(say.output.hasPrefix("hi\n"))
            let nothing = try await runSwiftXtend(["run", "Maths.xtend", "--method", "nothing"], in: directory)
            #expect(nothing.succeeded)
            #expect(nothing.output.isEmpty)
        }
    }

    @Test("run writes a changed model with --output")
    func runWritesChangedModel() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "retire", "--output", "retired.xmi"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            let text = try String(contentsOf: directory.appendingPathComponent("retired.xmi"), encoding: .utf8)
            #expect(text.contains("available=\"false\""))
            #expect(!text.contains("available=\"true\""))
            let json = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "retire", "-o", "retired.json"] + Self.library, in: directory)
            #expect(json.succeeded, "\(json.error)")
            let jsonText = try String(contentsOf: directory.appendingPathComponent("retired.json"), encoding: .utf8)
            #expect(jsonText.hasPrefix("{") || jsonText.hasPrefix("["))
        }
    }

    @Test("run reads a JSON model that it wrote, with the semantics option")
    func runJSONModel() async throws {
        try await withFixtures { directory in
            let written = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "retire", "-o", "retired.json"] + Self.library, in: directory)
            #expect(written.succeeded, "\(written.error)")
            let run = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "describe", "--model", "retired.json", "--metamodel", "Library.ecore",
                 "--semantics", "legacy"], in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.output == "City Library has 3 books\n")
        }
    }

    @Test("run writes the model that a transformation creates")
    func runTransformation() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                [
                    "run", "Transform.xtend", "--method", "toCatalogue", "--output", "catalogue.xmi",
                    "--model", "library.xmi", "--metamodel", "Library.ecore", "--metamodel", "Catalogue.ecore",
                ], in: directory)
            #expect(run.succeeded, "\(run.error)")
            let text = try String(contentsOf: directory.appendingPathComponent("catalogue.xmi"), encoding: .utf8)
            #expect(text.contains("City Library Catalogue"))
            #expect(text.contains("Ulysses"))
        }
    }

    @Test("run chooses among several classes with --class and reads --include sources")
    func runClasses() async throws {
        try await withFixtures { directory in
            let ambiguous = try await runSwiftXtend(["run", "Pair.xtend", "--method", "second"], in: directory)
            #expect(ambiguous.status == 1)
            #expect(ambiguous.error.contains("several classes"))
            let chosen = try await runSwiftXtend(
                ["run", "Pair.xtend", "--class", "Second", "--method", "second"], in: directory)
            #expect(chosen.output == "two\n")
            let included = try await runSwiftXtend(
                ["run", "Helper.xtend", "--include", "Pair.xtend", "--class", "Second", "--method", "second"], in: directory)
            #expect(included.output == "two\n")
        }
    }

    @Test("run reports bad classes, methods and arguments")
    func runErrors() async throws {
        try await withFixtures { directory in
            let badClass = try await runSwiftXtend(["run", "Pair.xtend", "--class", "Nope", "-n", "x"], in: directory)
            #expect(badClass.status == 1)
            #expect(badClass.error.contains("declares no class 'Nope'"))
            let badMethod = try await runSwiftXtend(["run", "Helper.xtend", "--method", "nope"], in: directory)
            #expect(badMethod.status == 1)
            #expect(badMethod.error.contains("declares no method 'nope'"))
            #expect(badMethod.error.contains("help"))
            let missing = try await runSwiftXtend(["run", "Maths.xtend", "--method", "add"], in: directory)
            #expect(missing.status == 1)
            #expect(missing.error.contains("--argument"))
            let invalid = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "add", "--argument", "x", "--argument", "1"], in: directory)
            #expect(invalid.status == 1)
            #expect(invalid.error.contains("not a valid int"))
            let surplus = try await runSwiftXtend(
                ["run", "Helper.xtend", "--method", "help", "--argument", "1"], in: directory)
            #expect(surplus.status == 1)
            let noModel = try await runSwiftXtend(["run", "Report.xtend", "--method", "describe", "--metamodel", "Library.ecore"], in: directory)
            #expect(noModel.status == 1)
            #expect(noModel.error.contains("--model"))
            let noObject = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "pageCount", "--object", "Nobody"] + Self.library, in: directory)
            #expect(noObject.status == 1)
            let fileSystem = try await runSwiftXtend(
                ["run", "Maths.xtend", "--method", "needsFile"], in: directory)
            #expect(fileSystem.status == 1)
            #expect(fileSystem.error.contains("generate"))
            let division = try await runSwiftXtend(["run", "Maths.xtend", "--method", "broken"], in: directory)
            #expect(division.status == 1)
            #expect(division.error.contains("divisionByZero"))
        }
    }

    @Test("run reports missing files and invalid sources")
    func runFileErrors() async throws {
        try await withFixtures { directory in
            let source = try await runSwiftXtend(["run", "Absent.xtend", "--method", "x"], in: directory)
            #expect(source.status == 1)
            #expect(source.error.contains("Xtend source file not found"))
            let model = try await runSwiftXtend(
                ["run", "Helper.xtend", "--method", "help", "--model", "absent.xmi"], in: directory)
            #expect(model.status == 1)
            #expect(model.error.contains("Model file not found"))
            let wrong = try await runSwiftXtend(["run", "Wrong.xtend", "--method", "broken"], in: directory)
            #expect(wrong.status == 1)
            #expect(wrong.error.contains("error"))
            #expect(wrong.error.contains("Wrong.xtend"))
        }
    }

    @Test("Source encodings: fallback warning, explicit encoding and malformed input")
    func encodings() async throws {
        try await withFixtures { directory in
            let utf8 = try await runSwiftXtend(["run", "Escape.xtend", "--method", "greet"], in: directory)
            #expect(utf8.output == "Grüße\n")
            #expect(!utf8.error.contains("warning"))
            let fallback = try await runSwiftXtend(["run", "Latin.xtend", "--method", "greet"], in: directory)
            #expect(fallback.succeeded, "\(fallback.error)")
            #expect(fallback.output == "Grüße\n")
            #expect(fallback.error.contains("ISO-8859-1"))
            let explicit = try await runSwiftXtend(
                ["run", "Latin.xtend", "--method", "greet", "--encoding", "latin1"], in: directory)
            #expect(explicit.output == "Grüße\n")
            #expect(explicit.error.isEmpty)
            let wrong = try await runSwiftXtend(
                ["run", "Latin.xtend", "--method", "greet", "--encoding", "utf-8"], in: directory)
            #expect(wrong.status == 1)
        }
    }

    @Test("--verbose reports progress on standard error only")
    func verbose() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["run", "Report.xtend", "--method", "count", "--verbose"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.output == "3\n")
            #expect(run.error.contains("Loading model library.xmi"))
            #expect(run.error.contains("Calling Report.count"))
        }
    }

    // MARK: - generate

    @Test("generate writes files and lists them")
    func generate() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "--output", "out", "--output-configuration", "docs=documents"]
                    + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            let dune = try String(contentsOf: directory.appendingPathComponent("out/Dune.txt"), encoding: .utf8)
            #expect(dune == "Title: Dune\nPages: 412\n")
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("out/Ulysses.txt").path))
            let index = try String(contentsOf: directory.appendingPathComponent("documents/index.txt"), encoding: .utf8)
            #expect(index == "Index of books")
            let lines = run.output.split(separator: "\n").map(String.init)
            #expect(lines.contains("Generated the catalogue"))
            #expect(lines.contains("out/Dune.txt"))
            #expect(lines.contains("docs:documents/index.txt"))
        }
    }

    @Test("generate --quiet lists nothing and --class chooses the generator")
    func generateQuietAndClass() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "-q", "-o", "out", "--output-configuration", "docs=out/docs",
                 "--class", "Catalogue"] + Self.library, in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.output == "Generated the catalogue\n")
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("out/docs/index.txt").path))
        }
    }

    @Test("generate uses the first class with a generator method when several classes are declared")
    func generateAmongSeveralClasses() async throws {
        try await withFixtures { directory in
            let included = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "--include", "Helper.xtend", "-o", "out",
                 "--output-configuration", "docs=out/docs"] + Self.library, in: directory)
            #expect(included.succeeded, "\(included.error)")
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("out/Dune.txt").path))
            let helperFirst = try await runSwiftXtend(
                ["generate", "Helper.xtend", "--include", "Catalogue.xtend", "-o", "second",
                 "--output-configuration", "docs=second/docs", "--verbose"] + Self.library, in: directory)
            #expect(helperFirst.succeeded, "\(helperFirst.error)")
            #expect(helperFirst.error.contains("Running Catalogue"))
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("second/docs/index.txt").path))
            let noGenerator = try await runSwiftXtend(
                ["generate", "Pair.xtend", "--include", "Helper.xtend", "-o", "none"] + Self.library, in: directory)
            #expect(noGenerator.status == 1)
            #expect(noGenerator.error.contains("No generator class"))
            #expect(!noGenerator.error.contains("several classes"))
        }
    }

    @Test("generate fails for an unmapped output configuration")
    func generateUnmappedConfiguration() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(["generate", "Catalogue.xtend", "--output", "out"] + Self.library, in: directory)
            #expect(run.status == 1)
            #expect(run.error.contains("Unknown output configuration 'docs'"))
        }
    }

    @Test("generate reports a source without a generator and a wrong class")
    func generateErrors() async throws {
        try await withFixtures { directory in
            let none = try await runSwiftXtend(
                ["generate", "Helper.xtend", "--output", "out"] + Self.library, in: directory)
            #expect(none.status == 1)
            #expect(none.error.contains("No generator class"))
            let wrongClass = try await runSwiftXtend(
                ["generate", "Pair.xtend", "--class", "Nope", "--output", "out"] + Self.library, in: directory)
            #expect(wrongClass.status == 1)
            #expect(wrongClass.error.contains("declares no class 'Nope'"))
            let missing = try await runSwiftXtend(
                ["generate", "Absent.xtend", "--output", "out"] + Self.library, in: directory)
            #expect(missing.status == 1)
        }
    }

    @Test("generate validates its command line with status 64")
    func generateValidation() async throws {
        try await withFixtures { directory in
            let noModel = try await runSwiftXtend(["generate", "Catalogue.xtend", "--output", "out"], in: directory)
            #expect(noModel.status == 64)
            #expect(noModel.error.contains("--model"))
            let noOutput = try await runSwiftXtend(["generate", "Catalogue.xtend"] + Self.library, in: directory)
            #expect(noOutput.status == 64)
            let badConfiguration = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "-o", "out", "--output-configuration", "docs"] + Self.library, in: directory)
            #expect(badConfiguration.status == 64)
            #expect(badConfiguration.error.contains("name=value"))
            let both = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "-o", "out", "-q", "-v"] + Self.library, in: directory)
            #expect(both.status == 64)
        }
    }

    @Test("generate --verbose reports each file on standard error")
    func generateVerbose() async throws {
        try await withFixtures { directory in
            let run = try await runSwiftXtend(
                ["generate", "Catalogue.xtend", "-v", "-o", "out", "--output-configuration", "docs=out"] + Self.library,
                in: directory)
            #expect(run.succeeded, "\(run.error)")
            #expect(run.error.contains("Running Catalogue"))
            #expect(run.error.contains("Dune.txt (1 files)"))
            #expect(!run.output.contains("files)"))
        }
    }

    // MARK: - help and usage

    @Test("Help and version texts")
    func help() async throws {
        let main = try await runSwiftXtend(["--help"])
        #expect(main.succeeded)
        #expect(main.output.contains("run"))
        #expect(main.output.contains("generate"))
        let run = try await runSwiftXtend(["run", "--help"])
        #expect(run.succeeded)
        for option in ["--method", "--argument", "--object", "--output", "--model", "--metamodel", "--class", "--include", "--encoding", "--verbose"] {
            #expect(run.output.contains(option), "run help lacks \(option)")
        }
        #expect(run.output.contains("Exit status"))
        let generate = try await runSwiftXtend(["generate", "--help"])
        #expect(generate.succeeded)
        for option in ["--output-configuration", "--output", "--quiet", "--class", "--model"] {
            #expect(generate.output.contains(option), "generate help lacks \(option)")
        }
        let version = try await runSwiftXtend(["--version"])
        #expect(version.output == SwiftXtendVocabulary.version + "\n")
        #expect(!(main.output + run.output + generate.output).contains("\u{2014}"))
    }

    @Test("A command line that is wrong has status 64")
    func usage() async throws {
        let noMethod = try await runSwiftXtend(["run", "Report.xtend"])
        #expect(noMethod.status == 64)
        let unknown = try await runSwiftXtend(["bogus"])
        #expect(unknown.status == 64)
        let noCommand = try await runSwiftXtend([])
        #expect(noCommand.status == 0 || noCommand.status == 64)
    }
}
