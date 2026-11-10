//
// FormatRegistryDetectionTests.swift
// ModellingCommandLineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import Testing

/// Tests for the formats that the format registry chooses from the extension and contents of a
/// file, for the lists of formats in messages, and for Complete OCL documents applied to the
/// registered metamodels.
@Suite("Format registry detection")
struct FormatRegistryDetectionTests {
    /// An EMOF metamodel of a small shop.
    static let emofShop = """
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:emof="http://schema.omg.org/spec/MOF/2.0/emof.xml">
          <emof:Package xmi:id="shop" name="shop" uri="http://example.org/shop">
            <xmi:Extension extender="http://www.eclipse.org/emf/2002/Ecore">
              <nsPrefix>shop</nsPrefix>
            </xmi:Extension>
            <ownedType xmi:type="emof:Class" xmi:id="shop.Product" name="Product">
              <ownedAttribute xmi:id="shop.Product.price" name="price" isOrdered="true" lower="0">
                <type xmi:type="emof:PrimitiveType" href="http://schema.omg.org/spec/MOF/2.0/emof.xml#Integer"/>
              </ownedAttribute>
            </ownedType>
          </emof:Package>
        </xmi:XMI>

        """

    /// A model of the shop.
    static let product = """
        <?xml version="1.0" encoding="UTF-8"?>
        <shop:Product xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:shop="http://example.org/shop" price="3"/>

        """

    /// An Ecore metamodel of the shop.
    static let ecoreShop = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="shop"
            nsURI="http://example.org/shop" nsPrefix="shop">
          <eClassifiers xsi:type="ecore:EClass" name="Product">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="price"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
          </eClassifiers>
        </ecore:EPackage>

        """

    /// A Complete OCL document that constrains the shop.
    static let constraints = """
        package shop
        context Product
        inv PositivePrice: price > 0
        endpackage

        """

    /// A KM3 metamodel.
    static let km3 = """
        package Library {
            class Book {
                attribute title : String;
            }
        }

        package PrimitiveTypes {
            datatype String;
        }

