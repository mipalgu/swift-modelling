//
// ConfigurationTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Henshin
import ModellingCommandLine
import Testing

@testable import swift_henshin

/// Runs the commands of `swift-henshin` with a configuration file, as a project keeps one.
@Suite("swift-henshin configuration file", .serialized)
struct ConfigurationTests {
    /// Copies the depot fixtures into the root of a new repository.
    ///
    /// - Parameter configuration: The text of the configuration file, if any.
    /// - Returns: The directory of the repository.
    static func repository(_ configuration: String? = nil) throws -> URL {
        let directory = try Fixture.copyDepot()
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent(ModellingConfiguration.repositoryMarker), withIntermediateDirectories: true)
        if let configuration { try Fixture.write(configuration, named: ModellingConfiguration.fileName, in: directory) }
        return directory
    }

    /// The arguments that remove the parcel P1, which another object still refers to.
    static let removeHeldParcel = [
        "apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P1", "--dry-run",
    ]

    @Test("checks the dangling condition as the configuration file says, unless the command line says otherwise")
    func dangling() async throws {
        let directory = try Self.repository(#"{ "check-dangling": false }"#)
        defer { try? FileManager.default.removeItem(at: directory) }

        let configured = try await runSwiftHenshin(Self.removeHeldParcel, in: directory)
        let overridden = try await runSwiftHenshin(Self.removeHeldParcel + ["--check-dangling"], in: directory)
        let ignored = try await runSwiftHenshin(Self.removeHeldParcel + ["--no-config"], in: directory)

        #expect(configured.succeeded, "\(configured.error)")
        #expect(overridden.status == 2, "\(overridden.error)")
        #expect(ignored.status == 2, "\(ignored.error)")
    }

    @Test("matches injectively as the configuration file says, unless the command line says otherwise")
    func injectivity() async throws {
        let directory = try Self.repository(#"{ "injective": false }"#)
        defer { try? FileManager.default.removeItem(at: directory) }
        let ring = try Fixture.read(Fixture.model, in: directory)
            .replacingOccurrences(of: "next=\"//@bins.1\"", with: "next=\"//@bins.0\"")
        try Fixture.write(ring, named: "loop.xmi", in: directory)
        let arguments = ["apply", Fixture.module, "loop.xmi", "-u", "move", "--dry-run"]

        let configured = try await runSwiftHenshin(arguments, in: directory)
        let overridden = try await runSwiftHenshin(arguments + ["--injective"], in: directory)

        #expect(configured.succeeded, "\(configured.error)")
        #expect(overridden.status == 2, "\(overridden.error)")
    }

    @Test("writes files in the output encoding of the configuration file, unless the command line says otherwise")
    func outputEncoding() async throws {
        let directory = try Self.repository(#"{ "output-encoding": "ISO-8859-1" }"#)
        defer { try? FileManager.default.removeItem(at: directory) }
        let arguments = ["apply", Fixture.module, Fixture.model, "-u", "removeParcel", "--param", "code=P2", "-o"]

        let configured = try await runSwiftHenshin(arguments + ["configured.xmi"], in: directory)
        let overridden = try await runSwiftHenshin(arguments + ["overridden.xmi", "--output-encoding", "UTF-8"], in: directory)

        #expect(configured.succeeded, "\(configured.error)")
        #expect(overridden.succeeded, "\(overridden.error)")
        #expect(try Fixture.read("configured.xmi", in: directory).contains("ISO-8859-1"))
        #expect(try Fixture.read("overridden.xmi", in: directory).contains("UTF-8"))
    }

    @Test("behaves alike without a configuration file and with --no-config")
    func unchanged() async throws {
        let plain = try Self.repository()
        defer { try? FileManager.default.removeItem(at: plain) }
        let configured = try Self.repository(#"{ "check-dangling": true, "injective": true, "semantics": "legacy" }"#)
        defer { try? FileManager.default.removeItem(at: configured) }
        let runs: [[String]] = [
            Self.removeHeldParcel, ["validate", Fixture.module], ["convert", Fixture.module],
            ["analyse", Fixture.module], ["explore", Fixture.module, Fixture.model, "--max-states", "5"],
        ]

        for arguments in runs {
            let expected = try await runSwiftHenshin(arguments, in: plain)
            let ignored = try await runSwiftHenshin(arguments + ["--no-config"], in: configured)
            #expect(ignored.status == expected.status, "\(arguments): \(ignored.error)")
            #expect(ignored.output == expected.output, "\(arguments)")
            #expect(ignored.error == expected.error, "\(arguments)")
        }
    }

    @Test(
        "rejects an invalid value in the configuration file, naming the file and the key",
        arguments: [(#"{ "injective": "yes" }"#, "injective"), (#"{ "output-encoding": "klingon" }"#, "output-encoding")])
    func invalidValue(text: String, key: String) async throws {
        let directory = try Self.repository(text)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try await runSwiftHenshin(["validate", Fixture.module], in: directory)
        let ignored = try await runSwiftHenshin(["validate", Fixture.module, "--no-config"], in: directory)

        #expect(result.status == 1, "\(result.error)")
        #expect(result.error.contains(ModellingConfiguration.fileName), "\(result.error)")
        #expect(result.error.contains("'\(key)'"), "\(result.error)")
        #expect(ignored.succeeded, "\(ignored.error)")
    }

    @Test("reads Henshin Text in the encoding of the configuration file, unless --encoding says otherwise")
    @MainActor
    func encoding() throws {
        let settings = SemanticsSettings(
            configuration: try ModellingConfiguration(
                data: Data(#"{ "encoding": "latin1" }"#.utf8),
                url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json")))

        #expect(try ModuleOptions.parse([]).loader(settings: settings).encoding == .isoLatin1)
        #expect(try ModuleOptions.parse(["--encoding", "UTF-8"]).loader(settings: settings).encoding == .utf8)
        #expect(try ModuleOptions.parse([]).loader.encoding == nil)
    }

    @Test("resolves the overrides of matching from the command line, then the configuration file")
    func matchingOptions() throws {
        let settings = SemanticsSettings(
            configuration: try ModellingConfiguration(
                data: Data(#"{ "check-dangling": false, "injective": true }"#.utf8),
                url: URL(fileURLWithPath: "/projects/example/.swift-modelling.json")))

        #expect(try MatchingOptions.parse([]).engineOptions(settings: settings) == EngineOptions(
            injectiveMatching: true, checkDangling: false))
        #expect(try MatchingOptions.parse(["--check-dangling", "--non-injective"]).engineOptions(settings: settings)
            == EngineOptions(injectiveMatching: false, checkDangling: true))
        #expect(try MatchingOptions.parse([]).engineOptions(settings: SemanticsSettings()) == EngineOptions())
        #expect(SwiftHenshinVocabulary.OptionName.checkDangling == MatchingOptionName.checkDangling)
        #expect(SwiftHenshinVocabulary.OptionName.injective == MatchingOptionName.injective)
        #expect(String(describing: Injectivity.injective) == MatchingOptionName.injective)
    }

    @Test("lists --config and --no-config for every command that reads modules")
    func help() async throws {
        for command in ["apply", "explore", "analyse", "convert", "validate"] {
            let result = try await runSwiftHenshin([command, "--help"])
            for text in ["--config <file>", "--no-config", ModellingConfiguration.fileName] {
                #expect(result.output.contains(text), "\(command): \(text) is missing from the help")
            }
        }
    }
}
