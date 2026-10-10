//
//  CompanyFactory.swift
//

import ECore
import EMFBase
import Foundation

/// The factory of the company package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct CompanyFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = CompanyFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Company object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createCompany() -> Company { Company() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Company": return createCompany()
        default: return nil
        }
    }
}
