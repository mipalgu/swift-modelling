//
//  TestSupport.swift
//  ModelTypingTests
//
//  Copyright (c) 2026 Rene Hexel. All rights reserved.
//

import ECore
import EMFBase
import Foundation
import ModelTyping
import Testing

/// Loads the metamodel fixtures of the test bundle.
enum Fixtures {
    /// The subdirectory of the test bundle that holds the fixtures.
    static let directory = "Fixtures"

    /// Loads a fixture package.
    ///
    /// - Parameter name: The fixture name without the `.ecore` extension.
    /// - Returns: The package.
    static func package(_ name: String) async throws -> EPackage {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "ecore", subdirectory: directory))
        return try await EPackage(url: url)
    }

    /// Loads the model type of a fixture package.
    ///
    /// - Parameter name: The fixture name without the `.ecore` extension.
    /// - Returns: The model type.
    static func modelType(_ name: String) async throws -> ModelType {
        ModelType(packages: [try await package(name)])
    }
}

/// Builds small metamodels in code for focused rule tests.
enum Build {
    /// An attribute.
    static func attribute(
        _ name: String, _ type: String = "EString", lower: Int = 0, upper: Int = 1, changeable: Bool = true,
        derived: Bool = false, ordered: Bool = true, unique: Bool = true
    ) -> EAttribute {
        EAttribute(name: name, eType: EDataType(name: type), lowerBound: lower, upperBound: upper,
                   changeable: changeable, ordered: ordered, unique: unique, derived: derived)
    }

    /// A reference.
    static func reference(
        _ name: String, _ type: String, lower: Int = 0, upper: Int = 1, containment: Bool = false,
        ordered: Bool = true, unique: Bool = true, id: EUUID = EUUID(), opposite: EUUID? = nil
    ) -> EReference {
        EReference(id: id, name: name, eType: EClass(name: type), lowerBound: lower, upperBound: upper,
                   containment: containment, opposite: opposite, ordered: ordered, unique: unique)
    }

    /// A class.
    static func eClass(
        _ name: String, abstract: Bool = false, supers: [String] = [], _ features: [any EStructuralFeature] = []
    ) -> EClass {
        EClass(name: name, isAbstract: abstract, eSuperTypes: supers.map { EClass(name: $0) },
               eStructuralFeatures: features)
    }

    /// An enumeration.
    static func eEnum(_ name: String, _ literals: [String]) -> EEnum {
        EEnum(name: name, literals: literals.enumerated().map { EEnumLiteral(name: $0.element, value: $0.offset) })
    }

    /// The model type of a package made of the given classifiers.
    static func modelType(_ classifiers: [any EClassifier], name: String = "mm") -> ModelType {
        ModelType(packages: [EPackage(name: name, nsURI: "http://example.org/\(name)", nsPrefix: name,
                                      eClassifiers: classifiers)])
    }
}

extension CompatibilityReport {
    /// The codes of the findings with a severity.
    func codes(_ severity: TypingSeverity) -> Set<TypingDiagnosticCode> {
        Set(diagnostics.filter { $0.severity == severity }.map(\.code))
    }

    /// Whether a finding with a code and severity is about an element.
    func has(_ code: TypingDiagnosticCode, _ severity: TypingSeverity, at element: String) -> Bool {
        diagnostics.contains { $0.code == code && $0.severity == severity && $0.element.description == element }
    }
}

extension MetamodelFootprint {
    /// The used features written as `Class.feature`, sorted.
    var featureNames: [String] { featureReferences.map(\.description) }

    /// The access of a feature written as `Class.feature`.
    func access(_ feature: String) -> AccessMode? {
        features.first { $0.key.description == feature }?.value.access
    }
}
