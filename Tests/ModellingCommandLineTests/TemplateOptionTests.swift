//
// TemplateOptionTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import EMFBase
import Foundation
import MTL
import ModellingCommandLine
import Testing

@Suite("Template parameter and template path options")
struct TemplateOptionTests {
    @Test("collects repeated parameters in order")
    func parsesParameters() throws {
        let options = try TemplateParameterOptions.parse(["--param", "package=org.example", "--param", "n=3"])
        #expect(options.isGiven)
        #expect(options.arguments == ["package=org.example", "n=3"])
        let values = try options.values
        #expect(values["package"] as? String == "org.example")
        #expect(values["n"] as? Int == 3)
    }

    @Test("types values as booleans, integers or strings")
    func typedValues() throws {
        let options = try TemplateParameterOptions.parse(
            ["--param", "flag=true", "--param", "off=false", "--param", "count=041", "--param", "x=y=z"])
        let values = try options.values
        #expect(values["flag"] as? Bool == true)
        #expect(values["off"] as? Bool == false)
        #expect(values["count"] as? String == "041")
        #expect(values["x"] as? String == "y=z")
    }

    @Test("offers the parameter services")
    func services() throws {
        let options = try TemplateParameterOptions.parse(["--param", "a=1", "--param", "a=2"])
        let services = try options.services
        #expect(services.values["a"] as? Int == 2)
        #expect(services.services.map(\.name).sorted() == ["hasParameter", "parameter"])
    }

    @Test("has no parameters by default")
    func empty() throws {
        let options = try TemplateParameterOptions.parse([])
        #expect(!options.isGiven)
        #expect(try options.values.isEmpty)
    }

    @Test("rejects malformed arguments, bad names and reserved words")
    func rejectsBadParameters() throws {
        let malformed = try TemplateParameterOptions.parse(["--param", "novalue"])
        #expect(throws: TemplateParameterError.invalidParameter("novalue")) { try malformed.values }
        let badName = try TemplateParameterOptions.parse(["--param", "a.b=1"])
        #expect(throws: TemplateParameterError.invalidParameterName("a.b")) { try badName.values }
        let reserved = try TemplateParameterOptions.parse(["--param", "template=1"])
        #expect(throws: TemplateParameterError.reservedParameterName("template")) { try reserved.services }
    }

    @Test("describes the problems as the command line reports them")
    func errorMessages() {
        #expect(TemplateParameterError.invalidParameter("x").description == "Invalid parameter 'x': expected name=value")
        #expect(TemplateParameterError.invalidParameterName("a.b").description
            == "Invalid parameter name 'a.b': it is not a valid identifier")
        #expect(TemplateParameterError.reservedParameterName("if").description
            == "Invalid parameter name 'if': it is a reserved keyword of MTL or AQL")
        #expect(TemplateParameterError.invalidParameter("x").localizedDescription
            == "Invalid parameter 'x': expected name=value")
        #expect(TemplateParameterError(.invalidParameter("y")) == .invalidParameter("y"))
        #expect(TemplateParameterError(.invalidParameterName("y")) == .invalidParameterName("y"))
        #expect(TemplateParameterError(.reservedParameterName("y")) == .reservedParameterName("y"))
    }

    @Test("names the option param")
    func optionName() {
        #expect(TemplateParameterOptions.optionName == "param")
        #expect(TemplateParameterOptions.helpMessage().contains("--param <param>"))
    }

    @Test("collects template paths in order")
    func templatePaths() throws {
        let options = try TemplatePathOptions.parse(["--template-path", "a", "--template-path", "b"])
        #expect(options.isGiven)
        #expect(options.templatePaths == ["a", "b"])
        #expect(options.urls.map(\.lastPathComponent) == ["a", "b"])
        #expect(!(try TemplatePathOptions.parse([])).isGiven)
        #expect(TemplatePathOptions.helpMessage().contains("--template-path <template-path>"))
    }

    @Test("checks that template paths are directories")
    func templatePathDirectories() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("file.txt")
        try Data().write(to: file)

        let good = try TemplatePathOptions.parse(["--template-path", directory.path])
        #expect(try good.directories().map(\.path) == [directory.path])
        let bad = try TemplatePathOptions.parse(["--template-path", directory.path, "--template-path", file.path])
        #expect(throws: TemplatePathError.notADirectory(file.path)) { try bad.directories() }
        #expect(TemplatePathError.notADirectory("x").description == "The template path 'x' is not a directory")
        #expect(TemplatePathError.notADirectory("x").localizedDescription == "The template path 'x' is not a directory")
    }
}
