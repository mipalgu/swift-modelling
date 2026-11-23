//
// ATLTutorialConsistencyTests.swift
// TutorialTests
//
// Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

/// Checks that the ATL command-line tutorials say what their code does.
///
/// These tests compare what a tutorial claims, through the names under which it saves files, the
/// types that its helpers declare and the results that its steps describe, with what the modules
/// do when swift-atl runs them on the sample models of the tutorials.
@Suite("ATL Tutorials: Consistency of claims and code")
struct ATLTutorialConsistencyTests {
    /// The shared checks of the tutorials that show their metamodels.
    typealias Checks = ATL03to05ExecutionTests

    /// The numbers of the ATL command-line tutorials whose resources are in a directory of their own.
    static let tutorialNumbers = 2...8

    /// The pattern of the file name of an ATL command-line tutorial, which captures its number.
    static let tutorialFilePattern = #"^ATL-(\d\d)-.*\.tutorial$"#

    /// The extension of an ATL module or query file.
    static let atlExtension = ".atl"

    /// The keyword that starts the header of a module.
    static let moduleKeyword = "module "

    /// The keyword that starts a query unit.
    static let queryKeyword = "query "

    /// The keyword that starts the line naming the models of a module.
    static let createKeyword = "create "

    /// The ATL command-line tutorial files, each with its number.
    ///
    /// - Returns: The file names of the tutorials and their numbers, in number order.
    /// - Throws: An error if the tutorial directory cannot be read.
    static func tutorialFiles() throws -> [(file: String, number: Int)] {
        let pattern = try NSRegularExpression(pattern: tutorialFilePattern)
        return try FileManager.default.contentsOfDirectory(atPath: Checks.tutorialsPath.path).compactMap { file in
            let range = NSRange(location: 0, length: (file as NSString).length)
            guard let match = pattern.firstMatch(in: file, range: range),
                let number = Int((file as NSString).substring(with: match.range(at: 1)))
            else { return nil }
            return (file, number)
        }.sorted { $0.number < $1.number }
    }

    /// The captured groups of every match of a pattern in a text.
    ///
    /// - Parameters:
    ///   - pattern: A regular expression with capture groups.
    ///   - text: The text to search.
    /// - Returns: For each match, the text of each capture group in order, which is empty for an
    ///   optional group that did not take part in the match.
    /// - Throws: An error if the pattern is invalid.
    static func captures(of pattern: String, in text: String) throws -> [[String]] {
        let expression = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let nsText = text as NSString
        return expression.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map { match in
            (1..<match.numberOfRanges).map {
                let range = match.range(at: $0)
                return range.location == NSNotFound ? "" : nsText.substring(with: range)
            }
        }
    }

    /// The name of the module or query that an ATL file defines, with its header.
    ///
    /// - Parameter text: The text of the file.
    /// - Returns: The name and the `create` line of a module, or the name and the keyword of a
    ///   query, or `nil` for a file that defines neither, such as an excerpt.
    static func unit(in text: String) -> (name: String, header: String)? {
        let lines = Checks.lines(of: text)
        func name(after keyword: String, in line: String) -> String {
            String(line.dropFirst(keyword.count).prefix { $0.isLetter || $0.isNumber || $0 == "_" })
        }
        if let module = lines.first(where: { $0.hasPrefix(moduleKeyword) }) {
            let header = lines.first { $0.hasPrefix(createKeyword) } ?? ""
            return (name(after: moduleKeyword, in: module), header)
        }
        if let query = lines.first(where: { $0.hasPrefix(queryKeyword) }) {
            return (name(after: queryKeyword, in: query), queryKeyword)
        }
        return nil
    }

    // MARK: - File names of modules

