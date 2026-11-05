//
// TransformMetamodelOptions.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ArgumentParser
import ECore
import Foundation
import ModellingCommandLine
import OrderedCollections

/// The command line options that give the metamodel files of a transformation.
///
/// Each option names an Ecore file, either by position or as `NAME=file.ecore`, where `NAME`
/// is a metamodel name of the module header, such as `Families` in
/// `create OUT : Persons from IN : Families`. A metamodel file given on the command line takes
/// the place of the `-- @path` and `-- @nsURI` directives for its metamodel.
///
/// Files given by position follow the order of the module header: `--source-metamodel` the
/// metamodels after `from` or `refining`, `--target-metamodel` those after `create`, and
/// `--metamodel` all metamodels, source metamodels first, each name once. A metamodel that
/// both source and target models use, as in refining mode, therefore needs one `--metamodel`.
struct TransformMetamodelOptions: ParsableArguments {
    /// The long name of the option for source metamodels.
    static let sourceOptionName = "source-metamodel"

    /// The long name of the option for target metamodels.
    static let targetOptionName = "target-metamodel"

    /// The name of the value of the options in the usage of the command.
    static let valueName = "[name=]file.ecore"

    /// The metamodel files of the source models, in command line order.
    @Option(
        name: .customLong(TransformMetamodelOptions.sourceOptionName),
        help: ArgumentHelp(
            "An Ecore file for a source metamodel, by position or by metamodel name (can be specified multiple times)",
            valueName: TransformMetamodelOptions.valueName))
    var sourceMetamodels: [String] = []

    /// The metamodel files of the target models, in command line order.
    @Option(
        name: .customLong(TransformMetamodelOptions.targetOptionName),
        help: ArgumentHelp(
            "An Ecore file for a target metamodel, by position or by metamodel name (can be specified multiple times)",
            valueName: TransformMetamodelOptions.valueName))
    var targetMetamodels: [String] = []

    /// The metamodel files of any metamodel of the module, in command line order.
    @Option(
        name: .customLong(MetamodelOptions.optionName),
        help: ArgumentHelp(
            "An Ecore file for any metamodel of the module, such as one that source and target share (can be specified multiple times)",
            valueName: TransformMetamodelOptions.valueName))
    var metamodels: [String] = []

    /// Creates the options with no metamodel files.
    init() {}

    /// Whether at least one metamodel file was given on the command line.
    var isGiven: Bool { !(sourceMetamodels.isEmpty && targetMetamodels.isEmpty && metamodels.isEmpty) }

    /// The roles in which a metamodel file can be given.
    enum Role: CaseIterable {
        /// A metamodel of the source models.
        case source

        /// A metamodel of the target models.
        case target

        /// Any metamodel of the module.
        case any

        /// The command line option that gives files in this role.
        var optionName: String {
            switch self {
            case .source: return TransformMetamodelOptions.sourceOptionName
            case .target: return TransformMetamodelOptions.targetOptionName
            case .any: return MetamodelOptions.optionName
            }
        }

        /// How the metamodels of this role are described in messages.
        var noun: String {
            switch self {
            case .source: return "source metamodel"
            case .target: return "target metamodel"
            case .any: return "metamodel"
            }
        }

        /// The metamodel names of a module that files in this role can bind.
        ///
        /// - Parameter module: The module whose header declares the metamodels.
        /// - Returns: The names in the order of the header, each once.
        func names(in module: ATLModule) -> [String] {
            let source = Self.names(of: module.sourceMetamodels, in: module)
            let target = Self.names(of: module.targetMetamodels, in: module)
            switch self {
            case .source: return source
            case .target: return target
            case .any: return Array(OrderedSet(source + target))
            }
        }

        /// The header names of metamodels, in order and each once.
        ///
        /// - Parameters:
        ///   - metamodels: The metamodels by model alias.
        ///   - module: The module that declares them.
        /// - Returns: The metamodel names.
        static func names(of metamodels: OrderedDictionary<String, EPackage>, in module: ATLModule) -> [String] {
            Array(OrderedSet(metamodels.map { metamodelName(alias: $0.key, package: $0.value, in: module) }))
        }
    }

    /// The files that a role gives on the command line.
    ///
    /// - Parameter role: The role.
    /// - Returns: The arguments of the option of the role.
    func arguments(for role: Role) -> [String] {
        switch role {
        case .source: return sourceMetamodels
        case .target: return targetMetamodels
        case .any: return metamodels
        }
    }

