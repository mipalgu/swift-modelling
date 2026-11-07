//
// ModelExportTests.swift
// ModellingGeneratorsTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing

@testable import ModellingGenerators

/// The behaviour of model exports and of the verification services apart from the text that
/// they produce.
@Suite("Model exports")
struct ModelExportTests {
    /// A scratch output directory, removed by the caller.
    ///
    /// - Returns: A new directory.
    /// - Throws: An error if the directory cannot be created.
    private func scratchDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swift-modelling-model-export-tests").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The bundled verification sets are languages and can export models.
    @Test("The verification targets are bundled template sets that export models", arguments: VerificationTarget.allCases)
    func bundledSets(target: VerificationTarget) throws {
        #expect(TemplateSet.availableLanguages().contains(target.templateSetName))
        let set = try TemplateSet.assemble(language: target.templateSetName)
        defer { set.remove() }
        #expect(set.descriptor.modelTemplate != nil)
        #expect(set.descriptor.modelFileCountTemplate != nil)
        #expect(set.descriptor.fileCountTemplate != nil)
    }

    /// The shared directory of verification queries is not a language.
    @Test("The shared verification queries are not a language")
    func sharedQueriesAreNoLanguage() {
        #expect(!TemplateSet.availableLanguages().contains("verification"))
    }