    @Test("Tutorial: Every ATL file that a tutorial saves is named after its module, and each name holds one module")
    func testModuleFileNames() throws {
        let tutorials = try Self.tutorialFiles()
        #expect(tutorials.map(\.number) == Array(Self.tutorialNumbers))
        for tutorial in tutorials {
            let text = try String(
                contentsOf: Checks.tutorialsPath.appendingPathComponent(tutorial.file), encoding: .utf8)
            var headers: [String: Set<String>] = [:]
            for code in TutorialCatalogue.codes(in: text) where code.name.hasSuffix(Self.atlExtension) {
                let atl = try Checks.text(of: code.file, in: tutorial.number)
                guard let unit = Self.unit(in: atl) else { continue }
                #expect(
                    code.name == unit.name + Self.atlExtension,
                    "\(tutorial.file): \(code.file) defines \(unit.name), but is saved as \(code.name)")
                headers[code.name, default: []].insert(unit.header)
            }
            for (name, found) in headers {
                #expect(found.count == 1, "\(tutorial.file) saves modules with different models as \(name): \(found)")
            }
        }
    }

    // MARK: - Declared collection types

    /// A tutorial whose helpers are evaluated on its sample model.
    struct HelperTutorial: Sendable, CustomTestStringConvertible {
        /// The tutorial and its metamodels.
        let metamodel: Checks.TargetMetamodel

        /// The name of the source metamodel, as the `-- @path` directives give it.
        let sourceMetamodelName: String

        var testDescription: String { metamodel.tutorialFile }
    }

    /// The tutorials whose helpers declare collection types, with their source metamodels.
    static let helperTutorials = [
        HelperTutorial(metamodel: Checks.targetMetamodels[0], sourceMetamodelName: "University"),
        HelperTutorial(metamodel: Checks.targetMetamodels[1], sourceMetamodelName: "Organisation"),
        HelperTutorial(metamodel: ATL02to08Tests.metamodels[1], sourceMetamodelName: "Source"),
        HelperTutorial(metamodel: ATL02to08Tests.metamodels[2], sourceMetamodelName: "Source"),
    ]

    /// The pattern of a helper without parameters that declares a collection type. It captures the
    /// context class, the name, the parentheses of an operation helper and the kind of collection.
    static let collectionHelperPattern =
        #"^helper context \w+!(\w+) def: (\w+)(\(\))?\s*:\s*(Sequence|OrderedSet|Set|Bag)\("#

    @Test("CLI: Every collection type that a helper declares is the kind of collection it returns", arguments: helperTutorials)
    @MainActor
    func testDeclaredCollectionKinds(_ tutorial: HelperTutorial) async throws {
        let metamodel = tutorial.metamodel
        let workspace = try Checks.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Checks.copy(
            [
                (resource: metamodel.sourceFile, name: metamodel.sourceName),
                (resource: metamodel.sampleFile, name: metamodel.sampleName),
            ], of: metamodel.tutorial, to: workspace)
        var checked = 0
        for module in Checks.modules(of: metamodel.tutorial) {
            let text = try Checks.text(of: module, in: metamodel.tutorial)
            let parts = ATL02to08Tests.helperLines(of: text)
            let sourceDirective = try #require(parts.directives.first { $0.contains(" \(tutorial.sourceMetamodelName)=") })
            for helper in try Self.captures(of: Self.collectionHelperPattern, in: text) {
                let (context, name, call, declared) = (helper[0], helper[1], helper[2], helper[3])
                let expression =
                    "\(tutorial.sourceMetamodelName)!\(context).allInstances()->first().\(name)\(call)->oclType()"
                let unit = ([sourceDirective, "", "query DeclaredKind = \(expression);"] + parts.helpers)
                    .joined(separator: "\n")
                let result = try await Checks.query(
                    unit, arguments: ["--source", metamodel.sampleName], in: workspace)
                #expect(result.succeeded, "\(module): \(name): \(result.stdout)\(result.stderr)")
                #expect(Checks.lines(of: result.stdout) == [declared], "\(module): \(name) declares \(declared)")
                checked += 1
            }
        }
        #expect(checked > 0)
    }

    // MARK: - Tutorial 06: the robust transformation

    /// The tutorial on debugging and its metamodels.
    static let debugging = ATL02to08Tests.metamodels[1]

    /// The robust transformation of the tutorial on debugging.
    static let robustTransformation = "atl-06-step-16-robust-transformation.atl"

    /// The model that the robust transformation writes, as the tutorial shows it.
    static let robustTarget = "atl-06-step-18-target.xmi"

    @Test("CLI: The robust transformation of tutorial 06 names every Item after its own element")
    @MainActor
    func testRobustTransformationNames() async throws {
        let metamodel = Self.debugging
        let workspace = try Checks.makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try Checks.copy(
            [
                (resource: metamodel.sourceFile, name: metamodel.sourceName),
                (resource: metamodel.targetFile, name: metamodel.targetName),
                (resource: Self.robustTransformation, name: metamodel.transformationName),
                (resource: metamodel.sampleFile, name: metamodel.sampleName),
            ], of: metamodel.tutorial, to: workspace)
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl",
            arguments: [
                "transform", metamodel.transformationName, "--source", "IN=\(metamodel.sampleName)",
                "--target", "OUT=target.xmi",
            ], in: workspace)
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let sample = try Checks.text(of: metamodel.sampleFile, in: metamodel.tutorial)
        let elementNames = try Self.captures(of: #"<elements name="([^"]+)""#, in: sample).map { $0[0] }
        #expect(elementNames.count == 3)
        let written = try String(contentsOf: workspace.appendingPathComponent("target.xmi"), encoding: .utf8)
        let shown = try Checks.text(of: Self.robustTarget, in: metamodel.tutorial)
        for target in [written, shown] {
            let itemNames = try Self.captures(of: #"<tgt:Item name="([^"]+)""#, in: target).map { $0[0] }
            #expect(itemNames == elementNames)
        }
    }

    @Test("Content: No helper of tutorial 06 tests a many-valued reference for being undefined")
    func testNoUndefinedCollectionChecks() throws {
        let metamodel = Self.debugging
        let ecore = try Checks.text(of: metamodel.sourceFile, in: metamodel.tutorial)
        let manyValued = try Self.captures(of: #"name="(\w+)" upperBound="-1""#, in: ecore).map { $0[0] }
        #expect(Set(manyValued) == ["elements", "children", "items"])
        for file in Checks.atlFiles(in: Checks.directory(of: metamodel.tutorial)) {
            let text = try Checks.text(of: file, in: metamodel.tutorial)
            for feature in manyValued {
                #expect(!text.contains(".\(feature).oclIsUndefined()"), "\(file) tests \(feature) for being undefined")
            }
        }
    }

    // MARK: - Tutorial 07: the rule that combines two source models

    /// The scenario of the tutorial on complex transformations with two source models.
    static var multipleSources: ATL02to08Tests.Scenario { ATL02to08Tests.scenarios[1] }

    /// The complete module of the scenario with two source models.
    static let combiningModule = "atl-07-step-14-complete-multi-model.atl"

    /// The guard of the rule that combines the two source models.
    static let combiningGuard = " (b.refId = a.id)"

    /// The pattern of a Combined element of a written model, which captures its two names.
    static let combinedPattern = #"<mtg:Combined nameA="([^"]+)" nameB="([^"]+)""#

    /// Runs a version of the combining module on the two sample models.
    ///
    /// - Parameter module: The text of the module.
    /// - Returns: The pairs of names of the Combined elements that the run wrote.
    /// - Throws: An error if a file cannot be prepared or read or the tool cannot be run.
    @MainActor
    static func combinedPairs(running module: String) async throws -> [[String]] {
        let scenario = multipleSources
        let workspace = try ATL02to08Tests.complexWorkspace(for: scenario, module: combiningModule)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try module.write(
            to: workspace.appendingPathComponent(scenario.transformationName), atomically: true, encoding: .utf8)
        let bindings = scenario.sources.flatMap { [Checks.sourceOption, $0.argument] }
            + scenario.targets.flatMap { [Checks.targetOption, $0.argument] }
        let result = try await ATLAdvanced02Tests.execute(
            tool: "swift-atl", arguments: ["transform", scenario.transformationName] + bindings, in: workspace)
        #expect(result.succeeded, "\(result.stdout)\(result.stderr)")
        let target = try #require(scenario.targets.first)
        let written = try String(contentsOf: workspace.appendingPathComponent(target.shown.name), encoding: .utf8)
        return try captures(of: combinedPattern, in: written)
    }

    @Test("CLI: The combining rule of tutorial 07 pairs each ElementB with the ElementA it refers to, and only those")
    @MainActor
    func testCombiningRulePairs() async throws {
        let scenario = Self.multipleSources
        let modelA = try Checks.text(of: scenario.sources[0].shown.file, in: ATL02to08Tests.complexTutorial)
        let modelB = try Checks.text(of: scenario.sources[1].shown.file, in: ATL02to08Tests.complexTutorial)
        let rooms = try Self.captures(of: #"name="([^"]+)" id="(\d+)""#, in: modelA)
        let materials = try Self.captures(of: #"name="([^"]+)" refId="(\d+)""#, in: modelB)
        let related = rooms.flatMap { room in materials.filter { $0[1] == room[1] }.map { [room[0], $0[0]] } }
        #expect(related.count == materials.count)
        let module = try Checks.text(of: Self.combiningModule, in: ATL02to08Tests.complexTutorial)
        #expect(module.contains(Self.combiningGuard))
        #expect(try await Self.combinedPairs(running: module) == related)
        let shown = try Checks.text(of: scenario.targets[0].shown.file, in: ATL02to08Tests.complexTutorial)
        #expect(try Self.captures(of: Self.combinedPattern, in: shown) == related)
        let unguarded = module.replacingOccurrences(of: Self.combiningGuard, with: "")
        #expect(try await Self.combinedPairs(running: unguarded).count == rooms.count * materials.count)
    }

    // MARK: - Captions that name the operations of their code

    /// A step whose caption names helpers and operations that its code must use.
    struct NamedOperations: Sendable, CustomTestStringConvertible {
        /// The number of the tutorial.
        let tutorial: Int

        /// The tutorial file.
        let tutorialFile: String

        /// The resource that the step shows.
        let file: String

        var testDescription: String { file }
    }

    /// The steps whose captions describe what their code calls.
    static let namedOperations = [
        NamedOperations(tutorial: 5, tutorialFile: "ATL-05-ocl-expressions.tutorial", file: "atl-05-step-13-complex-collections.atl"),
        NamedOperations(tutorial: 6, tutorialFile: "ATL-06-debugging.tutorial", file: "atl-06-step-12-logging-helpers.atl"),
        NamedOperations(tutorial: 6, tutorialFile: "ATL-06-debugging.tutorial", file: "atl-06-step-13-collection-debugging.atl"),
        NamedOperations(tutorial: 6, tutorialFile: "ATL-06-debugging.tutorial", file: "atl-06-step-16-robust-transformation.atl"),
        NamedOperations(tutorial: 8, tutorialFile: "ATL-08-performance.tutorial", file: "atl-08-step-05-optimised-collections.atl"),
    ]

    @Test("Tutorial: Every helper or operation that a caption names in code font is one its code uses", arguments: namedOperations)
    func testCaptionNamesOperationsOfCode(_ step: NamedOperations) throws {
        let tutorial = try String(
            contentsOf: Checks.tutorialsPath.appendingPathComponent(step.tutorialFile), encoding: .utf8)
        let block = try #require(Checks.blocks("@Step", in: tutorial[...]).first { $0.contains("file: \(step.file))") })
        let caption = try #require(Checks.paragraphs(of: block).last)
        let names = try Self.captures(of: #"`(\w+)(?:\(\))?`"#, in: caption).map { $0[0] }
        #expect(!names.isEmpty)
        let code = try Checks.text(of: step.file, in: step.tutorial)
        for name in names {
            #expect(code.contains(name), "The caption of \(step.file) names \(name), which its code does not use")
        }
    }

    // MARK: - Tutorial 08: the optimised collection operations

    @Test("Content: The optimised helpers of tutorial 08 never filter the result of a select again")
    func testNoRepeatedSelect() throws {
        let tutorial = ATL02to08Tests.metamodels[2].tutorial
        let optimised = Checks.atlFiles(in: Checks.directory(of: tutorial)).filter { !$0.contains("inefficient") }
        #expect(optimised.contains("atl-08-step-05-optimised-collections.atl"))
        for file in optimised {
            let text = try Checks.text(of: file, in: tutorial)
            #expect(try Self.captures(of: #"(->select\([^\n]*\)\s*->select\()"#, in: text).isEmpty, "\(file)")
        }
    }
}