    /// The header name of a metamodel.
    ///
    /// - Parameters:
    ///   - alias: The alias of the model that conforms to the metamodel.
    ///   - package: The package bound to the metamodel.
    ///   - module: The module that declares the metamodel.
    /// - Returns: The name that the module header gives the metamodel.
    static func metamodelName(alias: String, package: EPackage, in module: ATLModule) -> String {
        module.declaredMetamodelNames[alias] ?? package.name
    }

    /// The metamodel files by metamodel name, from all options.
    ///
    /// - Parameter module: The module whose header declares the metamodels.
    /// - Returns: The file of each metamodel that the command line binds.
    /// - Throws: ``TransformationError/invalidMetamodelArgument(_:)`` if a name is not declared
    ///   in its role, if files given by position do not match the declared metamodels in number,
    ///   or if two options bind one metamodel to different files.
    func files(for module: ATLModule) throws -> OrderedDictionary<String, String> {
        var bindings: OrderedDictionary<String, String> = [:]
        for role in Role.allCases {
            for (name, path) in try files(for: role, in: module) {
                if let earlier = bindings[name], earlier != path {
                    throw TransformationError.invalidMetamodelArgument(
                        "Metamodel '\(name)' is given twice, as \(earlier) and as \(path)")
                }
                bindings[name] = path
            }
        }
        return bindings
    }

    /// The metamodel files that one option gives, by metamodel name.
    ///
    /// - Parameters:
    ///   - role: The role of the option.
    ///   - module: The module whose header declares the metamodels.
    /// - Returns: The file of each metamodel that the option binds.
    /// - Throws: ``TransformationError/invalidMetamodelArgument(_:)`` if a name is not declared
    ///   in the role, or if files given by position do not match the metamodels in number.
    func files(for role: Role, in module: ATLModule) throws -> OrderedDictionary<String, String> {
        let arguments = arguments(for: role)
        guard !arguments.isEmpty else { return [:] }
        let names = role.names(in: module)
        let declared = names.joined(separator: ", ")
        guard arguments.contains(where: { $0.contains(KeyValueOptionSyntax.separator) }) else {
            guard arguments.count == names.count else {
                throw TransformationError.invalidMetamodelArgument(
                    "--\(role.optionName) gives \(arguments.count) file(s), but the module declares \(names.count) \(role.noun)(s) (\(declared)); give each as name=file.ecore to bind only some"
                )
            }
            return OrderedDictionary(uniqueKeysWithValues: zip(names, arguments))
        }
        let option = KeyValueOption<String>(noun: role.noun, allowedKeys: names)
        var bindings: OrderedDictionary<String, String> = [:]
        for argument in arguments {
            do {
                let (name, path) = try option.pair(argument)
                bindings[name] = path
            } catch {
                throw TransformationError.invalidMetamodelArgument("--\(role.optionName): \(error)")
            }
        }
        return bindings
    }

    /// Binds the metamodels of a module to the files given on the command line.
    ///
    /// Each file is loaded once, and every model alias whose metamodel it binds receives its root
    /// package. When `requiresAll` is `true`, every other metamodel must already be bound by a
    /// directive to a package that defines classifiers.
    ///
    /// - Parameters:
    ///   - module: The parsed module.
    ///   - requiresAll: Whether a metamodel that remains without a package is an error.
    ///   - verbose: Whether to print each binding.
    /// - Returns: The module with its metamodels bound.
    /// - Throws: The errors of ``files(for:)``, ``MetamodelRegistrationError/fileNotFound(_:)``
    ///   if a file does not exist, the error of the parser if a file cannot be loaded, and
    ///   ``TransformationError/unboundMetamodel(_:)`` for a metamodel without a package.
    func bind(_ module: ATLModule, requiresAll: Bool, verbose: Bool) async throws -> ATLModule {
        let files = try files(for: module)
        var packages: [String: EPackage] = [:]
        for path in OrderedSet(files.values) {
            guard FileManager.default.fileExists(atPath: path) else {
                throw MetamodelRegistrationError.fileNotFound(path)
            }
            packages[path] = try await EPackage(url: URL(fileURLWithPath: path))
        }
        if verbose {
            for (name, path) in files {
                print("Metamodel '\(name)' from \(path)")
            }
        }

        func bound(_ metamodels: OrderedDictionary<String, EPackage>) throws -> OrderedDictionary<String, EPackage> {
            var result = metamodels
            for (alias, package) in metamodels {
                let name = Self.metamodelName(alias: alias, package: package, in: module)
                if let path = files[name], let loaded = packages[path] {
                    result[alias] = loaded
                } else if requiresAll, package.eClassifiers.isEmpty {
                    throw TransformationError.unboundMetamodel(name)
                }
            }
            return result
        }
        return module.withMetamodels(
            source: try bound(module.sourceMetamodels), target: try bound(module.targetMetamodels))
    }
}
