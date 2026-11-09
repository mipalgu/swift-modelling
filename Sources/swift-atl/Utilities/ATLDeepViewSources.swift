//
// ATLDeepViewSources.swift
// swift-atl
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import ModellingCommandLine
import OrderedCollections

/// The source models that `--deep-view` presents as the deep view of a level.
///
/// Every source model that holds a multi-level model, such as a MetaDepth document (`.mdepth`)
/// or an XMI or JSON document of its linguistic instances, is replaced by the read-only deep
/// view of the level given, and the package of that view becomes the metamodel of the source
/// model, whatever name the module header gives that metamodel. Other source models are read as
/// without the option. At least one source model must hold a multi-level model, and the views of
/// two source models must not present packages of the same name.
struct ATLDeepViewSources {
    /// The level whose deep views are presented.
    let level: Int

    /// The deep views of each multi-level source model, by its path as given on the command line.
    let viewsByPath: OrderedDictionary<String, DeepModelViews>

    /// The separator between a name and a path in a source argument, as in `IN=shop.mdepth`.
    static let pathSeparator: Character = "="

    /// The path of a source argument, which may name its model before the path.
    ///
    /// - Parameter argument: A source argument, such as `shop.mdepth`, `IN=shop.mdepth` or
    ///   `IN:Bookshop=shop.mdepth`.
    /// - Returns: The text after the first `=`, or the whole argument without one.
    static func path(ofSourceArgument argument: String) -> String {
        guard let separator = argument.firstIndex(of: pathSeparator) else { return argument }
        return String(argument[argument.index(after: separator)...])
    }