        """

    /// Writes a file in a new temporary directory.
    ///
    /// - Parameters:
    ///   - contents: The contents of the file.
    ///   - name: The name of the file.
    /// - Returns: The path of the file.
    /// - Throws: Any error writing the file.
    static func write(_ contents: String, named name: String) throws -> String {
        let url = try ScratchDirectory().url.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    // MARK: - Detection

    @Test("counts an EMOF metamodel in an .xmi file as a metamodel, and an XMI model not")
    func emofInXMI() async throws {
        let metamodel = try Self.write(Self.emofShop, named: "shop.xmi")
        let model = try Self.write(Self.product, named: "product.xmi")
        #expect(await MetamodelRegistration.documentHandler(at: metamodel)?.format == .emof)
        #expect(await MetamodelRegistration.holdsMetamodel(at: metamodel))
        #expect(await MetamodelRegistration.mayHoldMetamodel(at: metamodel))
        #expect(await MetamodelRegistration.documentHandler(at: model)?.format == .xmi)
        #expect(!(await MetamodelRegistration.holdsMetamodel(at: model)))
        #expect(!(await MetamodelRegistration.mayHoldMetamodel(at: model)))
    }

    @Test("judges files by their extension as before when the contents name no other format")
    func extensions() async throws {
        let ecore = try Self.write(Self.ecoreShop, named: "shop.ECORE")
        let json = try Self.write(#"{ "eClass": "http://example.org/shop#//Product" }"#, named: "shop.json")
        #expect(await MetamodelRegistration.holdsMetamodel(at: ecore))
        #expect(!(await MetamodelRegistration.holdsMetamodel(at: json)))
        #expect(await MetamodelRegistration.mayHoldMetamodel(at: json))
        #expect(await MetamodelRegistration.holdsMetamodel(at: "missing/Library.km3"))
        #expect(!(await MetamodelRegistration.holdsMetamodel(at: "missing/library.xmi")))
    }

    @Test("reads a file with an unknown extension as a model unless a distinctive format recognises it")
    func unknownExtensions() async throws {
        let ecore = try Self.write(Self.ecoreShop, named: "shop.model")
        let km3 = try Self.write(Self.km3, named: "library.txt")
        #expect(!(await MetamodelRegistration.holdsMetamodel(at: ecore)))
        #expect(!(await MetamodelRegistration.mayHoldMetamodel(at: ecore)))
        #expect(await MetamodelRegistration.documentHandler(at: ecore)?.format == .ecore)
        #expect(await MetamodelRegistration.holdsMetamodel(at: km3))
    }

    // MARK: - Format lists

    @Test("names formats by extension, with the prose name where it differs")
    func formatList() {
        #expect(MetamodelRegistration.formatList([.ecore, .json, .emfatic]) == "ecore, json, emf (Emfatic)")
        #expect(MetamodelRegistration.formatList([.oclinecore, .xmi]) == "oclinecore, xmi")
        #expect(MetamodelOptions.formatList.hasPrefix("ecore, json, km3, emof, uml, emf (Emfatic)"))
        #expect(MetamodelOptions.effect.contains(MetamodelOptions.formatList))
    }

    @Test("lists only the formats that can be written")
    func writableFormats() {
        let metamodels = MetamodelRegistration.writableFormats(preferring: [.ecore, .json]) { $0 != .model }
        let models = MetamodelRegistration.writableFormats(preferring: [.xmi, .json]) { $0 != .metamodel }
        #expect(metamodels.prefix(4) == [.ecore, .json, .km3, .emof])
        #expect(!metamodels.contains(.langium))
        #expect(!metamodels.contains(.xtext))
        #expect(!metamodels.contains(.sdf3))
        #expect(models.prefix(3) == [.xmi, .json, .uml])
        #expect(!models.contains(.ecore))
        #expect(!MetamodelRegistration.isWritable(.langium))
        #expect(MetamodelRegistration.isWritable(.asdl))
    }

    // MARK: - Model instances

    @Test("reads and writes UML models as UML")
    func uml() throws {
        let url = URL(fileURLWithPath: "/models/design.uml")
        #expect(ModelFileFormat.instanceFormat(of: url) == .uml)
        #expect(ModelFileFormat.instanceFormat(of: URL(fileURLWithPath: "/models/design.xmi"), explicit: "uml") == .uml)
        #expect(try ModelFileFormat.detectedInstanceFormat(of: url) == .uml)
        #expect(ModelFileFormat.instanceFormat(of: URL(fileURLWithPath: "/models/design.xmi")) == .xmi)
    }

    // MARK: - Complete OCL

    @Test("constrains the registered metamodels with Complete OCL documents")
    @MainActor
    func completeOCL() async throws {
        let metamodel = try Self.write(Self.emofShop, named: "shop.xmi")
        let document = try Self.write(Self.constraints, named: "shop.ocl")
        let resourceSet = try await MetamodelRegistration.resourceSet(registering: [metamodel], applying: [document])
        let product = await resourceSet.getMetamodel(uri: "http://example.org/shop")?.getClassifier("Product") as? EClass
        let details = product?.eAnnotations.flatMap { $0.details.map(\.key) } ?? []
        #expect(details.contains("PositivePrice"), "\(details)")
        let unconstrained = try await MetamodelRegistration.resourceSet(registering: [metamodel])
        let plain = await unconstrained.getMetamodel(uri: "http://example.org/shop")?.getClassifier("Product") as? EClass
        #expect(plain?.eAnnotations.isEmpty == true)
    }

    @Test("reports a missing Complete OCL document and a document with nothing to constrain")
    @MainActor
    func completeOCLErrors() async throws {
        let metamodel = try Self.write(Self.emofShop, named: "shop.xmi")
        let document = try Self.write(Self.constraints, named: "shop.ocl")
        await #expect(throws: MetamodelRegistrationError.fileNotFound("missing.ocl")) {
            _ = try await MetamodelRegistration.resourceSet(registering: [metamodel], applying: ["missing.ocl"])
        }
        await #expect(throws: MetamodelRegistrationError.nothingToConstrain(document)) {
            try await MetamodelRegistration.applyCompleteOCL([document], to: [], in: ResourceSet())
        }
        #expect(
            MetamodelRegistrationError.nothingToConstrain("a.ocl").description
                == "No metamodel to constrain with a.ocl: give the metamodel with --metamodel")
        #expect(MetamodelRegistration.appliedMessage(count: 2, document: "a.ocl").contains("Applied 2"))
    }

    @Test("parses the Complete OCL option")
    func option() throws {
        let options = try CompleteOCLOptions.parse(["--ocl", "a.ocl", "--ocl", "b.ocl"])
        #expect(options.documents == ["a.ocl", "b.ocl"])
        #expect(options.isGiven)
        #expect(!(try CompleteOCLOptions.parse([])).isGiven)
        #expect(CompleteOCLOptions.optionName == "ocl")
    }
}
