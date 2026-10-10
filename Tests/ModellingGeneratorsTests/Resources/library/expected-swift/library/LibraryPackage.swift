//
//  LibraryPackage.swift
//
//  Copyright 2026 Example Pty Ltd
//

import ECore
import EMFBase
import Foundation

/// The description of the library package.
///
/// The shared instance builds the Ecore package of the model, with the metaclass of each class, enumeration and
/// data type, which the objects of the package return as their metaclass.
// @generated
public struct LibraryPackage: Sendable {
    /// The shared description of the package.
    // @generated
    public static let shared = LibraryPackage()

    /// The Ecore package that holds the classifiers.
    // @generated
    public let ePackage: EPackage

    /// The factory that creates the objects of the package.
    // @generated
    public var factory: LibraryFactory { LibraryFactory.shared }

    /// The metaclass of the Named class.
    // @generated
    public let eNamed: EClass

    /// The metaclass of the Lendable class.
    // @generated
    public let eLendable: EClass

    /// The metaclass of the Book class.
    // @generated
    public let eBook: EClass

    /// The metaclass of the Writer class.
    // @generated
    public let eWriter: EClass

    /// The metaclass of the Library class.
    // @generated
    public let eLibrary: EClass

    /// The Ecore enumeration of the BookCategory enumeration.
    // @generated
    public let eBookCategory: EEnum

    /// The Ecore data type of the ISBN data type.
    // @generated
    public let eISBN: EDataType

    /// Builds the Ecore package and its classifiers.
    // @generated
    private init() {
        let classID_Named = EUUID()
        let featureID_Named_name = EUUID()
        let classID_Lendable = EUUID()
        let featureID_Lendable_loanDays = EUUID()
        let featureID_Lendable_onLoan = EUUID()
        let classID_Book = EUUID()
        let featureID_Book_pages = EUUID()
        let featureID_Book_category = EUUID()
        let featureID_Book_isbn = EUUID()
        let featureID_Book_author = EUUID()
        let featureID_Book_library = EUUID()
        let classID_Writer = EUUID()
        let featureID_Writer_aliases = EUUID()
        let featureID_Writer_books = EUUID()
        let classID_Library = EUUID()
        let featureID_Library_books = EUUID()
        let featureID_Library_writers = EUUID()
        let enum_BookCategory = EEnum(
            name: "BookCategory",
            literals: [
                EEnumLiteral(name: "Mystery", value: 0, literal: "Mystery"),
                EEnumLiteral(name: "ScienceFiction", value: 1, literal: "ScienceFiction"),
                EEnumLiteral(name: "Biography", value: 2, literal: "Biography"),
            ])
        let dataType_ISBN = EDataType(name: "ISBN", instanceClassName: "java.lang.String")
        let class_Named = EClass(
            id: classID_Named, name: "Named",
            isAbstract: true, isInterface: false,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Named_name, name: "name",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Lendable = EClass(
            id: classID_Lendable, name: "Lendable",
            isAbstract: true, isInterface: true,
            eSuperTypes: [],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Lendable_loanDays, name: "loanDays",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "14", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Lendable_onLoan, name: "onLoan",
                    eType: EDataType(name: "EBoolean"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
            ])
        let class_Book = EClass(
            id: classID_Book, name: "Book",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Named, class_Lendable],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Book_pages, name: "pages",
                    eType: EDataType(name: "EInt"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: "100", unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Book_category, name: "category",
                    eType: enum_BookCategory,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EAttribute(
                    id: featureID_Book_isbn, name: "isbn",
                    eType: dataType_ISBN,
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Book_author, name: "author",
                    eType: EClass(id: classID_Writer, name: "Writer"),
                    lowerBound: 1, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Writer_books,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Book_library, name: "library",
                    eType: EClass(id: classID_Library, name: "Library"),
                    lowerBound: 0, upperBound: 1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Library_books,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: true),
            ])
        let class_Writer = EClass(
            id: classID_Writer, name: "Writer",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Named],
            eStructuralFeatures: [
                EAttribute(
                    id: featureID_Writer_aliases, name: "aliases",
                    eType: EDataType(name: "EString"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    defaultValueLiteral: nil, unsettable: false, derived: false),
                EReference(
                    id: featureID_Writer_books, name: "books",
                    eType: EClass(id: classID_Book, name: "Book"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: false, opposite: featureID_Book_author,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        let class_Library = EClass(
            id: classID_Library, name: "Library",
            isAbstract: false, isInterface: false,
            eSuperTypes: [class_Named],
            eStructuralFeatures: [
                EReference(
                    id: featureID_Library_books, name: "books",
                    eType: EClass(id: classID_Book, name: "Book"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: featureID_Book_library,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
                EReference(
                    id: featureID_Library_writers, name: "writers",
                    eType: EClass(id: classID_Writer, name: "Writer"),
                    lowerBound: 0, upperBound: -1,
                    changeable: true, volatile: false, transient: false,
                    containment: true, opposite: nil,
                    resolveProxies: true, unsettable: false, derived: false,
                    container: false),
            ])
        self.ePackage = EPackage(
            name: "library", nsURI: "http://swift-modelling.org/test/library/1.0", nsPrefix: "lib",
            eClassifiers: [
                class_Named,
                class_Lendable,
                class_Book,
                class_Writer,
                class_Library,
                enum_BookCategory,
                dataType_ISBN,
            ])
        self.eNamed = class_Named
        self.eLendable = class_Lendable
        self.eBook = class_Book
        self.eWriter = class_Writer
        self.eLibrary = class_Library
        self.eBookCategory = enum_BookCategory
        self.eISBN = dataType_ISBN
    }
}
