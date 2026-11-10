//
// StrictKeyTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingCommandLine
import Testing

@testable import swift_epsilon

/// Tests for `--strict`, `--no-strict` and the `strict` key of the configuration file in
/// `swift-epsilon evl validate`.
@Suite("swift-epsilon evl validate - strictness from the command line and the configuration file")
struct StrictKeyTests {
    @Test("leaves the strictness to the configuration file unless the command line gives it")
    func flags() throws {
        let plain = try EVLValidateCommand.parse(["rules.evl"])
        let lenient = try EVLValidateCommand.parse(["rules.evl", "--no-strict"])
        let strict = try EVLValidateCommand.parse(["rules.evl", "--strict"])

        #expect(plain.explicitStrict == nil)
        #expect(lenient.explicitStrict == false)
        #expect(strict.explicitStrict == true)
        #expect(SwiftEpsilonVocabulary.OptionName.strict == ValidationOptionName.strict)
    }
}
