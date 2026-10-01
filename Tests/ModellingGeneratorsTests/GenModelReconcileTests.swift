import ECore
import Foundation
import Testing

@testable import ModellingGenerators

/// Replaces text in a document and fails if the text is not there.
///
/// - Parameters:
///   - text: The document.
///   - target: The text to replace.
///   - replacement: The new text.
/// - Returns: The edited document.
func edited(_ text: String, replacing target: String, with replacement: String) throws -> String {
    try #require(text.contains(target), "'\(target)' is not in the document")
    return text.replacingOccurrences(of: target, with: replacement)
}

@Suite("Reloading an existing generator model")
struct GenModelReconcileTests {
    /// Generates the library model, applies the edits a user might make, and changes the source model.
    @MainActor
    private func editedLibrary() async throws -> (project: FixtureProject, genModel: URL) {
        let generated = try await generate(OracleCase.all[0])
        let project = generated.project
        var text = generated.text
        text = try edited(text, replacing: #"modelName="Library""#, with: #"modelName="MyLibrary""#)
        text = try edited(text, replacing: #"copyrightText="Copyright 2026 Example Pty Ltd""#, with: #"copyrightText="Mine""#)
        text = try edited(text, replacing: #"complianceLevel="17.0""#, with: #"complianceLevel="8.0""#)
        text = try edited(text, replacing: #" operationReflection="true""#, with: "")
        text = try edited(text, replacing: #"<genPackages prefix="Library""#, with: #"<genPackages prefix="Lib""#)
        text = try edited(
            text, replacing: #"<genClasses ecoreClass="library.ecore#//Book">"#,
            with: #"<genClasses image="false" ecoreClass="library.ecore#//Book">"#)
        text = try edited(
            text, replacing: #"<genFeatures ecoreFeature="ecore:EAttribute library.ecore#//Book/pages"/>"#,
            with: #"<genFeatures property="Readonly" propertyDescription="Page count" ecoreFeature="ecore:EAttribute library.ecore#//Book/pages"/>"#)
        text = try edited(
            text, replacing: #" modelPluginID="library""#,
            with: #" modelPluginID="library" usedGenPackages="platform:/plugin/org.example/model/Other.genmodel#//other""#)
        try text.write(to: generated.result.url, atomically: true, encoding: .utf8)

        var ecore = try String(contentsOf: project.model("library.ecore"), encoding: .utf8)
        ecore = try edited(
            ecore,
            replacing: """
                <eStructuralFeatures xsi:type="ecore:EAttribute" name="aliases" upperBound="-1"
                        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>

                """, with: "")
        ecore = try edited(
            ecore,
            replacing: ##"<eStructuralFeatures xsi:type="ecore:EAttribute" name="isbn" eType="#//ISBN"/>"##,
            with: """
                <eStructuralFeatures xsi:type="ecore:EAttribute" name="isbn" eType="#//ISBN"/>
                    <eStructuralFeatures xsi:type="ecore:EAttribute" name="subtitle"
                        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
                """)
        try ecore.write(to: project.model("library.ecore"), atomically: true, encoding: .utf8)
        return (project, generated.result.url)
    }

    @Test("Settings of the existing model are kept and the structure follows the sources")
    @MainActor
    func keepsSettingsAndSynchronisesStructure() async throws {
        let (project, genModel) = try await editedLibrary()
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.reload = genModel
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("library.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)

        #expect(result.reloaded)
        #expect(text.contains(#"modelName="MyLibrary""#))
        #expect(text.contains(#"copyrightText="Mine""#))
        #expect(text.contains(#"complianceLevel="8.0""#))
        #expect(!text.contains("operationReflection"))
        #expect(text.contains(#"<genPackages prefix="Lib" basePackage="org.example""#))
        #expect(text.contains(#"<genClasses image="false" ecoreClass="library.ecore#//Book">"#))
        #expect(text.contains(#"property="Readonly" propertyDescription="Page count" ecoreFeature="ecore:EAttribute library.ecore#//Book/pages""#))
        #expect(text.contains(#"usedGenPackages="platform:/plugin/org.example/model/Other.genmodel#//other""#))
        #expect(text.contains(#"<genFeatures ecoreFeature="ecore:EAttribute library.ecore#//Book/subtitle"/>"#))
        #expect(!text.contains("Writer/aliases"))
        #expect(text.contains(#"importerID="org.eclipse.emf.importer.ecore""#))
        #expect(text.contains("<foreignModel>library.ecore</foreignModel>"))
    }

    @Test("Explicit options take precedence over the existing model")
    @MainActor
    func explicitOptionsWin() async throws {
        let (project, genModel) = try await editedLibrary()
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.reload = genModel
        options.basePackage = "org.other"
        options.prefix = "Fresh"
        options.copyright = "Brand new"
        options.complianceLevel = "21.0"
        options.modelPluginID = "other.plugin"
        options.modelDirectory = "/other/src"
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("library.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"copyrightText="Brand new""#))
        #expect(text.contains(#"complianceLevel="21.0""#))
        #expect(text.contains(#"modelPluginID="other.plugin""#))
        #expect(text.contains(#"modelDirectory="/other/src""#))
        #expect(text.contains(#"<genPackages prefix="Fresh" basePackage="org.other""#))
        #expect(text.contains(#"modelName="MyLibrary""#))
    }

    @Test("A package prefix given for one package overrides only that package")
    @MainActor
    func packagePrefixOverridesOnReload() async throws {
        let generated = try await generate(OracleCase.all[3])
        defer { generated.project.remove() }
        var text = generated.text
        text = try edited(text, replacing: #"<nestedGenPackages prefix="People""#, with: #"<nestedGenPackages prefix="Staff""#)
        text = try edited(text, replacing: #"<nestedGenPackages prefix="Proj""#, with: #"<nestedGenPackages prefix="Work""#)
        text = try edited(
            text, replacing: #"<genEnums typeSafeEnumCompatible="false""#,
            with: #"<genEnums typeSafeEnumCompatible="true""#)
        try text.write(to: generated.result.url, atomically: true, encoding: .utf8)

        var options = GenModelImportOptions()
        options.reload = generated.result.url
        options.packagePrefixes = ["projects": "Fresh"]
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("company.ecore")], options: options)
        let reloaded = try String(contentsOf: result.url, encoding: .utf8)
        #expect(reloaded.contains(#"<nestedGenPackages prefix="Staff""#))
        #expect(reloaded.contains(#"<nestedGenPackages prefix="Fresh""#))
        #expect(!reloaded.contains("typeSafeEnumCompatible"))
    }

    @Test("The existing model's compliance level is kept unless one is requested")
    @MainActor
    func complianceLevelIsKept() async throws {
        let generated = try await generate(OracleCase.all[1])
        defer { generated.project.remove() }
        let old = try edited(generated.text, replacing: #"complianceLevel="17.0""#, with: #"complianceLevel="11.0""#)
        try old.write(to: generated.result.url, atomically: true, encoding: .utf8)
        var options = GenModelImportOptions()
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("families.ecore")], options: options)
        #expect(try String(contentsOf: result.url, encoding: .utf8).contains(#"complianceLevel="11.0""#))
    }

    @Test("Elements are matched by name, so a renamed class starts afresh")
    @MainActor
    func renamedClassStartsAfresh() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        let old = try edited(
            generated.text, replacing: #"<genClasses ecoreClass="library.ecore#//Writer">"#,
            with: #"<genClasses image="false" ecoreClass="library.ecore#//Writer">"#)
        try old.write(to: generated.result.url, atomically: true, encoding: .utf8)
        var ecore = try String(contentsOf: generated.project.model("library.ecore"), encoding: .utf8)
        ecore = ecore.replacingOccurrences(of: #"name="Writer""#, with: #"name="Author""#)
            .replacingOccurrences(of: "#//Writer", with: "#//Author")
        try ecore.write(to: generated.project.model("library.ecore"), atomically: true, encoding: .utf8)
        var options = GenModelImportOptions()
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("library.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"<genClasses ecoreClass="library.ecore#//Author">"#))
        #expect(!text.contains("Writer"))
    }

    @Test("The label feature of a class is kept by feature name")
    @MainActor
    func labelFeatureIsKept() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        let old = try edited(
            generated.text, replacing: #"<genClasses ecoreClass="library.ecore#//Book">"#,
            with: ##"<genClasses ecoreClass="library.ecore#//Book" labelFeature="#//@genPackages.0/@genClasses.2/@genFeatures.1">"##)
        try old.write(to: generated.result.url, atomically: true, encoding: .utf8)
        var options = OracleCase.all[0].options
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("library.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(##"labelFeature="#//@genPackages.0/@genClasses.2/@genFeatures.1""##))
    }

    @Test("Many-valued settings of the existing model are kept")
    @MainActor
    func manyValuedSettingsAreKept() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        let old = try edited(
            generated.text, replacing: "  <foreignModel>library.ecore</foreignModel>\n",
            with: """
                  <foreignModel>library.ecore</foreignModel>
                  <modelPluginVariables>EMF_CORE=org.eclipse.emf.ecore</modelPluginVariables>
                  <modelPluginVariables>EMF_COMMON=org.eclipse.emf.common</modelPluginVariables>

                """)
        try old.write(to: generated.result.url, atomically: true, encoding: .utf8)
        var options = OracleCase.all[0].options
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("library.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains("<modelPluginVariables>EMF_CORE=org.eclipse.emf.ecore</modelPluginVariables>"))
        #expect(text.contains("<modelPluginVariables>EMF_COMMON=org.eclipse.emf.common</modelPluginVariables>"))
    }

    @Test("Reloading an unchanged model reproduces it")
    @MainActor
    func reloadIsIdempotent() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        var options = OracleCase.all[0].options
        options.reload = generated.result.url
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [generated.project.model("library.ecore")], options: options)
        #expect(try String(contentsOf: result.url, encoding: .utf8) == generated.text)
    }

    @Test("A missing model to reload is reported")
    @MainActor
    func missingReload() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.reload = project.root.appendingPathComponent("nothing.genmodel")
        await #expect(throws: GenerationError.self) {
            _ = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: [project.model("families.ecore")], options: options)
        }
    }

    @Test("A model to reload that is not a generator model is reported")
    @MainActor
    func unreadableReload() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.reload = project.model("families.ecore")
        do {
            _ = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: [project.model("families.ecore")], options: options)
            Issue.record("Expected the reload to fail")
        } catch let error as GenerationError {
            guard case .reloadModelUnreadable = error else {
                Issue.record("Unexpected error \(error)")
                return
            }
            #expect(error.description.contains("cannot be reloaded"))
        }
    }
}
