//
//  BarePackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the bare package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct BarePackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = BarePackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: BareFactory { BareFactory.shared }

    /// The metaclass of the Thing class.
    // @generated
    public let eThing: EClass

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Thing = EUUID()
        let class_Thing = EClass(
            id: classID_Thing, name: "Thing",
            isAbstract: false, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
            ])
        self.ePackage = EPackage(
            name: "bare", nsURI: "http://swift-modelling.org/test/bare", nsPrefix: "bare",
            eClassifiers: [
                class_Thing,
            ])
        self.eThing = class_Thing
    }
}
