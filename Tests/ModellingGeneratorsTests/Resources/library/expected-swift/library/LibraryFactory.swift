//
//  LibraryFactory.swift
//
//  Copyright 2026 Example Pty Ltd
//

import ECore
import EMFBase
import Foundation

/// The factory of the library package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
public struct LibraryFactory: Sendable {
    /// The shared factory of the package.
    // @generated
    public static let shared = LibraryFactory()

    /// Creates a factory.
    // @generated
    public init() {}

    /// Creates a new Book object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createBook() -> Book { Book() }

    /// Creates a new Writer object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createWriter() -> Writer { Writer() }

    /// Creates a new Library object.
    ///
    /// - Returns: An object with all features at their defaults.
    // @generated
    public func createLibrary() -> Library { Library() }

    /// Creates an object for a metaclass of the package.
    ///
    /// - Parameter eClass: The metaclass to create an object for.
    /// - Returns: A new object, or `nil` if the package has no class with instances of that name.
    // @generated
    public func create(_ eClass: EClass) -> (any EObject)? {
        switch eClass.name {
        case "Book": return createBook()
        case "Writer": return createWriter()
        case "Library": return createLibrary()
        default: return nil
        }
    }
}
