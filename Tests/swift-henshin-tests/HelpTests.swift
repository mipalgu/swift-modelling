//
// HelpTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Testing

@testable import swift_henshin

/// Checks the help and the version that the tool prints.
@Suite("swift-henshin help")
struct HelpTests {
    @Test("The version is that of the tools")
    func version() async throws {
        let run = try await runSwiftHenshin(["--version"])
        #expect(run.succeeded)
        #expect(run.output == "0.8.1\n")
    }

    @Test("The overview lists every subcommand and the exit statuses")
    func overview() async throws {
        let run = try await runSwiftHenshin(["--help"])
        #expect(run.succeeded)
        for command in ["apply", "validate", "translate", "analyse", "explore", "convert"] {
            #expect(run.output.contains("  \(command) "), "\(command)")
        }
        #expect(run.output.contains("Exit statuses: 0 on success, 1 if the command fails"))
        let bare = try await runSwiftHenshin([])
        #expect(bare.output.contains("USAGE: swift-henshin <subcommand>"))
    }

    @Test(
        "Each subcommand documents its options, examples and exit statuses",
        arguments: [
            ("apply", ["--unit <name>", "--param <name=value>", "--output <file>", "--seed <n>", "--nondeterministic",
                       "--check-dangling", "--no-dangling-check", "--injective", "--non-injective", "--iteration-limit <n>",
                       "--trace", "--dry-run", "--metamodel <file.ecore>", "--encoding", "--verbose"]),
            ("validate", ["<module.henshin>", "--metamodel <file.ecore>", "--encoding", "--verbose"]),
            ("translate", ["--expression <expression>", "--variables <name,...>", "--table", "--verbose"]),
            ("analyse", ["--rules <name,...>", "--direction <direction>", "--granularity <level>", "--essential",
                         "--no-multiplicities", "--format <format>", "--check-dangling", "--no-dangling-check"]),
            ("explore", ["--rules <name,...>", "--units <name,...>", "--param <unit.name=value>", "--max-states <n>",
                         "--max-depth <n>", "--max-objects <n>", "--identity <mode>", "--reach <aql>", "--invariant <aql>",
                         "--forbid <rule>", "--deadlock", "--dot <file.dot>", "--workers <n>"]),
            ("convert", ["<module.henshin>", "--output <file>", "--force", "--encoding"]),
        ])
    func subcommand(name: String, options: [String]) async throws {
        let run = try await runSwiftHenshin([name, "--help"])
        #expect(run.succeeded)
        for option in options {
            #expect(run.output.contains(option), "\(name): \(option)")
        }
        #expect(run.output.contains("Exit statuses: 0"))
        #expect(run.output.contains("Examples:"))
        #expect(!run.output.contains("\u{2014}"))
    }
}
