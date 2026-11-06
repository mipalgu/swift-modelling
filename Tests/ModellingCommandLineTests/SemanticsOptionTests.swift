//
// SemanticsOptionTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ATL
import ArgumentParser
import ECore
import MTL
import ModellingCommandLine
import ModellingGenerators
import Testing

/// The option groups of a command that runs templates and reads ATL source.
private struct SemanticsCommand: ParsableArguments {
    @OptionGroup var semantics: SemanticsOptions
    @OptionGroup var mtl: MTLSemanticsOptions
    @OptionGroup var atl: ATLSemanticsOptions
}

@Suite("Semantics options")
struct SemanticsOptionTests {
    // MARK: - Preset

    @Test("selects the behaviour of this release unless told otherwise")
    func presetDefault() throws {
        let options = try SemanticsOptions.parse([])
        #expect(options.semantics == .standard)
    }

    @Test("parses each preset by its spelling", arguments: SemanticsPreset.allCases)
    func parsesPresets(preset: SemanticsPreset) throws {
        let options = try SemanticsOptions.parse(["--\(SemanticsOptions.optionName)", preset.rawValue])
        #expect(options.semantics == preset)
    }

    @Test("rejects a value that is not a preset")
    func rejectsUnknownPreset() {
        #expect(throws: (any Error).self) {
            try SemanticsOptions.parse(["--\(SemanticsOptions.optionName)", "0.5"])
        }
    }

    @Test("names the option and its values")
    func presetNames() {
        #expect(SemanticsOptions.optionName == "semantics")
        #expect(SemanticsOptions.valueList == "standard|legacy")
        let discussion = SemanticsOptions.discussion()
        #expect(discussion.contains("--semantics legacy"))
        #expect(discussion.contains("0.6"))
        #expect(discussion.contains("overrides"))
    }

    @Test("gives the standard and legacy options of the libraries")
    func presetOptions() {
        #expect(SemanticsPreset.standard.mtlOptions == .standard)
        #expect(SemanticsPreset.legacy.mtlOptions == .legacy)
        #expect(SemanticsPreset.standard.atlOptions == .standard)
        #expect(SemanticsPreset.legacy.atlOptions == .legacy)
    }

    // MARK: - Template options

    @Test("leaves every template behaviour to the preset unless given")
    func mtlFollowsPreset() throws {
        let options = try MTLSemanticsOptions.parse([])
        #expect(options.mtlOptions(preset: .standard) == .standard)
        #expect(options.mtlOptions(preset: .legacy) == .legacy)
        #expect(options.aqlOptions(preset: .standard) == .standard)
        #expect(options.aqlOptions(preset: .legacy) == .legacy)
    }

    @Test("parses each line break mode", arguments: MTLBlockLineBreaks.allCases, SemanticsPreset.allCases)
    func blockLineBreaks(mode: MTLBlockLineBreaks, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--block-line-breaks", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).blockLineBreaks == mode)
    }

    @Test("parses each collection parameter mode", arguments: MTLCollectionParameters.allCases, SemanticsPreset.allCases)
    func collectionParameters(mode: MTLCollectionParameters, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--collection-parameters", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).collectionParameters == mode)
    }

    @Test("checks let types with --check-let-types and not with --no-check-let-types", arguments: SemanticsPreset.allCases)
    func checkLetTypes(preset: SemanticsPreset) throws {
        #expect(try MTLSemanticsOptions.parse(["--check-let-types"]).mtlOptions(preset: preset).checksLetTypes)
        #expect(try !MTLSemanticsOptions.parse(["--no-check-let-types"]).mtlOptions(preset: preset).checksLetTypes)
    }

    @Test("caches containers with --cache-containers and not with --no-cache-containers", arguments: SemanticsPreset.allCases)
    func cacheContainers(preset: SemanticsPreset) throws {
        #expect(try MTLSemanticsOptions.parse(["--cache-containers"]).mtlOptions(preset: preset).cachesContainers)
        #expect(try !MTLSemanticsOptions.parse(["--no-cache-containers"]).mtlOptions(preset: preset).cachesContainers)
    }

    @Test("parses each collection argument mode", arguments: AQLCollectionArguments.allCases, SemanticsPreset.allCases)
    func collectionArguments(mode: AQLCollectionArguments, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--collection-arguments", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.collectionArguments == mode)
        #expect(options.aqlOptions(preset: preset).collectionArguments == mode)
    }

    @Test("parses each collection kind mode", arguments: AQLCollectionKinds.allCases, SemanticsPreset.allCases)
    func collectionKinds(mode: AQLCollectionKinds, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--collection-kinds", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.collectionKinds == mode)
    }

    @Test("parses each single value collection", arguments: AQLSingleValueCollections.allCases, SemanticsPreset.allCases)
    func singleValueCollections(mode: AQLSingleValueCollections, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--single-value-collections", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.singleValueCollections == mode)
    }

    @Test("parses each container lookup", arguments: AQLContainerLookup.allCases, SemanticsPreset.allCases)
    func containerLookup(mode: AQLContainerLookup, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--container-lookup", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.containerLookup == mode)
    }

    @Test("parses each sequence union", arguments: AQLSequenceUnion.allCases, SemanticsPreset.allCases)
    func sequenceUnion(mode: AQLSequenceUnion, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--sequence-union", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.sequenceUnion == mode)
    }

    @Test("parses each null addition", arguments: AQLNullAddition.allCases, SemanticsPreset.allCases)
    func nullAddition(mode: AQLNullAddition, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--null-addition", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.nullAddition == mode)
    }

    @Test("parses each text form", arguments: AQLTextForm.allCases, SemanticsPreset.allCases)
    func textForm(mode: AQLTextForm, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--text-form", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.textForm == mode)
    }

    @Test("takes the union, null addition and text form of each preset unless given")
    func newBehavioursFollowPreset() throws {
        let options = try MTLSemanticsOptions.parse([])
        let standard = options.aqlOptions(preset: .standard)
        let legacy = options.aqlOptions(preset: .legacy)
        #expect(standard.sequenceUnion == .concatenation)
        #expect(standard.nullAddition == .emptyText)
        #expect(standard.textForm == .joined)
        #expect(legacy.sequenceUnion == .distinct)
        #expect(legacy.nullAddition == .null)
        #expect(legacy.textForm == .bracketed)
        #expect(MTLSemanticsOptions.OptionName.sequenceUnion == "sequence-union")
        #expect(MTLSemanticsOptions.OptionName.nullAddition == "null-addition")
        #expect(MTLSemanticsOptions.OptionName.textForm == "text-form")
        let discussion = MTLSemanticsOptions.discussion(reader: "the templates")
        for name in ["--sequence-union", "--null-addition", "--text-form"] {
            #expect(discussion.contains(name), "\(name)")
        }
    }

    @Test("rejects values that are not union, null addition or text form modes", arguments: [
        "--sequence-union", "--null-addition", "--text-form",
    ])
    func rejectsUnknownNewValues(option: String) {
        #expect(throws: (any Error).self) {
            try MTLSemanticsOptions.parse([option, "sometimes"])
        }
    }

    @Test("parses each dot call mode", arguments: AQLDotCalls.allCases, SemanticsPreset.allCases)
    func dotCalls(mode: AQLDotCalls, preset: SemanticsPreset) throws {
        let options = try MTLSemanticsOptions.parse(["--dot-calls", mode.rawValue])
        #expect(options.mtlOptions(preset: preset).aql.dotCalls == mode)
        #expect(options.aqlOptions(preset: preset).dotCalls == mode)
    }

    @Test("takes the dot calls of each preset unless given")
    func dotCallsFollowPreset() throws {
        let options = try MTLSemanticsOptions.parse([])
        #expect(options.aqlOptions(preset: .standard).dotCalls == .eachElement)
        #expect(options.aqlOptions(preset: .legacy).dotCalls == .collection)
        #expect(options.mtlOptions(preset: .legacy).aql.dotCalls == .collection)
    }

    @Test("names the dot call option and its values, and describes it")
    func dotCallNames() {
        #expect(MTLSemanticsOptions.OptionName.dotCalls == "dot-calls")
        #expect(MTLSemanticsOptions.valueList(AQLDotCalls.self) == "each-element|collection")
        #expect(MTLSemanticsOptions.discussion(reader: "the templates").contains("--dot-calls"))
    }

    @Test("rejects a value that is not a dot call mode", arguments: ["sometimes", "each", "Collection"])
    func rejectsUnknownDotCalls(value: String) {
        #expect(throws: (any Error).self) {
            try MTLSemanticsOptions.parse(["--dot-calls", value])
        }
    }

    @Test("changes only the dot calls when the option is given")
    func overridesDotCallsOnly() throws {
        let options = try MTLSemanticsOptions.parse(["--dot-calls", "each-element"])
        var expected = MTLOptions.legacy
        expected.aql.dotCalls = .eachElement
        #expect(options.mtlOptions(preset: .legacy) == expected)
    }

    @Test("changes only the behaviour that an option names")
    func overridesOneBehaviour() throws {
        let options = try MTLSemanticsOptions.parse(["--block-line-breaks", "acceleo"])
        var expected = MTLOptions.legacy
        expected.blockLineBreaks = .acceleo
        #expect(options.mtlOptions(preset: .legacy) == expected)
    }

    @Test("rejects values that are not modes", arguments: [
        "--block-line-breaks", "--collection-parameters", "--collection-arguments", "--collection-kinds",
        "--single-value-collections", "--container-lookup",
    ])
    func rejectsUnknownValues(option: String) {
        #expect(throws: (any Error).self) {
            try MTLSemanticsOptions.parse([option, "sometimes"])
        }
    }

    @Test("names the options and their values")
    func mtlNames() {
        #expect(MTLSemanticsOptions.OptionName.blockLineBreaks == "block-line-breaks")
        #expect(MTLSemanticsOptions.OptionName.collectionParameters == "collection-parameters")
        #expect(MTLSemanticsOptions.OptionName.checkLetTypes == "check-let-types")
        #expect(MTLSemanticsOptions.OptionName.cacheContainers == "cache-containers")
        #expect(MTLSemanticsOptions.OptionName.collectionArguments == "collection-arguments")
        #expect(MTLSemanticsOptions.OptionName.collectionKinds == "collection-kinds")
        #expect(MTLSemanticsOptions.OptionName.singleValueCollections == "single-value-collections")
        #expect(MTLSemanticsOptions.OptionName.containerLookup == "container-lookup")
        #expect(MTLSemanticsOptions.valueList(AQLCollectionArguments.self) == "whole|first-element")
        let discussion = MTLSemanticsOptions.discussion(reader: "the templates")
        #expect(discussion.contains("the templates"))
        #expect(discussion.contains("--[no-]check-let-types"))
        #expect(discussion.contains("--semantics legacy"))
    }

    @Test("applies the behaviours to generation options, keeping unset features and let mismatches")
    func appliesToGenerationOptions() throws {
        let options = try MTLSemanticsOptions.parse(["--collection-kinds", "sequences"])
        var generation = GenerationOptions(mtlOptions: .standard)
        generation.mtlOptions.unsetFeatureReads = .undefined
        generation.mtlOptions.letTypeMismatches = .skip

        options.apply(to: &generation, preset: .standard)

        #expect(generation.mtlOptions.aql.collectionKinds == .sequences)
        #expect(generation.mtlOptions.blockLineBreaks == .acceleo)
        #expect(generation.mtlOptions.unsetFeatureReads == .undefined)
        #expect(generation.mtlOptions.letTypeMismatches == .skip)

        try MTLSemanticsOptions.parse([]).apply(to: &generation, preset: .legacy)
        #expect(generation.mtlOptions.blockLineBreaks == .kept)
        #expect(generation.mtlOptions.unsetFeatureReads == .undefined)
        #expect(generation.mtlOptions.letTypeMismatches == .skip)
    }

    // MARK: - ATL options

    @Test("leaves the ATL behaviours to the preset unless given")
    func atlFollowsPreset() throws {
        let options = try ATLSemanticsOptions.parse([])
        #expect(options.atlOptions(preset: .standard) == .standard)
        #expect(options.atlOptions(preset: .legacy) == .legacy)
    }

    @Test("parses each range syntax", arguments: ATLCollectionRangeSyntax.allCases, SemanticsPreset.allCases)
    func collectionRangeSyntax(syntax: ATLCollectionRangeSyntax, preset: SemanticsPreset) throws {
        let options = try ATLSemanticsOptions.parse(["--collection-range-syntax", syntax.rawValue])
        #expect(options.atlOptions(preset: preset).collectionRangeSyntax == syntax)
    }

    @Test("rejects a range syntax that does not exist")
    func rejectsUnknownSyntax() {
        #expect(throws: (any Error).self) {
            try ATLSemanticsOptions.parse(["--collection-range-syntax", "sometimes"])
        }
    }

    @Test("parses each integer division", arguments: ATLIntegerDivision.allCases, SemanticsPreset.allCases)
    func integerDivision(division: ATLIntegerDivision, preset: SemanticsPreset) throws {
        let options = try ATLSemanticsOptions.parse(["--integer-division", division.rawValue])
        #expect(options.atlOptions(preset: preset).integerDivision == division)
    }

    @Test("takes the integer division of each preset unless given")
    func integerDivisionFollowsPreset() throws {
        let options = try ATLSemanticsOptions.parse([])
        #expect(options.atlOptions(preset: .standard).integerDivision == .real)
        #expect(options.atlOptions(preset: .legacy).integerDivision == .truncating)
    }

    @Test("rejects an integer division that does not exist")
    func rejectsUnknownDivision() {
        #expect(throws: (any Error).self) {
            try ATLSemanticsOptions.parse(["--integer-division", "rounding"])
        }
    }

    @Test("leaves strict AQL off in both presets unless --strict-aql is given", arguments: SemanticsPreset.allCases)
    func strictAQL(preset: SemanticsPreset) throws {
        #expect(!(try MTLSemanticsOptions.parse([]).aqlOptions(preset: preset).strict))
        let strict = try MTLSemanticsOptions.parse(["--strict-aql"])
        #expect(strict.aqlOptions(preset: preset).strict)
        #expect(strict.mtlOptions(preset: preset).aql.strict)
        #expect(MTLSemanticsOptions.OptionName.strictAQL == "strict-aql")
        #expect(MTLSemanticsOptions.discussion(reader: "the templates").contains("--strict-aql"))
    }

    @Test("names the integer division option and describes it")
    func integerDivisionNames() {
        #expect(ATLSemanticsOptions.OptionName.integerDivision == "integer-division")
        let discussion = ATLSemanticsOptions.discussion(reader: "the transformation")
        #expect(discussion.contains("--integer-division"))
        #expect(discussion.contains("real"))
        #expect(discussion.contains("truncating"))
    }

    @Test("names the ATL option and describes it")
    func atlNames() {
        #expect(ATLSemanticsOptions.OptionName.collectionRangeSyntax == "collection-range-syntax")
        let discussion = ATLSemanticsOptions.discussion(reader: "the transformation")
        #expect(discussion.contains("--collection-range-syntax"))
        #expect(discussion.contains("the transformation"))
        #expect(discussion.contains("--semantics legacy"))
    }

    @Test("applies the ATL behaviours to import options")
    func appliesToImportOptions() throws {
        var imports = GenModelImportOptions(atlOptions: .standard)
        try ATLSemanticsOptions.parse([]).apply(to: &imports, preset: .legacy)
        #expect(imports.atlOptions == .legacy)
        try ATLSemanticsOptions.parse(["--collection-range-syntax", "ocl"]).apply(to: &imports, preset: .legacy)
        #expect(imports.atlOptions.collectionRangeSyntax == .ocl)
        try ATLSemanticsOptions.parse(["--integer-division", "real"]).apply(to: &imports, preset: .legacy)
        #expect(imports.atlOptions.integerDivision == .real)
        #expect(imports.atlOptions.collectionRangeSyntax == .eclipse)
    }

    // MARK: - Combined

    @Test("lets an option override the preset whatever their order")
    func precedence() throws {
        let before = try SemanticsCommand.parse([
            "--block-line-breaks", "acceleo", "--collection-range-syntax", "ocl", "--semantics", "legacy",
        ])
        let after = try SemanticsCommand.parse([
            "--semantics", "legacy", "--block-line-breaks", "acceleo", "--collection-range-syntax", "ocl",
        ])
        for command in [before, after] {
            let mtl = command.mtl.mtlOptions(preset: command.semantics.semantics)
            #expect(mtl.blockLineBreaks == .acceleo)
            #expect(mtl.collectionParameters == .exact)
            #expect(mtl.aql == .legacy)
            let atl = command.atl.atlOptions(preset: command.semantics.semantics)
            #expect(atl.collectionRangeSyntax == .ocl)
        }
    }
}
