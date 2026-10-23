//
// KeyValueOptionTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ModellingCommandLine
import Testing

@Suite("KeyValueOption - name=value families")
struct KeyValueOptionTests {
    @Test("reads text values, keeping separators in the value")
    func textValues() throws {
        let option = KeyValueOption<String>(noun: "parameter")
        let values = try option.values(from: ["a=1", "b=x=y", "c="])
        #expect(values == ["a": "1", "b": "x=y", "c": ""])
    }

    @Test("lets a later pair replace an earlier one")
    func laterPairWins() throws {
        let option = KeyValueOption<String>(noun: "parameter")
        #expect(try option.values(from: ["a=1", "a=2"]) == ["a": "2"])
    }

    @Test("rejects text without a name or a separator", arguments: ["novalue", "=value", ""])
    func missingSeparator(_ text: String) {
        let option = KeyValueOption<String>(noun: "parameter")
        #expect(throws: KeyValueOptionError.missingSeparator(noun: "parameter", text: text, usage: "name=value")) {
            try option.pair(text)
        }
    }

    @Test("describes a missing separator with the noun and the usage")
    func missingSeparatorMessage() {
        let error = KeyValueOptionError.missingSeparator(noun: "parameter", text: "x", usage: "name=value")
        #expect(error.description == "Invalid parameter 'x': expected name=value")
        #expect(error.localizedDescription == error.description)
    }

    @Test("uses its own key placeholder in the usage")
    func keyPlaceholder() {
        let option = KeyValueOption<String>(noun: "prefix", keyPlaceholder: "package")
        #expect(option.usage == "package=value")
        #expect(throws: KeyValueOptionError.missingSeparator(noun: "prefix", text: "p", usage: "package=value")) {
            try option.pair("p")
        }
    }

    @Test("accepts only the allowed keys and lists them")
    func allowedKeys() throws {
        let option = KeyValueOption<String>(noun: "setting", allowedKeys: ["indent", "width"])
        #expect(option.allowedKeyList == "indent, width")
        #expect(try option.pair("width=80") == ("width", "80"))
        #expect(throws: KeyValueOptionError.unknownKey(noun: "setting", key: "depth", allowed: ["indent", "width"])) {
            try option.pair("depth=1")
        }
        #expect(KeyValueOption<String>(noun: "any").allowedKeyList == nil)
    }

    @Test("describes an unknown key with the allowed keys")
    func unknownKeyMessage() {
        let error = KeyValueOptionError.unknownKey(noun: "setting", key: "depth", allowed: ["indent", "width"])
        #expect(error.description == "Unknown setting 'depth': expected one of indent, width")
    }

    @Test("reads typed values with the initialiser of their type")
    func typedValues() throws {
        #expect(try KeyValueOption<Int>(noun: "level").values(from: ["a=3"]) == ["a": 3])
        #expect(try KeyValueOption<Bool>(noun: "flag").values(from: ["on=true"]) == ["on": true])
        #expect(try KeyValueOption<Double>(noun: "ratio").values(from: ["r=0.5"]) == ["r": 0.5])
    }

    @Test("reports values that the type cannot read")
    func invalidTypedValue() {
        let option = KeyValueOption<Int>(noun: "level")
        #expect(throws: KeyValueOptionError.invalidValue(
            noun: "level", key: "a", value: "many", reason: "expected a value of type Int")) {
            try option.pair("a=many")
        }
        let error = KeyValueOptionError.invalidValue(noun: "level", key: "a", value: "many", reason: "why")
        #expect(error.description == "Invalid value 'many' for the level 'a': why")
    }

    /// A failure raised by a custom conversion.
    struct Rejected: Error, CustomStringConvertible {
        var description: String { "not allowed here" }
    }

    @Test("passes the key to a custom conversion and reports its errors")
    func customConversion() throws {
        let option = KeyValueOption<String>(noun: "entry") { key, text in
            guard key != "locked" else { throw Rejected() }
            return key + ":" + text
        }
        #expect(try option.values(from: ["a=b"]) == ["a": "a:b"])
        #expect(throws: KeyValueOptionError.invalidValue(
            noun: "entry", key: "locked", value: "x", reason: "not allowed here")) {
            try option.pair("locked=x")
        }
    }

    @Test("passes errors of the family itself through a custom conversion")
    func nestedFamilyErrors() {
        let inner = KeyValueOption<String>(noun: "inner")
        let outer = KeyValueOption<String>(noun: "outer") { _, text in try inner.pair(text).value }
        #expect(throws: KeyValueOptionError.missingSeparator(noun: "inner", text: "x", usage: "name=value")) {
            try outer.pair("a=x")
        }
    }
}