    /// Reads the multi-level source models and presents the deep view of a level of each.
    ///
    /// - Parameters:
    ///   - level: The level given with `--deep-view`.
    ///   - sourceArguments: The source arguments of the command line, possibly with names.
    ///   - explicitFormat: The input format given on the command line, if any.
    ///   - settings: The settings of the run, which create the resource sets of the models.
    ///   - encoding: The encoding of MetaDepth documents, or `nil` (the default) to read UTF-8
    ///     with a fallback to ISO-8859-1.
    ///   - verbose: Whether to print each view.
    /// - Returns: The deep views of the multi-level source models.
    /// - Throws: ``TransformationError/modelFileNotFound(_:)`` for a missing file,
    ///   ``TransformationError/invalidDeepView(_:)`` if a model has no such level,
    ///   ``TransformationError/noMultiLevelSource(_:_:)`` if no source model is a multi-level
    ///   model, ``TransformationError/ambiguousDeepView(_:_:)`` if two views present packages of
    ///   the same name, and the error of the reader if a file cannot be read.
    static func load(
        level: Int, sourceArguments: [String], explicitFormat: String?, settings: SemanticsSettings,
        encoding: TextEncoding? = nil, verbose: Bool = false
    ) async throws -> ATLDeepViewSources {
        let paths = Array(OrderedSet(sourceArguments.map(path(ofSourceArgument:))))
        var viewsByPath: OrderedDictionary<String, DeepModelViews> = [:]
        var pathsByPackageName: [String: String] = [:]
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else {
                throw TransformationError.modelFileNotFound(path)
            }
            let views: DeepModelViews?
            do {
                views = try await MultiLevelSupport.views(
                    ofFileAt: URL(fileURLWithPath: path), level: level, explicitFormat: explicitFormat,
                    encoding: encoding, in: settings.makeResourceSet())
            } catch let error as DeepViewError {
                throw TransformationError.invalidDeepView(error.description)
            }
            guard let views else { continue }
            let name = views.view.package.name
            if let earlier = pathsByPackageName[name] {
                throw TransformationError.ambiguousDeepView(name, [earlier, path])
            }
            pathsByPackageName[name] = path
            viewsByPath[path] = views
            if verbose {
                print("Deep view of level \(level) of \(path): package '\(name)' (\(views.view.namespaceURI))")
            }
        }
        guard !viewsByPath.isEmpty else { throw TransformationError.noMultiLevelSource(level, paths) }
        return ATLDeepViewSources(level: level, viewsByPath: viewsByPath)
    }

    /// The packages of the views, which metamodel names and `-- @nsURI` directives may bind to.
    var packages: [EPackage] { viewsByPath.values.map(\.view.package) }

    /// The helpers that the transformation or query calls on the objects of the views, such as
    /// `clabjectName()`.
    var helpers: [ATLNativeHelper] { ATLDeepViewHelpers.helpers(for: Array(viewsByPath.values)) }

    /// Adds the packages of the views to a registry of metamodels.
    ///
    /// The header of a module may give the metamodel of a multi-level source model a name of
    /// its own, as in `from IN : Products`. A stand-in package of that name is registered for
    /// it, so that parsing binds the metamodel without a directive; ``binding(_:mapping:)``
    /// then puts the package of the view in its place. The packages of the views are
    /// registered last, so that their namespace URIs name them.
    ///
    /// - Parameters:
    ///   - registry: The registry with which the transformation is parsed.
    ///   - header: The module as a first reading of its source declares it, if any.
    ///   - sourceArguments: The source arguments of the command line, for the header.
    func register(
        in registry: inout ATLMetamodelRegistry, header: ATLModule? = nil, sourceArguments: [String] = []
    ) {
        if let header,
            let mapping = try? mapFilesToAliases(
                filePaths: sourceArguments, aliases: Array(header.sourceMetamodels.keys), modelType: "source",
                verbose: false)
        {
            for (alias, path) in mapping {
                guard let package = viewsByPath[path]?.view.package,
                    let name = Self.metamodelName(of: alias, in: header), name != package.name
                else { continue }
                registry.register(EPackage(name: name, nsURI: package.nsURI))
            }
        }
        for package in packages {
            registry.register(package)
        }
    }

    /// The name that a module gives the metamodel of a source model.
    ///
    /// - Parameters:
    ///   - alias: The name of the source model.
    ///   - module: The module.
    /// - Returns: The declared metamodel name, or `nil` if the module has no such source model.
    static func metamodelName(of alias: String, in module: ATLModule) -> String? {
        guard let package = module.sourceMetamodels[alias] else { return nil }
        return module.declaredMetamodelNames[alias] ?? package.name
    }

    /// Binds the source models that are deep views to the packages of their views.
    ///
    /// A target model whose metamodel has the same name in the module header, as in refining
    /// mode, is bound to the same package.
    ///
    /// - Parameters:
    ///   - module: The module or query unit.
    ///   - mapping: The path of each source model, by model name.
    /// - Returns: The module with the package of its view as the metamodel of each such model.
    func binding(_ module: ATLModule, mapping: OrderedDictionary<String, String>) -> ATLModule {
        var sources = module.sourceMetamodels
        var packagesByName: [String: EPackage] = [:]
        for (alias, path) in mapping {
            guard let name = Self.metamodelName(of: alias, in: module), let views = viewsByPath[path] else {
                continue
            }
            sources[alias] = views.view.package
            packagesByName[name] = views.view.package
        }
        var targets = module.targetMetamodels
        for (alias, package) in targets {
            if let view = packagesByName[module.declaredMetamodelNames[alias] ?? package.name] {
                targets[alias] = view
            }
        }
        return module.withMetamodels(source: sources, target: targets)
    }

    /// Loads the source models, presenting the deep view for each multi-level model.
    ///
    /// The other source models are loaded as ``loadModelsFromMapping(_:metamodels:containerLookupScope:explicitFormat:verbose:debug:)``
    /// loads them.
    ///
    /// - Parameters:
    ///   - mapping: The path of each source model, by model name, in order.
    ///   - metamodels: The metamodels to register for the other source models.
    ///   - containerLookupScope: The container lookup scope of the other source models.
    ///   - explicitFormat: The input format given on the command line, if any.
    ///   - verbose: Whether to print verbose output.
    ///   - debug: Whether to enable debug mode for parsers.
    /// - Returns: The resource of each source model, by model name, in the order of `mapping`.
    /// - Throws: The errors of loading the other source models.
    func loadSources(
        _ mapping: OrderedDictionary<String, String>, metamodels: OrderedDictionary<String, EPackage>,
        containerLookupScope: ContainerLookupScope?, explicitFormat: String?, verbose: Bool, debug: Bool
    ) async throws -> OrderedDictionary<String, Resource> {
        let others = mapping.filter { viewsByPath[$0.value] == nil }
        let loaded = try await loadModelsFromMapping(
            others, metamodels: metamodels, containerLookupScope: containerLookupScope,
            explicitFormat: explicitFormat, verbose: verbose, debug: debug)
        var models: OrderedDictionary<String, Resource> = [:]
        for (alias, path) in mapping {
            if let views = viewsByPath[path] {
                if verbose {
                    print("Using the deep view of level \(level) of \(path) for model '\(alias)'")
                }
                models[alias] = views.view.resource
            } else if let resource = loaded[alias] {
                models[alias] = resource
            }
        }
        return models
    }
}
