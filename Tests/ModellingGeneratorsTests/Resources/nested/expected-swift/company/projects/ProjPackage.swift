//
//  ProjPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the projects package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct ProjPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = ProjPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: ProjFactory { ProjFactory.shared }

    /// The metaclass of the Project class.
    // @generated
    public let eProject: EClass

    /// The Ecore enumeration of the Status enumeration.
    // @generated
    public let eStatus: EEnum

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Project = EUUID()
        let featureID_Project_title = EUUID()
        let featureID_Project_status = EUUID()
        let featureID_Project_members = EUUID()
        let enum_Status = EEnum(
            name: "Status",
            literals: [
                EEnumLiteral(name: "Proposed", value: 0, literal: "Proposed"),
                EEnumLiteral(name: "Active", value: 1, literal: "Active"),
                EEnumLiteral(name: "Finished", value: 2, literal: "Finished"),
            ])
        let class_Project = EClass(
            id: classID_Project, name: "Project",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Project_title, name: "title",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Project_status, name: "status",
                    eType: enum_Status,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Project_members, name: "members",
                    eType: EClass(name: "Employee"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "projects", nsURI: "http://swift-modelling.org/test/company/projects", nsPrefix: "projects",
            eClassifiers: [
                class_Project,
                enum_Status,
            ])
        self.eProject = class_Project
        self.eStatus = enum_Status
    }
}