    /// The descriptor reads and writes the members of model exports, and leaves them out by default.
    @Test("The descriptor reads the model export members")
    func descriptorMembers() throws {
        let text = #"""
            { "name": "x", "mainModule": "m", "mainTemplate": "t",
              "modelTemplate": "exportModel", "modelFileCountTemplate": "countModel" }
            """#
        let descriptor = try JSONDecoder().decode(TemplateSetDescriptor.self, from: Data(text.utf8))
        #expect(descriptor.modelTemplate == "exportModel")
        #expect(descriptor.modelFileCountTemplate == "countModel")
        let plain = TemplateSetDescriptor(name: "x", mainModule: "m", mainTemplate: "t")
        #expect(plain.modelTemplate == nil)
        #expect(plain.modelFileCountTemplate == nil)
        let reread = try JSONDecoder().decode(TemplateSetDescriptor.self, from: try JSONEncoder().encode(descriptor))
        #expect(reread == descriptor)
    }

    /// The progress reports of a model export carry the total of its file count template.
    @Test("A model export reports progress with its total")
    @MainActor
    func progressHasTotal() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let updates = ProgressCollector()
        let result = try await GenerationPipeline.generate(
            modelURL: LendingFixtures.lendingModel, metamodelURL: LendingFixtures.lendingMetamodel,
            language: VerificationTarget.tla.templateSetName, outputDirectory: output,
            progress: { updates.add($0) })
        #expect(result.files.map(\.lastPathComponent).sorted() == ["lending_instance.cfg", "lending_instance.tla"])
        #expect(result.language == VerificationTarget.tla.templateSetName)
        #expect(result.packageCount == 1)
        #expect(updates.updates.last == GenerationProgressUpdate(message: "Done", completed: 2, total: 2))
    }

    /// The metamodel exports report progress with the total of their file count template.
    @Test("A metamodel export reports progress with its total")
    @MainActor
    func metamodelProgressHasTotal() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let updates = ProgressCollector()
        let result = try await GenerationPipeline.generate(
            inputURL: LendingFixtures.lendingMetamodel, language: VerificationTarget.eventB.templateSetName,
            outputDirectory: output, importOptions: GenModelImportOptions(atlOptions: .standard),
            options: GenerationOptions(mtlOptions: .standard), progress: { updates.add($0) })
        #expect(result.files.map(\.lastPathComponent).sorted() == ["lending_ctx.bucx", "lending_machine.bumx"])
        #expect(updates.updates.last == GenerationProgressUpdate(message: "Done", completed: 2, total: 2))
    }

    /// A model export reads unset features as undefined, whatever the options say.
    @Test("A model export reads unset features as undefined")
    @MainActor
    func unsetFeaturesAreUndefined() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        var options = GenerationOptions(mtlOptions: .standard)
        options.unsetFeatureReads = .defaults
        let result = try await GenerationPipeline.generate(
            modelURL: LendingFixtures.lendingModel, metamodelURL: LendingFixtures.lendingMetamodel,
            language: VerificationTarget.alloy.templateSetName, outputDirectory: output, options: options)
        let file = try #require(result.files.first)
        let expected = try VerificationGoldenFiles.directory(for: .alloy).appendingPathComponent(file.lastPathComponent)
        #expect(try String(contentsOf: file, encoding: .utf8) == String(contentsOf: expected, encoding: .utf8))
    }

    /// A generator model names the Ecore models that are the metamodel of an export.
    @Test("A generator model can be the metamodel of a model export")
    @MainActor
    func generatorModelAsMetamodel() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let project = output.appendingPathComponent("project")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let ecore = project.appendingPathComponent("lending.ecore")
        try FileManager.default.copyItem(at: LendingFixtures.lendingMetamodel, to: ecore)
        var importOptions = GenModelImportOptions(atlOptions: .standard)
        importOptions.output = project.appendingPathComponent("lending.genmodel")
        let genModel = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [ecore], options: importOptions)
        let exported = output.appendingPathComponent("out")
        let result = try await GenerationPipeline.generate(
            modelURL: LendingFixtures.lendingModel, metamodelURL: genModel.url,
            language: VerificationTarget.lean.templateSetName, outputDirectory: exported)
        let file = try #require(result.files.first)
        let expected = try VerificationGoldenFiles.directory(for: .lean).appendingPathComponent(file.lastPathComponent)
        #expect(try String(contentsOf: file, encoding: .utf8) == String(contentsOf: expected, encoding: .utf8))
    }

    /// A metamodel that does not exist is reported.
    @Test("A missing metamodel is reported")
    @MainActor
    func missingMetamodel() async throws {
        let missing = LendingFixtures.lendingDirectory.appendingPathComponent("missing.ecore")
        await #expect(throws: GenerationError.sourceModelNotFound(missing.standardizedFileURL.path)) {
            _ = try await GenerationPipeline.generate(
                modelURL: LendingFixtures.lendingModel, metamodelURL: missing, language: "alloy",
                outputDirectory: FileManager.default.temporaryDirectory)
        }
    }

    /// A model that does not exist is reported.
    @Test("A missing model is reported")
    @MainActor
    func missingModel() async throws {
        let missing = LendingFixtures.lendingDirectory.appendingPathComponent("missing.xmi")
        await #expect(throws: GenerationError.modelNotFound(missing.standardizedFileURL.path)) {
            _ = try await GenerationPipeline.generate(
                modelURL: missing, metamodelURL: LendingFixtures.lendingMetamodel, language: "alloy",
                outputDirectory: FileManager.default.temporaryDirectory)
        }
    }

    /// A model that cannot be read is reported with its path.
    @Test("An unreadable model is reported")
    @MainActor
    func unreadableModel() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let model = output.appendingPathComponent("broken.xmi")
        try "<?xml version=\"1.0\"?>\n<unclosed".write(to: model, atomically: true, encoding: .utf8)
        do {
            _ = try await GenerationPipeline.generate(
                modelURL: model, metamodelURL: LendingFixtures.lendingMetamodel, language: "alloy",
                outputDirectory: output)
            Issue.record("A broken model was exported")
        } catch GenerationError.modelUnreadable(let path, _) {
            #expect(path == model.standardizedFileURL.path)
        }
    }

    /// A metamodel that cannot be read is reported with its path.
    @Test("An unreadable metamodel is reported")
    @MainActor
    func unreadableMetamodel() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let metamodel = output.appendingPathComponent("broken.ecore")
        try "<?xml version=\"1.0\"?>\n<unclosed".write(to: metamodel, atomically: true, encoding: .utf8)
        do {
            _ = try await GenerationPipeline.generate(
                modelURL: LendingFixtures.lendingModel, metamodelURL: metamodel, language: "alloy",
                outputDirectory: output)
            Issue.record("A model of a broken metamodel was exported")
        } catch GenerationError.sourceModelUnreadable(let path, _) {
            #expect(path == metamodel.standardizedFileURL.path)
        } catch GenerationError.noRootPackage(let path) {
            #expect(path == metamodel.standardizedFileURL.path)
        }
    }

    /// A template set without a model template cannot export models.
    @Test("A template set without a model template is reported")
    @MainActor
    func missingModelTemplate() async throws {
        let output = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        await #expect(throws: GenerationError.noModelTemplate("java")) {
            _ = try await GenerationPipeline.generate(
                modelURL: LendingFixtures.lendingModel, metamodelURL: LendingFixtures.lendingMetamodel,
                language: "java", outputDirectory: output)
        }
    }

    /// The errors of model exports describe themselves.
    @Test("The errors of model exports have descriptions")
    func errorDescriptions() {
        #expect(GenerationError.modelNotFound("a.xmi").description == "The model 'a.xmi' does not exist")
        #expect(GenerationError.modelUnreadable("a.xmi", "why").description == "The model 'a.xmi' cannot be read: why")
        #expect(GenerationError.noModelTemplate("java").description == "The template set 'java' cannot export models")
        #expect(TranslationError("x").description == "x")
    }

    /// The model alias, the name variable and the Ecore model prefix are fixed.
    @Test("The names of model exports are fixed")
    func constants() {
        #expect(TemplateSetConstants.modelNameVariable == "modelName")
        #expect(TemplateSetConstants.modelAlias == "MODEL")
        #expect(TemplateSetConstants.ecoreModelAliasPrefix == "ECORE_")
    }

    /// The root package of an export is the one that declares the class of the root object.
    @Test("The root package declares the class of the root object")
    func rootPackage() {
        let first = EPackage(name: "first", nsURI: "urn:first", nsPrefix: "first", eClassifiers: [EClass(name: "A")])
        let b = EClass(name: "B")
        let nested = EPackage(name: "nested", nsURI: "urn:nested", nsPrefix: "nested", eClassifiers: [b])
        let second = EPackage(name: "second", nsURI: "urn:second", nsPrefix: "second", eSubpackages: [nested])
        let object = DynamicEObject(eClass: b)
        #expect(GenerationPipeline.rootPackage(declaring: object, among: [first, second])?.name == "second")
        let stranger = DynamicEObject(eClass: EClass(name: "C"))
        #expect(GenerationPipeline.rootPackage(declaring: stranger, among: [first, second])?.name == "first")
        #expect(GenerationPipeline.rootPackage(declaring: stranger, among: []) == nil)
    }

    /// The kinds of values of the data types of the lending metamodel.
    @Test("Data types are classified by name and instance class")
    func dataTypeKinds() {
        #expect(MetamodelIndex.kind(ofDataType: "EInt", instanceClass: nil) == .integer)
        #expect(MetamodelIndex.kind(ofDataType: "EBooleanObject", instanceClass: nil) == .boolean)
        #expect(MetamodelIndex.kind(ofDataType: "Isbn", instanceClass: "java.lang.String") == .string)
        #expect(MetamodelIndex.kind(ofDataType: "Count", instanceClass: "long") == .integer)
        #expect(MetamodelIndex.kind(ofDataType: "Flag", instanceClass: "boolean") == .boolean)
        #expect(MetamodelIndex.kind(ofDataType: "EDouble", instanceClass: nil) == .uninterpreted("EDouble"))
    }

    /// The index resolves inherited features, conformance and concrete subclasses.
    @Test("The metamodel index resolves inheritance")
    func indexResolvesInheritance() async throws {
        let index = MetamodelIndex(packages: [try await LendingFixtures.lendingPackage()])
        #expect(index.lineage(of: "ReferenceBook") == ["ReferenceBook", "Book", "Restricted", "Item", "Named"])
        #expect(index.conforms("ReferenceBook", to: "Restricted"))
        #expect(!index.conforms("Book", to: "Restricted"))
        #expect(index.concreteSubclasses(of: "Item") == ["Book", "Periodical", "ReferenceBook"])
        #expect(index.feature(named: "name", in: "Member")?.owner == "Named")
        #expect(index.feature(named: "loans", in: "Member")?.isMany == true)
        #expect(index.feature(named: "loan", in: "Book")?.isOptional == true)
        #expect(index.feature(named: "loanCount", in: "Member")?.isDerived == true)
        #expect(index.enumerations["Status"] == ["AVAILABLE", "ON_LOAN", "WITHDRAWN"])
        #expect(index.dataTypes["Isbn"] == .string)
    }

    /// Event-B machines declare the populations of the classes and all exported features as
    /// variables.
    @Test("Classes and exported features are the variables of Event-B machines")
    func eventBVariables() async throws {
        let index = MetamodelIndex(packages: [try await LendingFixtures.lendingPackage()])
        let variables = VerificationServices.variables(of: index, target: .eventB)
        #expect(variables.contains("Member_age"))
        #expect(variables.contains("Branch_code"))
        #expect(variables.contains("Member"))
        #expect(variables.contains("Restricted"))
        #expect(!variables.contains("Member_loanCount"))
    }

    /// Invariants in the before-after predicate of an Event-B initialisation prime the classes
    /// and features.
    @Test("Primed Event-B invariants prime classes and features")
    func primedEventBInvariant() async throws {
        let translator = InvariantTranslator(packages: [try await LendingFixtures.lendingPackage()])
        let primed = VerificationServices.variables(of: translator.index, target: .eventB)
        let age = translator.translate(className: "Member", constraint: "AgeRestriction", target: .eventB, primed: primed)
        #expect(age == .success(
            "∀self·self ∈ Member' ⇒ (∀l·l ∈ Member_loans'[{self}] ⇒ ((Loan_item'(l) ∈ Restricted') ⇒ (Member_age'(self) ≥ Restricted_minimumAge'(Loan_item'(l)))))"))
        let all = translator.translate(text: "Loan.allInstances()->notEmpty()", className: "Member", target: .eventB, primed: primed)
        #expect(all == .success("∀self·self ∈ Member' ⇒ (Loan' ≠ ∅)"))
    }

    /// String literals are escaped.
    @Test("String literals are escaped")
    func stringLiterals() {
        #expect(VerificationTarget.alloy.stringLiteral("a \"b\" \\ c\n\t") == #""a \"b\" \\ c\n\t""#)
    }

    /// Each verification target names the template set of the same name.
    @Test("Each verification target names its template set")
    func targetNames() {
        #expect(VerificationTarget.allCases.map(\.templateSetName) == ["alloy", "tla", "eventb", "lean"])
        #expect(VerificationTarget.isTarget("eventb"))
        #expect(!VerificationTarget.isTarget("java"))
    }
}
