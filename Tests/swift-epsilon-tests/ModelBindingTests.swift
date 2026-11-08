//
// ModelBindingTests.swift
// swift-epsilon-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EOL
import ModellingCommandLine
import Testing

@testable import swift_epsilon

/// Tests how the values of the model, store and parameter options are read.
@Suite("Model bindings and parameters")
struct ModelBindingTests {
    @Test("A binding names a model and its file")
    func binding() throws {
        let binding = try ModelBinding(parsing: "Bank=data/bank.xmi")
        #expect(binding == ModelBinding(name: "Bank", path: "data/bank.xmi"))
        #expect(binding.names == ["Bank"])
    }

    @Test("A binding may give aliases, and its file may contain the separator")
    func aliases() throws {
        let binding = try ModelBinding(parsing: "Source,Bank,_b2=dir=x/bank.xmi")
        #expect(binding.name == "Source")
        #expect(binding.aliases == ["Bank", "_b2"])
        #expect(binding.path == "dir=x/bank.xmi")
        #expect(binding.names == ["Source", "Bank", "_b2"])
    }

    @Test("A binding without a name, a separator or a file is rejected")
    func malformedBindings() {
        #expect(throws: KeyValueOptionError.self) { try ModelBinding(parsing: "bank.xmi") }
        #expect(throws: KeyValueOptionError.self) { try ModelBinding(parsing: "=bank.xmi") }
        #expect(throws: KeyValueOptionError.self) { try ModelBinding(parsing: "Bank=") }
    }

    @Test("Model names and aliases must be identifiers", arguments: ["1Bank=b.xmi", "Bank,=b.xmi", "Ba nk=b.xmi", "Bank,a-b=b.xmi"])
    func invalidNames(argument: String) {
        #expect(throws: SwiftEpsilonError.self) { try ModelBinding(parsing: argument) }
    }

    @Test("Identifiers start with a letter or underscore")
    func identifiers() {
        #expect(Identifier.isValid("Bank"))
        #expect(Identifier.isValid("_bank2"))
        #expect(Identifier.isValid("Größe"))
        #expect(!Identifier.isValid(""))
        #expect(!Identifier.isValid("2bank"))
        #expect(!Identifier.isValid("bank!"))
    }

    @Test("A store request names a model and optionally another file")
    func storeRequests() throws {
        #expect(try StoreRequest(parsing: "Bank") == StoreRequest(name: "Bank"))
        #expect(try StoreRequest(parsing: "Bank=out/bank.json") == StoreRequest(name: "Bank", path: "out/bank.json"))
        #expect(throws: SwiftEpsilonError.self) { try StoreRequest(parsing: "1Bank") }
        #expect(throws: SwiftEpsilonError.self) { try StoreRequest(parsing: "a,b=x.xmi") }
        #expect(throws: KeyValueOptionError.self) { try StoreRequest(parsing: "Bank=") }
    }

    @Test("A plan keeps the order of sources and targets")
    func plan() throws {
        let plan = try ModelPlan(
            models: ["Bank=bank.xmi", "Other,O=other.xmi"], targets: ["Ledger=ledger.xmi"], stores: ["O=copy.xmi"])
        #expect(plan.sources.map(\.name) == ["Bank", "Other"])
        #expect(plan.targets.map(\.name) == ["Ledger"])
        #expect(plan.bindings.map(\.name) == ["Bank", "Other", "Ledger"])
        #expect(plan.stores == [StoreRequest(name: "O", path: "copy.xmi")])
    }

    @Test("A plan rejects names given twice and stores of unknown models")
    func planErrors() {
        #expect(throws: SwiftEpsilonError.duplicateModelName("Bank")) {
            try ModelPlan(models: ["Bank=a.xmi", "Bank=b.xmi"])
        }
        #expect(throws: SwiftEpsilonError.duplicateModelName("B")) {
            try ModelPlan(models: ["Bank,B=a.xmi"], targets: ["B=b.xmi"])
        }
        #expect(throws: SwiftEpsilonError.unknownStoredModel("Ledger")) {
            try ModelPlan(models: ["Bank=a.xmi"], targets: ["Ledger=l.xmi"], stores: ["Ledger"])
        }
    }

    @Test("Parameter values are typed by their text")
    func parameterTypes() {
        #expect(ParameterValue(text: "true") == .boolean(true))
        #expect(ParameterValue(text: "false") == .boolean(false))
        #expect(ParameterValue(text: "42") == .integer(42))
        #expect(ParameterValue(text: "-7") == .integer(-7))
        #expect(ParameterValue(text: "2.5") == .real(2.5))
        #expect(ParameterValue(text: "1e3") == .real(1000))
        #expect(ParameterValue(text: "inf") == .string("inf"))
        #expect(ParameterValue(text: "Alice") == .string("Alice"))
        #expect(ParameterValue(text: "") == .string(""))
        #expect(ParameterValue(text: "True") == .string("True"))
    }

    @Test("Parameter values become EOL values")
    func parameterValues() {
        #expect(ParameterValue.boolean(true).eolValue == .boolean(true))
        #expect(ParameterValue.integer(3).eolValue == .integer(3))
        #expect(ParameterValue.real(0.5).eolValue == .real(0.5))
        #expect(ParameterValue.string("x").eolValue == .string("x"))
    }

    @Test("Parameters are read by name, a later one replacing an earlier one")
    func parameters() throws {
        let values = try ParameterValue.parameters(from: ["reader=Alice", "count=2", "reader=Bob", "note=a=b"])
        #expect(values == ["reader": .string("Bob"), "count": .integer(2), "note": .string("a=b")])
    }

    @Test("Parameter names must be identifiers that are not keywords", arguments: ["2x=1", "a-b=1", "var=1", "self=1", "out=1", "loopCount=1"])
    func invalidParameterNames(argument: String) {
        #expect(throws: (any Error).self) { try ParameterValue.parameters(from: [argument]) }
    }

    @Test("A parameter without a separator is rejected")
    func malformedParameter() {
        #expect(throws: KeyValueOptionError.self) { try ParameterValue.parameters(from: ["reader"]) }
    }

    @Test("Every error describes itself in terms of the command line")
    func errorDescriptions() {
        let errors: [(SwiftEpsilonError, String)] = [
            (.modelNotFound("bank.xmi"), "Model file not found: bank.xmi"),
            (.sourceNotFound("x.eol"), "Source file not found or not readable: x.eol"),
            (.invalidSource("x.eol", 1), "x.eol has 1 syntax error"),
            (.invalidSource("x.eol", 2), "x.eol has 2 syntax errors"),
            (.invalidModelName("1B"), "Invalid model name '1B': a model name must be an identifier"),
            (.duplicateModelName("B"), "The model name 'B' is given more than once"),
            (.unknownStoredModel("L"), "Cannot store 'L': no --model has that name"),
            (.invalidParameterName("var"), "Invalid parameter name 'var': it must be an identifier that is neither a keyword nor a reserved variable"),
            (.targetWithoutMetamodel("L"), "The target model 'L' needs a metamodel: give it with --metamodel"),
            (.outputNotDirectory("f.txt"), "The output of an EGX module must be a directory: f.txt"),
        ]
        for (error, text) in errors {
            #expect(error.description == text)
            #expect(error.errorDescription == text)
        }
    }
}
