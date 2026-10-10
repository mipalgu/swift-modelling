//
//  FamiliesPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the Families package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct FamiliesPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = FamiliesPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: FamiliesFactory { FamiliesFactory.shared }

    /// The metaclass of the Family class.
    // @generated
    public let eFamily: EClass

    /// The metaclass of the Member class.
    // @generated
    public let eMember: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Family = EUUID()
        let featureID_Family_lastName = EUUID()
        let featureID_Family_father = EUUID()
        let featureID_Family_mother = EUUID()
        let featureID_Family_sons = EUUID()
        let featureID_Family_daughters = EUUID()
        let classID_Member = EUUID()
        let featureID_Member_firstName = EUUID()
        let featureID_Member_familyFather = EUUID()
        let featureID_Member_familyMother = EUUID()
        let featureID_Member_familySon = EUUID()
        let featureID_Member_familyDaughter = EUUID()
        let class_Family = EClass(
            id: classID_Family, name: "Family",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Family_lastName, name: "lastName",
                    eType: EDataType(name: "EString"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Family_father, name: "father",
                    eType: EClass(id: classID_Member, name: "Member"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Member_familyFather,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Family_mother, name: "mother",
                    eType: EClass(id: classID_Member, name: "Member"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Member_familyMother,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Family_sons, name: "sons",
                    eType: EClass(id: classID_Member, name: "Member"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Member_familySon,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Family_daughters, name: "daughters",
                    eType: EClass(id: classID_Member, name: "Member"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Member_familyDaughter,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Member = EClass(
            id: classID_Member, name: "Member",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Member_firstName, name: "firstName",
                    eType: EDataType(name: "EString"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Member_familyFather, name: "familyFather",
                    eType: EClass(id: classID_Family, name: "Family"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Family_father,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
                EReference(
                    id: featureID_Member_familyMother, name: "familyMother",
                    eType: EClass(id: classID_Family, name: "Family"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Family_mother,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
                EReference(
                    id: featureID_Member_familySon, name: "familySon",
                    eType: EClass(id: classID_Family, name: "Family"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Family_sons,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
                EReference(
                    id: featureID_Member_familyDaughter, name: "familyDaughter",
                    eType: EClass(id: classID_Family, name: "Family"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Family_daughters,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
            ])
        self.ePackage = EPackage(
            name: "Families", nsURI: "http://www.example.org/families", nsPrefix: "families",
            eClassifiers: [
                class_Family,
                class_Member,
            ])
        self.eFamily = class_Family
        self.eMember = class_Member
    }
}
