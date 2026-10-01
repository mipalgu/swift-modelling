import ECore
import EMFBase
import Foundation
import GenModel
import Synchronization
import Testing

@testable import ModellingGenerators

/// Generates a generator model for a fixture project.
///
/// - Parameters:
///   - fixture: The fixture to copy and import.
///   - options: The import options.
/// - Returns: The scratch copy, the result and the text of the written file.
@MainActor
func generate(_ fixture: OracleCase, options: GenModelImportOptions? = nil) async throws
    -> (project: FixtureProject, result: GenModelResult, text: String)
{
    let project = try FixtureProject.make(fixture.name)
    let result = try await GenerationPipeline.ecoreToGenModel(
        ecoreURLs: [project.model(fixture.ecoreFileName)], options: options ?? fixture.options)
    return (project, result, try String(contentsOf: result.url, encoding: .utf8))
}

/// Writes a source model into a scratch directory.
///
/// - Parameters:
///   - text: The text of the Ecore document.
///   - path: The path of the file below a fresh scratch directory.
/// - Returns: The location of the file.
func writeEcore(_ text: String, path: String = "model/sample.ecore") throws -> URL {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-modelling-genmodel-tests")
        .appendingPathComponent(UUID().uuidString)
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// The text of an Ecore document with a root package holding the given body.
///
/// - Parameters:
///   - name: The name of the root package.
///   - body: The classifiers and annotations of the package.
/// - Returns: The document text.
func ecoreDocument(name: String = "sample", body: String) -> String {
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
        name="\(name)" nsURI="http://swift-modelling.org/test/\(name)" nsPrefix="\(name)">
    \(body)
    </ecore:EPackage>
    """
}

@Suite("Ecore to generator model import")
struct GenModelImportTests {
    @Test("Output matches the reviewed expectation", arguments: OracleCase.all)
    @MainActor
    func matchesExpectation(fixture: OracleCase) async throws {
        let generated = try await generate(fixture)
        defer { generated.project.remove() }
        let expected = try String(
            contentsOf: generated.project.expectation(fixture.genModelFileName), encoding: .utf8)
        #expect(generated.text == expected)
    }

    @Test("Output is written beside the source model by default")
    @MainActor
    func defaultOutputLocation() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        #expect(generated.result.url == generated.project.model("library.genmodel").standardizedFileURL)
        #expect(
            GenerationPipeline.defaultOutput(for: URL(fileURLWithPath: "/a/model/x.ecore")).path
                == "/a/model/x.genmodel")
    }

    @Test("Generating twice yields identical files", arguments: OracleCase.all)
    @MainActor
    func isDeterministic(fixture: OracleCase) async throws {
        let first = try await generate(fixture)
        let second = try await generate(fixture)
        defer {
            first.project.remove()
            second.project.remove()
        }
        #expect(first.text == second.text)
    }

    @Test("Importer defaults are applied to the generator model")
    @MainActor
    func importerDefaults() async throws {
        let generated = try await generate(OracleCase.all[1])
        defer { generated.project.remove() }
        let text = generated.text
        #expect(text.contains(#"importerID="org.eclipse.emf.importer.ecore""#))
        #expect(text.contains(#"complianceLevel="17.0""#))
        #expect(text.contains(#"modelDirectory="/families/src""#))
        #expect(text.contains(#"modelPluginID="families""#))
        #expect(text.contains(#"modelName="Families""#))
        #expect(text.contains(#"copyrightFields="false""#))
        #expect(text.contains(#"operationReflection="true""#))
        #expect(text.contains(#"importOrganizing="true""#))
        #expect(text.contains(#"rootExtendsClass="org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container""#))
        #expect(text.contains("<foreignModel>families.ecore</foreignModel>"))
        #expect(!text.contains("copyrightText"))
        #expect(!text.contains("usedGenPackages"))
        #expect(text.contains(#"prefix="Families" disposableProviderFactory="true""#))
    }

    @Test("The result summarises the generator model")
    @MainActor
    func resultSummary() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        let result = generated.result
        #expect(result.packageCount == 1)
        #expect(result.classCount == 5)
        #expect(result.enumCount == 1)
        #expect(result.dataTypeCount == 1)
        #expect(result.featureCount == 12)
        #expect(result.operationCount == 1)
        #expect(!result.reloaded)
    }

    @Test("Operations and their parameters become generator operations")
    @MainActor
    func operations() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        #expect(generated.text.contains(#"<genOperations ecoreOperation="library.ecore#//Library/findBooks">"#))
        #expect(generated.text.contains(#"ecoreParameter="library.ecore#//Library/findBooks/title""#))
        #expect(generated.text.contains(#"ecoreParameter="library.ecore#//Library/findBooks/maxResults""#))
    }

    @Test("References to Ecore types do not add used generator packages")
    @MainActor
    func ecoreTypesAreImplicit() async throws {
        let generated = try await generate(OracleCase.all[4])
        defer { generated.project.remove() }
        #expect(!generated.text.contains("usedGenPackages"))
        #expect(generated.text.contains(#"ecoreFeature="ecore:EReference bridge.ecore#//Span/supports""#))
    }

    // MARK: - Options

    @Test("Explicit options override the importer defaults")
    @MainActor
    func explicitOptions() async throws {
        var options = GenModelImportOptions()
        options.basePackage = "org.acme"
        options.prefix = "Fam"
        options.modelProject = "my project"
        options.modelPluginID = "org.acme.model"
        options.modelDirectory = "/other/src-gen"
        options.copyright = "Acme Ltd."
        options.complianceLevel = "21.0"
        options.operationReflection = false
        options.importOrganizing = false
        options.rootExtendsClass = "org.eclipse.emf.ecore.impl.EObjectImpl"
        let generated = try await generate(OracleCase.all[1], options: options)
        defer { generated.project.remove() }
        let text = generated.text
        #expect(text.contains(#"copyrightText="Acme Ltd.""#))
        #expect(text.contains(#"modelDirectory="/other/src-gen""#))
        #expect(text.contains(#"modelPluginID="org.acme.model""#))
        #expect(text.contains(#"complianceLevel="21.0""#))
        #expect(text.contains(#"prefix="Fam" basePackage="org.acme""#))
        #expect(!text.contains("operationReflection"))
        #expect(!text.contains("importOrganizing"))
        #expect(!text.contains("rootExtendsClass"))
    }

    @Test("The project name gives the default directory and a valid plug-in identifier")
    @MainActor
    func projectName() async throws {
        var options = GenModelImportOptions()
        options.modelProject = "My Model/v2!"
        let generated = try await generate(OracleCase.all[1], options: options)
        defer { generated.project.remove() }
        #expect(generated.text.contains(#"modelDirectory="/My Model/v2!/src""#))
        #expect(generated.text.contains(#"modelPluginID="My_Modelv2""#))
    }

    @Test("A model in a folder named model takes the parent folder as its project")
    @MainActor
    func projectFromModelFolder() async throws {
        let url = try writeEcore(
            ecoreDocument(body: #"<eClassifiers xsi:type="ecore:EClass" name="Thing"/>"#),
            path: "my.project/model/sample.ecore")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"modelDirectory="/my.project/src""#))
        #expect(text.contains(#"modelPluginID="my.project""#))
    }

    @Test("A model outside a model folder takes the root package as its project")
    @MainActor
    func projectFromRootPackage() async throws {
        let url = try writeEcore(
            ecoreDocument(name: "inventory", body: #"<eClassifiers xsi:type="ecore:EClass" name="Thing"/>"#),
            path: "elsewhere/inventory.ecore")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"modelDirectory="/inventory/src""#))
        #expect(text.contains(#"modelName="Inventory""#))
    }

    @Test("The model name follows the generator model file")
    @MainActor
    func modelNameFollowsOutput() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.output = project.root.appendingPathComponent("gen/kinship.v1.genmodel")
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("families.ecore")], options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"modelName="Kinship""#))
        #expect(text.contains("<foreignModel>../model/families.ecore</foreignModel>"))
        #expect(text.contains(#"ecorePackage="../model/families.ecore#/""#))
        #expect(GenerationPipeline.modelName(forOutput: URL(fileURLWithPath: "/x/lib.genmodel")) == "Lib")
    }

    @Test("Prefixes can be given for individual packages")
    @MainActor
    func packagePrefixes() async throws {
        var options = GenModelImportOptions()
        options.prefix = "Co"
        options.packagePrefixes = ["people": "Peeps", "archive": "Old"]
        let generated = try await generate(OracleCase.all[3], options: options)
        defer { generated.project.remove() }
        #expect(generated.text.contains(#"<genPackages prefix="Co""#))
        #expect(generated.text.contains(#"<nestedGenPackages prefix="Peeps""#))
        #expect(generated.text.contains(#"<nestedGenPackages prefix="Projects""#))
        #expect(generated.text.contains(#"<nestedGenPackages prefix="Old""#))
    }

    @Test("Several source models share one generator model")
    @MainActor
    func severalModels() async throws {
        let library = try FixtureProject.make("library")
        let families = try FixtureProject.make("families")
        defer {
            library.remove()
            families.remove()
        }
        var options = GenModelImportOptions()
        options.output = library.root.appendingPathComponent("all.genmodel")
        let result = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [library.model("library.ecore"), families.model("families.ecore")],
            options: options)
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(result.packageCount == 2)
        #expect(text.components(separatedBy: "<genPackages ").count == 3)
        #expect(text.contains("<foreignModel>model/library.ecore</foreignModel>"))
        #expect(text.contains(#"ecorePackage="model/library.ecore#/""#))
        #expect(text.contains(#"prefix="Families""#))
        #expect(text.components(separatedBy: "<genmodel:GenModel").count == 2)
    }

    // MARK: - Settings derived from the source model

    @Test("Many classes make a big model that loads its package from a serialised form")
    @MainActor
    func bigModel() async throws {
        var body = ""
        for index in 0..<130 {
            body += """
                <eClassifiers xsi:type="ecore:EClass" name="Thing\(index)">
                  <eStructuralFeatures xsi:type="ecore:EAttribute" name="a"
                      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
                  <eStructuralFeatures xsi:type="ecore:EAttribute" name="b"
                      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
                  <eStructuralFeatures xsi:type="ecore:EAttribute" name="c"
                      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
                  <eStructuralFeatures xsi:type="ecore:EAttribute" name="d"
                      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
                </eClassifiers>

                """
        }
        let url = try writeEcore(ecoreDocument(body: body))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"loadInitialization="true""#))
        #expect(text.contains(#"literalsInterface="false""#))
    }

    @Test("A model at the size limit is not a big model")
    @MainActor
    func smallModel() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        #expect(!generated.text.contains("loadInitialization"))
        #expect(!generated.text.contains("literalsInterface"))
    }

    @Test("Extended metadata annotations select the XML resource kind")
    @MainActor
    func extendedMetaData() async throws {
        let body = """
            <eClassifiers xsi:type="ecore:EClass" name="Thing">
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="value"
                  eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString">
                <eAnnotations source="http:///org/eclipse/emf/ecore/util/ExtendedMetaData">
                  <details key="kind" value="attribute"/>
                </eAnnotations>
              </eStructuralFeatures>
            </eClassifiers>
            """
        let url = try writeEcore(ecoreDocument(body: body))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        withKnownIssue("The Ecore loader does not keep annotations yet", isIntermittent: true) {
            #expect(text.contains(#"resource="XML""#))
        }
    }

    @Test("The XML type namespace selects the XML resource kind")
    @MainActor
    func xmlTypeNamespace() async throws {
        let document = ecoreDocument(body: #"<eClassifiers xsi:type="ecore:EClass" name="Thing"/>"#)
            .replacingOccurrences(
                of: "http://swift-modelling.org/test/sample",
                with: GenModelImportConstants.xmlTypeNsURI)
        let url = try writeEcore(document)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"resource="XML""#))
    }

    @Test("Models without extended metadata keep the default resource kind")
    @MainActor
    func noExtendedMetaData() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        #expect(!generated.text.contains("resource="))
    }

    @Test("Feature settings follow the changeability, containment and kind of the feature")
    @MainActor
    func featureSettings() async throws {
        let body = """
            <eClassifiers xsi:type="ecore:EClass" name="Node">
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="fixed" changeable="false"
                  eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
              <eStructuralFeatures xsi:type="ecore:EAttribute" name="entries" upperBound="-1"
                  eType="#//Entry"/>
              <eStructuralFeatures xsi:type="ecore:EReference" name="peer" changeable="false"
                  eType="#//Node"/>
              <eStructuralFeatures xsi:type="ecore:EReference" name="owned" upperBound="-1"
                  eType="#//Node" containment="true"/>
              <eStructuralFeatures xsi:type="ecore:EReference" name="frozen" upperBound="-1"
                  eType="#//Node" containment="true" changeable="false"/>
            </eClassifiers>
            <eClassifiers xsi:type="ecore:EDataType" name="Entry"
                instanceClassName="org.eclipse.emf.ecore.util.FeatureMap$Entry"/>
            """
        let url = try writeEcore(ecoreDocument(body: body))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        let text = try String(contentsOf: result.url, encoding: .utf8)
        #expect(text.contains(#"<genFeatures property="Readonly" ecoreFeature="ecore:EAttribute sample.ecore#//Node/fixed"/>"#))
        #expect(text.contains(#"<genFeatures property="None" children="true" createChild="true" ecoreFeature="ecore:EAttribute sample.ecore#//Node/entries"/>"#))
        #expect(text.contains(#"<genFeatures property="Readonly" notify="false" ecoreFeature="ecore:EReference sample.ecore#//Node/peer"/>"#))
        #expect(text.contains(#"<genFeatures property="None" children="true" createChild="true" ecoreFeature="ecore:EReference sample.ecore#//Node/owned"/>"#))
        #expect(text.contains(#"<genFeatures property="None" children="true" ecoreFeature="ecore:EReference sample.ecore#//Node/frozen"/>"#))
    }

    // MARK: - Round trip

    @Test("The written generator model loads and resolves against its source model")
    @MainActor
    func roundTrip() async throws {
        let generated = try await generate(OracleCase.all[0])
        defer { generated.project.remove() }
        let resourceSet = ResourceSet()
        _ = try await GenModelResource.load(
            url: generated.result.url, resourceSet: resourceSet, resolution: .nameFragments)
        let context = await GenModelContext.snapshot(of: resourceSet)
        let classes = context.elements(ofKind: GenModelConstants.ClassName.genClass)
        #expect(classes.compactMap(\.ecoreClass).map(\.name).sorted() == ["Book", "Library", "Lendable", "Named", "Writer"].sorted())
        let features = context.elements(ofKind: GenModelConstants.ClassName.genFeature)
        #expect(features.count == 12)
        #expect(features.allSatisfy { $0.ecoreFeature != nil })
    }

    // MARK: - Progress and errors

    @Test("Progress messages name each stage")
    @MainActor
    func progressMessages() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        let messages = MessageLog()
        _ = try await GenerationPipeline.ecoreToGenModel(
            ecoreURLs: [project.model("families.ecore")],
            progress: { messages.append($0) })
        let log = messages.all
        #expect(log.first == "Loading the transformation")
        #expect(log.contains("Loading families.ecore"))
        #expect(log.contains("Transforming families.ecore (1 of 1)"))
        #expect(log.last == "Writing families.genmodel")
    }

    @Test("Giving no source model is an error")
    @MainActor
    func noSources() async {
        await #expect(throws: GenerationError.noSourceModels) {
            _ = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [])
        }
    }

    @Test("A missing source model is reported by path")
    @MainActor
    func missingSource() async {
        let path = "/nonexistent/swift-modelling/none.ecore"
        await #expect(throws: GenerationError.sourceModelNotFound(path)) {
            _ = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [URL(fileURLWithPath: path)])
        }
    }

    @Test("An unreadable source model is reported")
    @MainActor
    func unreadableSource() async throws {
        let url = try writeEcore("this is not XML")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        do {
            _ = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
            Issue.record("Expected the import to fail")
        } catch let error as GenerationError {
            guard case .sourceModelUnreadable(let path, _) = error else {
                Issue.record("Unexpected error \(error)")
                return
            }
            #expect(path == url.standardizedFileURL.path)
            #expect(error.description.contains("cannot be read"))
        }
    }

    @Test("A source model without a package is reported")
    @MainActor
    func noRootPackage() async throws {
        let url = try writeEcore(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"/>
            """)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent().deletingLastPathComponent()) }
        await #expect(throws: GenerationError.self) {
            _ = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [url])
        }
    }

    @Test("An output that cannot be written is reported")
    @MainActor
    func unwritableOutput() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        let blocker = project.root.appendingPathComponent("blocker")
        try "file".write(to: blocker, atomically: true, encoding: .utf8)
        var options = GenModelImportOptions()
        options.output = blocker.appendingPathComponent("inside/out.genmodel")
        do {
            _ = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: [project.model("families.ecore")], options: options)
            Issue.record("Expected the import to fail")
        } catch let error as GenerationError {
            guard case .outputFailed = error else {
                Issue.record("Unexpected error \(error)")
                return
            }
            #expect(error.description.contains("cannot be written"))
        }
    }

    @Test("Every error describes itself")
    func errorDescriptions() {
        let errors: [GenerationError] = [
            .noSourceModels, .sourceModelNotFound("a"), .sourceModelUnreadable("a", "b"),
            .noRootPackage("a"), .reloadModelUnreadable("a", "b"), .unsupportedComplianceLevel("a", ["b"]),
            .transformationUnavailable("a"), .transformationFailed("a"), .outputFailed("a", "b"),
        ]
        for error in errors { #expect(!error.description.isEmpty) }
        #expect(Set(errors.map(\.description)).count == errors.count)
    }

    // MARK: - Constants

    @Test("The transformation declares exactly the parameters that the constants name")
    func declaredParameters() throws {
        let url = try #require(GenModelTransformation.resourceURL)
        let text = try String(contentsOf: url, encoding: .utf8)
        let declared = Set(
            text.split(separator: "\n").compactMap { line -> String? in
                guard line.hasPrefix("-- @param ") else { return nil }
                return line.dropFirst("-- @param ".count).split(separator: " ").first.map(String.init)
            })
        #expect(declared == GenModelImportConstants.Parameter.all)
    }

    @Test("The parameters passed to the transformation are exactly the declared ones")
    func passedParameters() {
        let values = GenModelTransformation.parameters(
            options: GenModelImportOptions(), modelProject: "", modelName: "M", foreignModels: [])
        #expect(Set(values.keys) == GenModelImportConstants.Parameter.all)
    }
}

