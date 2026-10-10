//
//  DocumentedPackage.swift
//

import ECore
import EMFBase
import Foundation

/// The description of the documented package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct DocumentedPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = DocumentedPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: DocumentedFactory { DocumentedFactory.shared }

    /// The Ecore enumeration of the Level enumeration.
    // @generated
    public let eLevel: EEnum

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let enum_Level = EEnum(
            name: "Level",
            literals: [
                EEnumLiteral(name: "Low", value: 0, literal: "Low"),
                EEnumLiteral(name: "High", value: 1, literal: "High"),
                EEnumLiteral(name: "Old", value: 2, literal: "Old"),
            ])
        self.ePackage = EPackage(
            name: "documented", nsURI: "http://swift-modelling.org/test/documented", nsPrefix: "doc",
            eClassifiers: [
                enum_Level,
            ])
        self.eLevel = enum_Level
    }
}
