//
//  PartsFactory.swift
//

import ECore
import EMFBase
import Foundation

/// The factory of the parts package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct PartsFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = PartsFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Wheel object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createWheel() -> Wheel { Wheel() }

    /// Creates a new Self object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createSelf() -> `Self` { `Self`() }

    /// Creates a new Protocol object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createProtocol() -> `Protocol` { `Protocol`() }

    /// Creates a new String object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createString() -> String_ { String_() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Wheel": return createWheel()
        case "Self": return createSelf()
        case "Protocol": return createProtocol()
        case "String": return createString()
        default: return nil
        }
    }
}
