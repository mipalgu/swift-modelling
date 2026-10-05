import ECore
import EMFBase
import Foundation
import Testing

@testable import ModellingGenerators

/// The lines of the generator model that the three preset settings write.
private enum PresetLine {
    static let operationReflection = #"operationReflection="true""#
    static let importOrganizing = #"importOrganizing="true""#
    static let rootExtendsClass = #"rootExtendsClass="org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container""#
}

/// One combination of preset and overrides, with the settings that the generator model must hold.
struct DefaultsCase: Sendable, CustomTestStringConvertible {
    let name: String
    let options: GenModelImportOptions
    let operationReflection: Bool
    let importOrganizing: Bool
    let rootExtendsClass: String?

    var testDescription: String { name }

    static let all: [DefaultsCase] = [
        DefaultsCase(
            name: "no preset is headless", options: GenModelImportOptions(),
            operationReflection: false, importOrganizing: false, rootExtendsClass: nil),
        DefaultsCase(
            name: "headless", options: GenModelImportOptions(defaults: .headless),
            operationReflection: false, importOrganizing: false, rootExtendsClass: nil),
        DefaultsCase(
            name: "wizard", options: GenModelImportOptions(defaults: .wizard),
            operationReflection: true, importOrganizing: true,
            rootExtendsClass: "org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"),
        DefaultsCase(
            name: "operation reflection overrides headless",
            options: GenModelImportOptions(operationReflection: true),
            operationReflection: true, importOrganizing: false, rootExtendsClass: nil),
        DefaultsCase(
            name: "import organising overrides headless",
            options: GenModelImportOptions(defaults: .headless, importOrganizing: true),
            operationReflection: false, importOrganizing: true, rootExtendsClass: nil),
        DefaultsCase(
            name: "root class overrides headless",
            options: GenModelImportOptions(rootExtendsClass: "org.example.Root"),
            operationReflection: false, importOrganizing: false, rootExtendsClass: "org.example.Root"),
        DefaultsCase(
            name: "no operation reflection overrides wizard",
            options: GenModelImportOptions(defaults: .wizard, operationReflection: false),
            operationReflection: false, importOrganizing: true,
            rootExtendsClass: "org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"),
        DefaultsCase(
            name: "no import organising overrides wizard",
            options: GenModelImportOptions(defaults: .wizard, importOrganizing: false),
            operationReflection: true, importOrganizing: false,
            rootExtendsClass: "org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"),
        DefaultsCase(
            name: "root class overrides wizard",
            options: GenModelImportOptions(defaults: .wizard, rootExtendsClass: "org.example.Root"),
            operationReflection: true, importOrganizing: true, rootExtendsClass: "org.example.Root"),
        DefaultsCase(
            name: "the default root class overrides wizard",
            options: GenModelImportOptions(
                defaults: .wizard, rootExtendsClass: "org.eclipse.emf.ecore.impl.EObjectImpl"),
            operationReflection: true, importOrganizing: true, rootExtendsClass: nil),
        DefaultsCase(
            name: "every override replaces the wizard",
            options: GenModelImportOptions(
                defaults: .wizard, operationReflection: false, rootExtendsClass: "org.example.Root",
                importOrganizing: false),
            operationReflection: false, importOrganizing: false, rootExtendsClass: "org.example.Root"),
        DefaultsCase(
            name: "every override replaces headless",
            options: GenModelImportOptions(
                defaults: .headless, operationReflection: true, rootExtendsClass: "org.example.Root",
                importOrganizing: true),
            operationReflection: true, importOrganizing: true, rootExtendsClass: "org.example.Root"),
    ]
}

@Suite("Generator model defaults")
struct GenModelDefaultsTests {
    @Test("The presets are named headless and wizard")
    func presetNames() {
        #expect(GenModelDefaults.allCases == [.headless, .wizard])
        #expect(GenModelDefaults(rawValue: "headless") == .headless)
        #expect(GenModelDefaults(rawValue: "wizard") == .wizard)
        #expect(GenModelDefaults(rawValue: "interactive") == nil)
    }

    @Test("Options have no preset and no overrides unless they are given")
    func optionsStartUnset() {
        let options = GenModelImportOptions()
        #expect(options.defaults == nil)
        #expect(options.operationReflection == nil)
        #expect(options.rootExtendsClass == nil)
        #expect(options.importOrganizing == nil)
    }

    @Test("The preset and overrides decide the settings that are written", arguments: DefaultsCase.all)
    @MainActor
    func settings(_ golden: DefaultsCase) async throws {
        let generated = try await generate(OracleCase.all[1], options: golden.options)
        defer { generated.project.remove() }
        let text = generated.text
        #expect(text.contains(#"operationReflection="true""#) == golden.operationReflection)
        #expect(!text.contains(#"operationReflection="false""#))
        #expect(text.contains(#"importOrganizing="true""#) == golden.importOrganizing)
        #expect(!text.contains(#"importOrganizing="false""#))
        if let rootExtendsClass = golden.rootExtendsClass {
            #expect(text.contains(#"rootExtendsClass="\#(rootExtendsClass)""#))
        } else {
            #expect(!text.contains("rootExtendsClass"))
        }
    }

