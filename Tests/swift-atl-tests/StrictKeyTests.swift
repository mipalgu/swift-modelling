//
// StrictKeyTests.swift
// swift-atl-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingCommandLine
import Testing

@testable import swift_atl

/// Tests for `--strict`, `--no-strict` and the `strict` key of the configuration file in
/// `swift-atl validate`.
@Suite("swift-atl validate - strictness from the command line and the configuration file")
struct StrictKeyTests {
    @Test("leaves the strictness to the configuration file unless the command line gives it")
    func flags() throws {
        let plain = try ValidateCommand.parse(["a.atl"])
        let strict = try ValidateCommand.parse(["a.atl", "--strict"])
        let lenient = try ValidateCommand.parse(["a.atl", "--no-strict"])

        #expect(plain.explicitStrict == nil)
        #expect(!plain.strict)
        #expect(strict.explicitStrict == true)
        #expect(strict.strict)
        #expect(lenient.explicitStrict == false)
        #expect(!lenient.strict)
    }

    @Test("names the flag after the key of the configuration file")
    func name() {
        #expect(ModellingConfiguration.keys.contains(ValidationOptionName.strict))
        #expect(ValidationOptionName.strict == "strict")
    }
}
