//
//  ArchivePackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the archive package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct ArchivePackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = ArchivePackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: ArchiveFactory { ArchiveFactory.shared }

    /// The metaclass of the Record class.
    // @generated
    public let eRecord: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Record = EUUID()
        let featureID_Record_project = EUUID()
        let class_Record = EClass(
            id: classID_Record, name: "Record",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EReference(
                    id: featureID_Record_project, name: "project",
                    eType: EClass(name: "Project"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "archive", nsURI: "http://swift-modelling.org/test/company/projects/archive", nsPrefix: "archive",
            eClassifiers: [
                class_Record,
            ])
        self.eRecord = class_Record
    }
}
