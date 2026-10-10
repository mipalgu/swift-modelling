//
//  CompanyPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the company package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct CompanyPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = CompanyPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: CompanyFactory { CompanyFactory.shared }

    /// The metaclass of the Company class.
    // @generated
    public let eCompany: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Company = EUUID()
        let featureID_Company_name = EUUID()
        let featureID_Company_staff = EUUID()
        let featureID_Company_projects = EUUID()
        let class_Company = EClass(
            id: classID_Company, name: "Company",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Company_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Company_staff, name: "staff",
                    eType: EClass(name: "Employee"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Company_projects, name: "projects",
                    eType: EClass(name: "Project"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "company", nsURI: "http://swift-modelling.org/test/company", nsPrefix: "company",
            eClassifiers: [
                class_Company,
            ])
        self.eCompany = class_Company
    }
}
