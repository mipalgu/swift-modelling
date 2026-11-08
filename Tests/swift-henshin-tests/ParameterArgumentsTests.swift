//
// ParameterArgumentsTests.swift
// swift-henshin-tests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Henshin
import ModellingCommandLine
import Testing

@testable import swift_henshin

/// Tests how `--param` values are typed by the declared types of their parameters.
@Suite("Parameter arguments")
struct ParameterArgumentsTests {
    /// The parameters of a unit with one parameter of each kind of type.
    let parameters = [
        UnitParameter(name: "count", kind: .in, typeName: "EInt"),
        UnitParameter(name: "ratio", kind: .in, typeName: "EDouble"),
        UnitParameter(name: "flag", kind: .in, typeName: "EBoolean"),
        UnitParameter(name: "label", kind: .in, typeName: "EString"),
        UnitParameter(name: "bin", kind: .in, typeName: "Bin"),
        UnitParameter(name: "loose", kind: .in),
        UnitParameter(name: "result", kind: .out, typeName: "EInt"),
        UnitParameter(name: "scratch", kind: .var, typeName: "EInt"),
    ]

    /// The family of options for the parameters.
    var family: KeyValueOption<ParameterArgument> {
        ParameterArguments.family(for: parameters, classNames: ["Bin", "Depot"])
    }

    @Test("Values are typed by the declared data types")
    func dataTypes() throws {
        let values = try family.values(from: ["count=3", "ratio=0.5", "flag=true", "label=007", "bin=A"])
        guard case .value(let count) = values["count"], case .value(let ratio) = values["ratio"],
            case .value(let flag) = values["flag"], case .value(let label) = values["label"],
            case .object(let bin) = values["bin"]
        else {
            Issue.record("Unexpected arguments: \(values)")
            return
        }
        #expect(count as? Int == 3)
        #expect(ratio as? Double == 0.5)
        #expect(flag as? Bool == true)
        #expect(label as? String == "007")
        #expect(bin == "A")
    }

    @Test(
        "Untyped values are inferred",
        arguments: [("42", "Int"), ("2.5", "Double"), ("false", "Bool"), ("text", "String")])
    func inferred(text: String, type: String) {
        #expect("\(Swift.type(of: ParameterArguments.inferred(text)))" == type)
    }

    @Test(
        "Values that do not suit their type are rejected",
        arguments: [("count=three", "count", "EInt"), ("ratio=x", "ratio", "EDouble"), ("flag=yes", "flag", "EBoolean")])
    func mismatches(argument: String, name: String, type: String) {
        #expect(throws: KeyValueOptionError.self) { try family.values(from: [argument]) }
        do {
            _ = try family.values(from: [argument])
        } catch {
            #expect("\(error)".contains("for the parameter '\(name)': expected a value of type \(type)"))
        }
    }

    @Test("Only parameters that accept input are allowed")
    func allowedNames() {
        for name in ["result", "scratch", "unknown"] {
            #expect(throws: KeyValueOptionError.self) { try family.values(from: ["\(name)=1"]) }
        }
        #expect(throws: KeyValueOptionError.self) { try family.values(from: ["count"]) }
    }

    @Test("A type that names no class or data type takes the text")
    func otherTypes() throws {
        guard case .value(let value) = try ParameterArguments.argument("red", typeName: "Colour", classNames: []) else {
            Issue.record("Expected a value")
            return
        }
        #expect(value as? String == "red")
        guard case .value(let date) = try ParameterArguments.argument("2026-01-01", typeName: "EDate", classNames: [])
        else {
            Issue.record("Expected a value")
            return
        }
        #expect(date as? String == "2026-01-01")
    }

    @Test("Objects are found by label or fragment path")
    @MainActor
    func objects() async throws {
        let loaded = try await ModuleLoader(metamodels: [], encoding: nil, log: RecordingLog().log())
            .load(try Fixture.depot(Fixture.module).path)
        let model = try await ModelFile.load(
            try Fixture.depot(Fixture.model).path, into: loaded.resourceSet, log: RecordingLog().log())
        let byLabel = try await ParameterArguments.object("B", typeName: "Bin", parameter: "bin", in: model.resource)
        #expect(ValueFormatter.describe(byLabel) == "Bin(B)")
        let byPath = try await ParameterArguments.object("//@bins.0", typeName: "Bin", parameter: "bin", in: model.resource)
        #expect(ValueFormatter.describe(byPath) == "Bin(A)")
        let values = try await ParameterArguments.values(
            ["bin": .object("A"), "count": .value(1)], parameters: parameters, in: model.resource)
        #expect(values["bin"] as? EUUID == byPath.id)
        #expect(values["count"] as? Int == 1)
        await #expect(throws: SwiftHenshinError.objectNotFound(parameter: "bin", value: "Z")) {
            _ = try await ParameterArguments.object("Z", typeName: "Bin", parameter: "bin", in: model.resource)
        }
        await #expect(throws: SwiftHenshinError.objectNotFound(parameter: "bin", value: "A")) {
            _ = try await ParameterArguments.object("A", typeName: "Parcel", parameter: "bin", in: model.resource)
        }
        await #expect(throws: SwiftHenshinError.objectNotFound(parameter: "bin", value: "//@bins.9")) {
            _ = try await ParameterArguments.object("//@bins.9", typeName: "Bin", parameter: "bin", in: model.resource)
        }
    }

    @Test("A label that several objects share is ambiguous")
    @MainActor
    func ambiguous() async throws {
        let directory = try Fixture.copyDepot()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = try Fixture.read(Fixture.model, in: directory).replacingOccurrences(of: "name=\"B\"", with: "name=\"A\"")
        try Fixture.write(model, named: Fixture.model, in: directory)
        let loaded = try await ModuleLoader(metamodels: [], encoding: nil, log: RecordingLog().log())
            .load(directory.appendingPathComponent(Fixture.module).path)
        let loadedModel = try await ModelFile.load(
            directory.appendingPathComponent(Fixture.model).path, into: loaded.resourceSet, log: RecordingLog().log())
        await #expect(throws: SwiftHenshinError.ambiguousObject(parameter: "bin", value: "A", count: 2)) {
            _ = try await ParameterArguments.object("A", typeName: nil, parameter: "bin", in: loadedModel.resource)
        }
    }
}
