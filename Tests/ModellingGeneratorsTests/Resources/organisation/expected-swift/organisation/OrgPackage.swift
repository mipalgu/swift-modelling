//
//  OrgPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the organisation package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct OrgPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = OrgPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: OrgFactory { OrgFactory.shared }

    /// The metaclass of the Person class.
    // @generated
    public let ePerson: EClass

    /// The metaclass of the Team class.
    // @generated
    public let eTeam: EClass

    /// The metaclass of the Organisation class.
    // @generated
    public let eOrganisation: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Person = EUUID()
        let featureID_Person_name = EUUID()
        let featureID_Person_age = EUUID()
        let classID_Team = EUUID()
        let featureID_Team_name = EUUID()
        let featureID_Team_members = EUUID()
        let featureID_Team_leader = EUUID()
        let classID_Organisation = EUUID()
        let featureID_Organisation_name = EUUID()
        let featureID_Organisation_teams = EUUID()
        let class_Person = EClass(
            id: classID_Person, name: "Person",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Person_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Person_age, name: "age",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Team = EClass(
            id: classID_Team, name: "Team",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Team_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Team_members, name: "members",
                    eType: EClass(id: classID_Person, name: "Person"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Team_leader, name: "leader",
                    eType: EClass(id: classID_Person, name: "Person"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Organisation = EClass(
            id: classID_Organisation, name: "Organisation",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Organisation_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Organisation_teams, name: "teams",
                    eType: EClass(id: classID_Team, name: "Team"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "organisation", nsURI: "http://swift-modelling.org/test/organisation", nsPrefix: "org",
            eClassifiers: [
                class_Person,
                class_Team,
                class_Organisation,
            ])
        self.ePerson = class_Person
        self.eTeam = class_Team
        self.eOrganisation = class_Organisation
    }
}
