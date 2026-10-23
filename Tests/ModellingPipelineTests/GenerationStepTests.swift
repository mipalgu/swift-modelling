//
// GenerationStepTests.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import EMFBase
import Foundation
import MTL
import ModellingGenerators
import ModellingPipeline
import Synchronization
import Testing

@Suite("GenerationStep - MTL runs on models in memory")
@MainActor
struct GenerationStepTests {
    /// Writes a module and returns its location.
    private func module(_ text: String, named name: String = "Main", in fixture: PipelineFixture) throws -> URL {
        let url = fixture.directory.appendingPathComponent("modules/\(name).mtl")
        try fixture.write(text, to: url)
        return url
    }

    /// A service provider with one standalone service, `twice(text)`.
    struct TwiceServices: AQLServiceProvider {
        var services: [AQLService] {
            [AQLService("twice", receiver: .standalone, arity: 1) { call in
                let text = try call.string(0)
                return text + text
            }]
        }
    }

    @Test("runs a module with parameters, services and standard output")
    func runsModule() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let main = try module(
            """
            [module Main('http://example.com')]
            [template public main()]
            [file ('out/a.txt')][twice(name)/] [parameter('count')/][/file]
            outside
            [/template]
            """, in: fixture)
        let output = fixture.directory.appendingPathComponent("generated")

        let collector = ReportCollector()
        let step = GenerationStep(
            templates: .module(main, mainTemplate: "main"), parameters: ["name": "ab", "count": 3],
            serviceProviders: [TwiceServices()], outputDirectory: output)
        let result = try await step.run(arguments: [], progress: { collector.receive($0) })
        let reports = collector.messages

        let file = output.appendingPathComponent("out/a.txt").standardizedFileURL
        #expect(result.files == [file])
        #expect(result.mainTemplate == "main")
        #expect(result.templateSet == nil)
        #expect(result.outputDirectory == output.standardizedFileURL)
        #expect(try fixture.text(of: file) == "abab 3")
        #expect(result.standardOutput?.contains("outside") == true)
        #expect(reports.first == "Generating with Main")
        #expect(reports.last == "Done")
    }

    @Test("chooses the main template, else the first template by name")
    func choosesTemplate() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let marked = try module(
            """
            [module Marked('http://example.com')]
            [template public a()][file ('a.txt')]a[/file][/template]
            [template public b()]
            [comment @main/]
            [file ('b.txt')]b[/file]
            [/template]
            """, named: "Marked", in: fixture)
        let plain = try module(
            """
            [module Plain('http://example.com')]
            [template public zeta()][file ('z.txt')]z[/file][/template]
            [template public alpha()][file ('a.txt')]a[/file][/template]
            """, named: "Plain", in: fixture)
        let output = fixture.directory.appendingPathComponent("generated")

        let first = try await GenerationStep(templates: .module(marked), outputDirectory: output).run(arguments: [])
        let second = try await GenerationStep(templates: .module(plain), outputDirectory: output).run(arguments: [])

        #expect(first.mainTemplate == "b")
        #expect(second.mainTemplate == "alpha")
    }

    @Test("rejects an unknown template, an empty module and an unreadable module")
    func rejectsBadModules() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let main = try module(
            """
            [module Main('http://example.com')]
            [template public main()][/template]
            """, in: fixture)
        let empty = try module("[module Empty('http://example.com')]", named: "Empty", in: fixture)
        let broken = try module("[module Broken('http://example.com')]\n[template public main(]", named: "Broken", in: fixture)
        let output = fixture.directory.appendingPathComponent("generated")

        await #expect(throws: ModelPipelineError.templateNotFound("other", "Main")) {
            _ = try await GenerationStep(templates: .module(main, mainTemplate: "other"), outputDirectory: output)
                .run(arguments: [])
        }
        await #expect(throws: ModelPipelineError.noTemplates("Empty")) {
            _ = try await GenerationStep(templates: .module(empty), outputDirectory: output).run(arguments: [])
        }
        await #expect {
            _ = try await GenerationStep(templates: .module(broken), outputDirectory: output).run(arguments: [])
        } throws: { error in
            guard case ModelPipelineError.templatesUnreadable(let path, _) = error else { return false }
            return path == broken.path
        }
    }

    @Test("rejects parameter names that are not identifiers")
    func rejectsBadParameterNames() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let main = try module("[module Main('http://example.com')]\n[template public main()][/template]", in: fixture)

        await #expect(throws: MTLParameterError.invalidParameterName("a.b")) {
            _ = try await GenerationStep(
                templates: .module(main), parameters: ["a.b": 1],
                outputDirectory: fixture.directory.appendingPathComponent("out")
            ).run(arguments: [])
        }
    }

    @Test("searches the template paths for the imports of a module")
    func moduleImports() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let library = fixture.directory.appendingPathComponent("library")
        try fixture.write(
            """
            [module Greetings('http://example.com')]
            [template public greeting(name : String)]Hello, [name/]![/template]
            """, to: library.appendingPathComponent("Greetings.mtl"))
        let main = try module(
            """
            [module Main('http://example.com')]
            [import Greetings/]
            [template public main()][file ('g.txt')][greeting('you')/][/file][/template]
            """, in: fixture)
        let output = fixture.directory.appendingPathComponent("generated")

        let result = try await GenerationStep(
            templates: .module(main), templatePaths: [library], outputDirectory: output
        ).run(arguments: [])

        #expect(try fixture.text(of: try #require(result.files.first)) == "Hello, you!")
    }

    @Test("passes model root objects as arguments and models by name")
    func modelArguments() async throws {
        let fixture = try PipelineFixture.make()
        defer { fixture.remove() }
        let resourceSet = ResourceSet()
        try await ModelIO.registerMetamodels(at: [fixture.peopleEcore], in: resourceSet)
        let people = try await ModelIO.load(url: fixture.peopleModel, resourceSet: resourceSet).resource
        let main = try module(
            """
            [module Main('http://example.org/people')]
            [template public main(g : Group)]
            [file ('names.txt')][for (p : Person | g.members) separator(',')][p.name/][/for][/file]
            [/template]
            """, in: fixture)
        let output = fixture.directory.appendingPathComponent("generated")

        let result = try await GenerationStep(templates: .module(main), outputDirectory: output)
            .run(arguments: await people.getRootObjects().map { Optional($0) }, models: ["people": people])

        #expect(try fixture.text(of: try #require(result.files.first)) == "Ada,Alan")
    }
}

/// Collects progress reports.
final class ReportCollector: Sendable {
    private let storage = Mutex<[GenerationProgressUpdate]>([])

    /// The reports received so far, in order.
    var updates: [GenerationProgressUpdate] { storage.withLock { $0 } }

    /// The messages of the reports received so far, in order.
    var messages: [String] { updates.map(\.message) }

    /// Records a report.
    ///
    /// - Parameter update: The report to record.
    func receive(_ update: GenerationProgressUpdate) {
        storage.withLock { $0.append(update) }
    }
}
