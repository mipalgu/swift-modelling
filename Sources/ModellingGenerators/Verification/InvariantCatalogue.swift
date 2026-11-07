//
// InvariantCatalogue.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// An invariant that a metamodel states for a class.
struct Invariant: Equatable, Sendable {
    /// The name of the class that the invariant constrains.
    let className: String
    /// The name of the constraint.
    let name: String
    /// The OCL text of the constraint, or `nil` if the metamodel names the constraint without
    /// giving its body, as for constraints implemented in code.
    let body: String?
}

/// Reads the invariants of classes from their Ecore annotations.
///
/// A class names its constraints in the `constraints` detail of the Ecore annotation, and a
/// validation delegate annotation, such as that of the Eclipse OCL pivot delegate, gives the body
/// of each constraint under its name. The delegates that the package declares are searched first,
/// then the OCL delegates in ``VerificationVocabulary/oclDelegateSources``.
enum InvariantCatalogue {
    /// The invariants of a class, in the order in which the class names them.
    ///
    /// - Parameters:
    ///   - eClass: The class.
    ///   - package: The package of the class, whose validation delegates are searched first.
    /// - Returns: The invariants that the class declares itself.
    static func invariants(of eClass: EClass, in package: EPackage?) -> [Invariant] {
        let names = details(of: eClass, source: VerificationVocabulary.ecoreAnnotationSource)?[
            VerificationVocabulary.constraintsKey]
        let constraintNames = (names ?? "").split(whereSeparator: \.isWhitespace).map(String.init)
        let declared = package.flatMap {
            details(of: $0, source: VerificationVocabulary.ecoreAnnotationSource)?[
                VerificationVocabulary.validationDelegatesKey]
        }
        let sources =
            (declared ?? "").split(whereSeparator: \.isWhitespace).map(String.init)
            + VerificationVocabulary.oclDelegateSources
        return constraintNames.map { name in
            let body = sources.lazy.compactMap { details(of: eClass, source: $0)?[name] }.first
            return Invariant(className: eClass.name, name: name, body: body)
        }
    }

    private static func details(of element: some EModelElement, source: String) -> [String: String]? {
        guard let annotation = element.eAnnotations.first(where: { $0.source == source }) else { return nil }
        return Dictionary(annotation.details.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })
    }
}