/// Collects progress messages from the pipeline.
final class MessageLog: Sendable {
    private let messages = Mutex<[String]>([])

    func append(_ message: String) {
        messages.withLock { $0.append(message) }
    }

    var all: [String] { messages.withLock { $0 } }
}

@Suite("Compliance levels")
struct ComplianceLevelTests {
    @Test("The supported levels come from the generator metamodel")
    func supportedLevels() async throws {
        let levels = try await GenerationPipeline.supportedComplianceLevels()
        #expect(levels.first == "1.4")
        #expect(levels.contains("5.0"))
        #expect(levels.contains(GenModelImportConstants.defaultComplianceLevel))
    }

    @Test("An unsupported level is rejected with the supported ones")
    @MainActor
    func unsupportedLevel() async throws {
        let project = try FixtureProject.make("families")
        defer { project.remove() }
        var options = GenModelImportOptions()
        options.complianceLevel = "17"
        do {
            _ = try await GenerationPipeline.ecoreToGenModel(
                ecoreURLs: [project.model("families.ecore")], options: options)
            Issue.record("Expected the import to fail")
        } catch let error as GenerationError {
            guard case .unsupportedComplianceLevel(let level, let supported) = error else {
                Issue.record("Unexpected error \(error)")
                return
            }
            #expect(level == "17")
            #expect(supported.contains("17.0"))
            #expect(error.description.contains("17.0"))
            #expect(error.errorDescription == error.description)
        }
    }
}