    @Test("The headless preset writes the settings of the bare Eclipse generator")
    @MainActor
    func headlessKeepsMetamodelDefaults() async throws {
        let generated = try await generate(OracleCase.all[1], options: GenModelImportOptions())
        defer { generated.project.remove() }
        #expect(!generated.text.contains("operationReflection"))
        #expect(!generated.text.contains("importOrganizing"))
        #expect(!generated.text.contains("rootExtendsClass"))
        #expect(generated.text.contains(#"importerID="org.eclipse.emf.importer.ecore""#))
    }

    @Test("The transformation receives the preset name and the overrides as text")
    func parameters() {
        typealias Name = GenModelImportConstants.Parameter
        func values(_ options: GenModelImportOptions) -> [String: any EcoreValue] {
            GenModelTransformation.parameters(
                options: options, modelProject: "", modelName: "M", foreignModels: [])
        }
        let none = values(GenModelImportOptions())
        #expect(none[Name.defaults] as? String == "headless")
        #expect(none[Name.operationReflection] as? String == "")
        #expect(none[Name.importOrganizing] as? String == "")
        #expect(none[Name.rootExtendsClass] as? String == "")
        let given = values(
            GenModelImportOptions(
                defaults: .wizard, operationReflection: false, rootExtendsClass: "a.B", importOrganizing: true))
        #expect(given[Name.defaults] as? String == "wizard")
        #expect(given[Name.operationReflection] as? String == "false")
        #expect(given[Name.importOrganizing] as? String == "true")
        #expect(given[Name.rootExtendsClass] as? String == "a.B")
        #expect(Name.all.contains(Name.defaults))
        #expect(Set(none.keys) == Name.all)
    }

    // MARK: - Reloading

    /// Imports the families model with the given options, then reloads it with other options.
    @MainActor
    private func reloaded(first: GenModelImportOptions, second: GenModelImportOptions) async throws -> String {
        let generated = try await generate(OracleCase.all[1], options: first)
        defer { generated.project.remove() }
        var options = second
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model(OracleCase.all[1].ecoreFileName)], options: options)
        return try String(contentsOf: result.url, encoding: .utf8)
    }

    @Test("A reload without a preset or overrides keeps the settings of the existing model")
    @MainActor
    func reloadKeepsWizardSettings() async throws {
        let text = try await reloaded(
            first: GenModelImportOptions(defaults: .wizard), second: GenModelImportOptions())
        #expect(text.contains(PresetLine.operationReflection))
        #expect(text.contains(PresetLine.importOrganizing))
        #expect(text.contains(PresetLine.rootExtendsClass))
    }

    @Test("A reload without a preset or overrides keeps headless settings")
    @MainActor
    func reloadKeepsHeadlessSettings() async throws {
        let text = try await reloaded(first: GenModelImportOptions(), second: GenModelImportOptions())
        #expect(!text.contains("operationReflection"))
        #expect(!text.contains("importOrganizing"))
        #expect(!text.contains("rootExtendsClass"))
    }

    @Test("A reload keeps the settings that no override names")
    @MainActor
    func reloadOverridesOneSetting() async throws {
        let text = try await reloaded(
            first: GenModelImportOptions(defaults: .wizard),
            second: GenModelImportOptions(operationReflection: false))
        #expect(!text.contains("operationReflection"))
        #expect(text.contains(PresetLine.importOrganizing))
        #expect(text.contains(PresetLine.rootExtendsClass))
        let other = try await reloaded(
            first: GenModelImportOptions(),
            second: GenModelImportOptions(importOrganizing: true))
        #expect(other.contains(PresetLine.importOrganizing))
        #expect(!other.contains("operationReflection"))
        #expect(!other.contains("rootExtendsClass"))
    }

    @Test("A preset given with a reload replaces the settings of the existing model")
    @MainActor
    func reloadPresetReplaces() async throws {
        let toWizard = try await reloaded(
            first: GenModelImportOptions(), second: GenModelImportOptions(defaults: .wizard))
        #expect(toWizard.contains(PresetLine.operationReflection))
        #expect(toWizard.contains(PresetLine.importOrganizing))
        #expect(toWizard.contains(PresetLine.rootExtendsClass))
        let toHeadless = try await reloaded(
            first: GenModelImportOptions(defaults: .wizard),
            second: GenModelImportOptions(defaults: .headless))
        #expect(!toHeadless.contains("operationReflection"))
        #expect(!toHeadless.contains("importOrganizing"))
        #expect(!toHeadless.contains("rootExtendsClass"))
    }

    @Test("Overrides given with a reload and a preset win over the preset")
    @MainActor
    func reloadOverridesBeatPreset() async throws {
        let text = try await reloaded(
            first: GenModelImportOptions(),
            second: GenModelImportOptions(defaults: .wizard, rootExtendsClass: "org.example.Root", importOrganizing: false))
        #expect(text.contains(PresetLine.operationReflection))
        #expect(!text.contains("importOrganizing"))
        #expect(text.contains(#"rootExtendsClass="org.example.Root""#))
    }
}
