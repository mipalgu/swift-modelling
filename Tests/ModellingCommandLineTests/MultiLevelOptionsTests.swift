//
// MultiLevelOptionsTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import MultiLevel
import Testing

/// Tests for the options and helpers of multi-level models: level crossing modes, deep views
/// and the detection of linguistic instances.
@Suite("Multi-level options")
struct MultiLevelOptionsTests {
    /// A model whose bottom level refers to a clabject one level up.
    static let crossing = """
        Model Cycling@2 {
          Node BicycleType {
            alternative : BicycleType[0..1];
          }
        }
        Cycling Catalogue {
          BicycleType Racer {}
        }
        Catalogue Inventory {
          Racer bike {
            alternative = Racer;
          }
        }

        """

    /// The model of ``crossing`` with the crossing declared.
    static var declared: String { crossing.replacingOccurrences(of: "[0..1];", with: "[0..1] {level=1};") }

    /// Reads a MetaDepth text.
    ///
    /// - Parameter text: The text.
    /// - Returns: The deep model.
    /// - Throws: An error if the text has no model.
    static func model(_ text: String) throws -> DeepModel {
        try #require(MetaDepthReader.parse(text).model)
    }

    @Test("names the option and its values once")
    func names() {
        #expect(LevelCrossingOptions.optionName == "level-crossing")
        #expect(LevelCrossingOptions.valueList == "strict|declared|non-strict")
        #expect(LevelCrossingOptions.defaultMode == .declared)
        #expect(DeepViewOptions.optionName == "deep-view")
    }

    @Test("maps the modes to the level crossing policies of the library")
    func policies() throws {
        #expect(LevelCrossingMode.strict.policy == .strict)
        #expect(LevelCrossingMode.declared.policy == .strict)
        #expect(LevelCrossingMode.nonStrict.policy == .nonStrict)
        #expect(try LevelCrossingOptions.parse([]).mode == .declared)
        #expect(try LevelCrossingOptions.parse(["--level-crossing", "non-strict"]).mode == .nonStrict)
        #expect(throws: (any Error).self) { try LevelCrossingOptions.parse(["--level-crossing", "loose"]) }
    }

    @Test("reports declared crossings only in the strict mode")
    func strictDiagnostics() throws {
        let declared = try Self.model(Self.declared)
        let strict = LevelCrossingMode.strict.diagnostics(for: declared)
        #expect(strict.map(\.code) == [MultiLevelDiagnosticCode.levelCrossing])
        #expect(strict.first?.message.contains("'BicycleType.alternative' is declared to refer to level 1") == true)
        #expect(LevelCrossingMode.declared.diagnostics(for: declared).isEmpty)
        #expect(LevelCrossingMode.nonStrict.diagnostics(for: declared).isEmpty)
        #expect(LevelCrossingMode.strict.diagnostics(for: try Self.model(Self.crossing)).isEmpty)
    }

    @Test("parses the level of the deep view")
    func deepViewOption() throws {
        #expect(!(try DeepViewOptions.parse([])).isGiven)
        let options = try DeepViewOptions.parse(["--deep-view", "0"])
        #expect(options.isGiven)
        #expect(options.level == 0)
    }

    @Test("presents the deep view of a level of a resource of linguistic instances")
    @MainActor
    func views() async throws {
        let resourceSet = ResourceSet()
        let resource = await LinguisticEncoding.resource(for: try Self.model(Self.declared), in: resourceSet)
        let views = try #require(try await MultiLevelSupport.views(of: resource, level: 0, in: resourceSet))
        #expect(views.view.level == 0)
        #expect(views.views.map(\.level) == [2, 1, 0])
        await #expect(throws: MultiLevelError.noSuchLevel(5)) {
            _ = try await MultiLevelSupport.views(of: resource, level: 5, in: resourceSet)
        }
        let plain = await resourceSet.createResource(uri: "memory:plain")
        #expect(try await MultiLevelSupport.views(of: plain, level: 0, in: resourceSet) == nil)
    }

    @Test("recognises XMI documents of linguistic instances")
    @MainActor
    func linguisticInstances() async throws {
        let directory = try ScratchDirectory().url
        let encoded = directory.appendingPathComponent("cycling.xmi")
        try await LinguisticEncoding.xmi(of: try Self.model(Self.declared)).write(to: encoded, atomically: true, encoding: .utf8)
        let other = directory.appendingPathComponent("other.xmi")
        try "<a:B xmlns:a=\"urn:example\"/>".write(to: other, atomically: true, encoding: .utf8)
        #expect(MultiLevelSupport.holdsLinguisticInstances(encoded))
        #expect(!MultiLevelSupport.holdsLinguisticInstances(other))
        #expect(!MultiLevelSupport.holdsLinguisticInstances(directory.appendingPathComponent("missing.xmi")))
    }

    @Test("reads and writes MetaDepth documents as multi-level models")
    func instanceFormat() {
        #expect(ModelFileFormat.instanceFormat(of: URL(fileURLWithPath: "/models/shop.mdepth")) == .metadepth)
    }
}
