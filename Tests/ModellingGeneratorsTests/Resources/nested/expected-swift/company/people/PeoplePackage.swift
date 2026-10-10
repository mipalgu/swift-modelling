//
//  PeoplePackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the people package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct PeoplePackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = PeoplePackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: PeopleFactory { PeopleFactory.shared }

    /// The metaclass of the Person class.
    // @generated
    public let ePerson: EClass

    /// The metaclass of the Employee class.
    // @generated
    public let eEmployee: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Person = EUUID()
        let featureID_Person_name = EUUID()
        let classID_Employee = EUUID()
        let featureID_Employee_salary = EUUID()
        let class_Person = EClass(
            id: classID_Person, name: "Person",
            isAbstract: true, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Person_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Employee = EClass(
            id: classID_Employee, name: "Employee",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Person],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Employee_salary, name: "salary",
                    eType: EDataType(name: "EDouble"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        self.ePackage = EPackage(
            name: "people", nsURI: "http://swift-modelling.org/test/company/people", nsPrefix: "people",
            eClassifiers: [
                class_Person,
                class_Employee,
            ])
        self.ePerson = class_Person
        self.eEmployee = class_Employee
    }
}
