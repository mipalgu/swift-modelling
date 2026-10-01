import Foundation
import Testing

@testable import ModellingGenerators

/// A fixture project together with the options that produce its committed expectation.
struct OracleCase: Sendable, CustomTestStringConvertible {
    /// The name of the fixture directory.
    let name: String

    /// The file stem of the source model in the fixture's `model` folder.
    let stem: String

    /// The import options that the expectation was reviewed for.
    let options: GenModelImportOptions

    var testDescription: String { name }

    /// The file name of the source model.
    var ecoreFileName: String { "\(stem).ecore" }

    /// The file name of the generator model that is written beside the source model.
    var genModelFileName: String { "\(stem).genmodel" }

    /// Every fixture with an expectation.
    static let all: [OracleCase] = [
        OracleCase(
            name: "library", stem: "library",
            options: GenModelImportOptions(
                basePackage: "org.example", copyright: "Copyright 2026 Example Pty Ltd")),
        OracleCase(name: "families", stem: "families", options: GenModelImportOptions()),
        OracleCase(
            name: "organisation", stem: "organisation",
            options: GenModelImportOptions(
                prefix: "Org", modelPluginID: "org.example.organisation", complianceLevel: "8.0")),
        OracleCase(
            name: "nested", stem: "company",
            options: GenModelImportOptions(
                basePackage: "org.example.company",
                packagePrefixes: ["projects": "Proj"])),
        OracleCase(name: "ecoretypes", stem: "bridge", options: GenModelImportOptions()),
    ]
}
