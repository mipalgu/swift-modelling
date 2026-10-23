//
// PipelineFixture.swift
// ModellingPipelineTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// A scratch directory with neutral metamodels, a model, a transformation and templates.
///
/// The `People` metamodel has a `Group` that contains `Person` objects with names; the
/// `Contacts` metamodel has a `Book` that contains `Contact` objects with full names. The
/// transformation turns a group into a book and each person into a contact.
struct PipelineFixture {
    /// The scratch directory, removed by ``remove()``.
    let directory: URL

    /// The `People` metamodel.
    var peopleEcore: URL { directory.appendingPathComponent("People.ecore") }

    /// The `Contacts` metamodel.
    var contactsEcore: URL { directory.appendingPathComponent("Contacts.ecore") }

    /// A group of two people.
    var peopleModel: URL { directory.appendingPathComponent("people.xmi") }

    /// The transformation from people to contacts.
    var transformation: URL { directory.appendingPathComponent("People2Contacts.atl") }

    /// A template that lists the contacts of a book in one file and writes a line outside it.
    var listing: URL { directory.appendingPathComponent("templates/Listing.mtl") }

    /// Creates the fixture in a new scratch directory.
    static func make() throws -> PipelineFixture {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("modelling-pipeline-tests")
            .appendingPathComponent(UUID().uuidString)
        let fixture = PipelineFixture(directory: directory)
        try fixture.write(Self.people, to: fixture.peopleEcore)
        try fixture.write(Self.contacts, to: fixture.contactsEcore)
        try fixture.write(Self.group, to: fixture.peopleModel)
        try fixture.write(Self.people2Contacts, to: fixture.transformation)
        try fixture.write(Self.listingModule, to: fixture.listing)
        return fixture
    }

    /// Removes the scratch directory.
    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Writes text to a file, creating its directory.
    func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// The text of a file.
    func text(of url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    static let people = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="People"
            nsURI="http://example.org/people" nsPrefix="people">
          <eClassifiers xsi:type="ecore:EClass" name="Group">
            <eStructuralFeatures xsi:type="ecore:EReference" name="members" upperBound="-1"
                eType="#//Person" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Person">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    static let contacts = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore" name="Contacts"
            nsURI="http://example.org/contacts" nsPrefix="contacts">
          <eClassifiers xsi:type="ecore:EClass" name="Book">
            <eStructuralFeatures xsi:type="ecore:EReference" name="entries" upperBound="-1"
                eType="#//Contact" containment="true"/>
          </eClassifiers>
          <eClassifiers xsi:type="ecore:EClass" name="Contact">
            <eStructuralFeatures xsi:type="ecore:EAttribute" name="fullName"
                eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
          </eClassifiers>
        </ecore:EPackage>
        """

    static let group = """
        <?xml version="1.0" encoding="UTF-8"?>
        <people:Group xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
            xmlns:people="http://example.org/people">
          <members name="Ada"/>
          <members name="Alan"/>
        </people:Group>
        """

    static let people2Contacts = """
        -- @param greeting : String = 'Dear'
        module People2Contacts;
        create OUT : Contacts from IN : People;

        rule Group2Book {
            from g : People!Group
            to b : Contacts!Book ( entries <- g.members )
        }

        rule Person2Contact {
            from p : People!Person
            to c : Contacts!Contact ( fullName <- thisModule.greeting + ' ' + shout(p.name) )
        }
        """

    static let listingModule = """
        [module Listing('http://example.org/contacts')]

        [template public main(b : Book)]
        [file ('contacts.txt', 'overwrite', 'UTF-8')]
        [for (c : Contact | b.entries)]
        [prefix/][c.fullName/]
        [/for]
        [/file]
        listed
        [/template]
        """
}
