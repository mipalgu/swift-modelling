//
// TransformationStep.swift
// ModellingPipeline
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import OrderedCollections

/// A model-to-model transformation written in ATL, run on models held in memory.
///
/// The step parses the transformation module against the given metamodels, creates an empty
/// target resource for each target model, and runs the module on the source models. The
/// target resources carry the target metamodels of the module, so that they are written with
/// the namespaces of those metamodels.
///
/// ## Example
///
/// ```swift
/// let step = TransformationStep(
///     moduleURL: URL(fileURLWithPath: "Families2Persons.atl"),
///     metamodels: [familiesPackage, personsPackage],
///     sourceAliases: ["IN": familiesResource],
///     parameters: ["prefix": "Mr"],
///     atlOptions: .standard)
/// let targets = try await step.run()
/// let persons = targets["OUT"]
/// ```
public struct TransformationStep: Sendable {
    /// The URI scheme of target resources that have no location of their own.
    public static let transientScheme = "transient"

    /// The location of the `.atl` module.
    public var moduleURL: URL

    /// The metamodels that the module binds to by namespace URI or by name.
    public var metamodels: ATLMetamodelRegistry

    /// The source models by the alias that the module declares for them, such as `IN`.
    public var sourceAliases: [String: Resource]

    /// The aliases of the target models to create; empty creates every target the module declares.
    public var targetAliases: [String]

    /// The values of the parameters that the module declares with `-- @param`, by name.
    public var parameters: [String: any EcoreValue]

    /// Helpers implemented in Swift that the module can call.
    public var nativeHelpers: [ATLNativeHelper]

    /// The directories searched for metamodels named by `-- @path` directives.
    ///
    /// Empty searches the directory of the module.
    public var metamodelSearchPaths: [URL]

    /// How the module reads features that a model does not set.
    public var unsetFeatureReads: UnsetFeatureReads

    /// The locations of target models by alias.
    ///
    /// A target without a location gets a URI with the ``transientScheme`` and its alias.
    public var targetURIs: [String: URL]

    /// The behaviours of the ATL language in which the module is written.
    ///
    /// A step created with an initialiser that takes `atlOptions` carries the value given there,
    /// such as `ATLOptions.standard` for the behaviour documented for this release, which
    /// accepts integer ranges such as `Sequence{1..3}`. A step created with an initialiser of
    /// version 0.6 carries `ATLOptions.legacy`, which rejects them as that version did.
    public var atlOptions: ATLOptions

    /// Creates a transformation step with a registry of metamodels and the ATL behaviour of
    /// version 0.6.
    ///
    /// The step carries `ATLOptions.legacy`.
    ///
    /// - Parameters:
    ///   - moduleURL: The location of the `.atl` module.
    ///   - metamodels: The metamodels that the module binds to (default: none).
    ///   - sourceAliases: The source models by alias (default: none).
    ///   - targetAliases: The aliases of the targets to create (default: all declared targets).
    ///   - parameters: The values of the module parameters (default: none).
    ///   - nativeHelpers: Helpers implemented in Swift (default: none).
    ///   - metamodelSearchPaths: The directories searched for `-- @path` metamodels (default: the
    ///     directory of the module).
    ///   - unsetFeatureReads: How unset features read (default ``UnsetFeatureReads/defaults``).
    ///   - targetURIs: The locations of target models by alias (default: transient URIs).
    @available(
        *, deprecated,
        message: "Use init(moduleURL:metamodels:sourceAliases:targetAliases:parameters:nativeHelpers:metamodelSearchPaths:unsetFeatureReads:targetURIs:atlOptions:); pass atlOptions: .legacy to keep the behaviour of version 0.6"
    )
    public init(
        moduleURL: URL, metamodels: ATLMetamodelRegistry = .empty,
        sourceAliases: [String: Resource] = [:], targetAliases: [String] = [],
        parameters: [String: any EcoreValue] = [:], nativeHelpers: [ATLNativeHelper] = [],
        metamodelSearchPaths: [URL] = [], unsetFeatureReads: UnsetFeatureReads = .defaults,
        targetURIs: [String: URL] = [:]
    ) {
        self.init(
            moduleURL: moduleURL, metamodels: metamodels, sourceAliases: sourceAliases,
            targetAliases: targetAliases, parameters: parameters, nativeHelpers: nativeHelpers,
            metamodelSearchPaths: metamodelSearchPaths, unsetFeatureReads: unsetFeatureReads,
            targetURIs: targetURIs, atlOptions: .legacy)
    }

    /// Creates a transformation step with a registry of metamodels and the given ATL behaviours.
    ///
    /// Pass `ATLOptions.standard` for the behaviour documented for this release, or
    /// `ATLOptions.legacy` for that of version 0.6.
    ///
    /// - Parameters:
    ///   - moduleURL: The location of the `.atl` module.
    ///   - metamodels: The metamodels that the module binds to (default: none).
    ///   - sourceAliases: The source models by alias (default: none).
    ///   - targetAliases: The aliases of the targets to create (default: all declared targets).
    ///   - parameters: The values of the module parameters (default: none).
    ///   - nativeHelpers: Helpers implemented in Swift (default: none).
    ///   - metamodelSearchPaths: The directories searched for `-- @path` metamodels (default: the
    ///     directory of the module).
    ///   - unsetFeatureReads: How unset features read (default ``UnsetFeatureReads/defaults``).
    ///   - targetURIs: The locations of target models by alias (default: transient URIs).
    ///   - atlOptions: The behaviours of the ATL language in which the module is written.
    public init(
        moduleURL: URL, metamodels: ATLMetamodelRegistry = .empty,
        sourceAliases: [String: Resource] = [:], targetAliases: [String] = [],
        parameters: [String: any EcoreValue] = [:], nativeHelpers: [ATLNativeHelper] = [],
        metamodelSearchPaths: [URL] = [], unsetFeatureReads: UnsetFeatureReads = .defaults,
        targetURIs: [String: URL] = [:], atlOptions: ATLOptions
    ) {
        self.moduleURL = moduleURL
        self.metamodels = metamodels
        self.sourceAliases = sourceAliases
        self.targetAliases = targetAliases
        self.parameters = parameters
        self.nativeHelpers = nativeHelpers
        self.metamodelSearchPaths = metamodelSearchPaths
        self.unsetFeatureReads = unsetFeatureReads
        self.targetURIs = targetURIs
        self.atlOptions = atlOptions
    }

    /// Creates a transformation step with metamodel packages and the ATL behaviour of version 0.6.
    ///
    /// Each package is registered under its namespace URI and its name. The step carries
    /// `ATLOptions.legacy`.
    ///
    /// - Parameters:
    ///   - moduleURL: The location of the `.atl` module.
    ///   - metamodels: The metamodel packages that the module binds to.
    ///   - sourceAliases: The source models by alias (default: none).
    ///   - targetAliases: The aliases of the targets to create (default: all declared targets).
    ///   - parameters: The values of the module parameters (default: none).
    ///   - nativeHelpers: Helpers implemented in Swift (default: none).
    ///   - metamodelSearchPaths: The directories searched for `-- @path` metamodels (default: the
    ///     directory of the module).
    ///   - unsetFeatureReads: How unset features read (default ``UnsetFeatureReads/defaults``).
    ///   - targetURIs: The locations of target models by alias (default: transient URIs).
    @available(
        *, deprecated,
        message: "Use init(moduleURL:metamodels:sourceAliases:targetAliases:parameters:nativeHelpers:metamodelSearchPaths:unsetFeatureReads:targetURIs:atlOptions:); pass atlOptions: .legacy to keep the behaviour of version 0.6"
    )
    public init(
        moduleURL: URL, metamodels: [EPackage], sourceAliases: [String: Resource] = [:],
        targetAliases: [String] = [], parameters: [String: any EcoreValue] = [:],
        nativeHelpers: [ATLNativeHelper] = [], metamodelSearchPaths: [URL] = [],
        unsetFeatureReads: UnsetFeatureReads = .defaults, targetURIs: [String: URL] = [:]
    ) {
        self.init(
            moduleURL: moduleURL, metamodels: ATLMetamodelRegistry(packages: metamodels),
            sourceAliases: sourceAliases, targetAliases: targetAliases, parameters: parameters,
            nativeHelpers: nativeHelpers, metamodelSearchPaths: metamodelSearchPaths,
            unsetFeatureReads: unsetFeatureReads, targetURIs: targetURIs, atlOptions: .legacy)
    }

    /// Creates a transformation step with metamodel packages and the given ATL behaviours.
    ///
    /// Each package is registered under its namespace URI and its name. Pass
    /// `ATLOptions.standard` for the behaviour documented for this release, or
    /// `ATLOptions.legacy` for that of version 0.6.
    ///
    /// - Parameters:
    ///   - moduleURL: The location of the `.atl` module.
    ///   - metamodels: The metamodel packages that the module binds to.
    ///   - sourceAliases: The source models by alias (default: none).
    ///   - targetAliases: The aliases of the targets to create (default: all declared targets).
    ///   - parameters: The values of the module parameters (default: none).
    ///   - nativeHelpers: Helpers implemented in Swift (default: none).
    ///   - metamodelSearchPaths: The directories searched for `-- @path` metamodels (default: the
    ///     directory of the module).
    ///   - unsetFeatureReads: How unset features read (default ``UnsetFeatureReads/defaults``).
    ///   - targetURIs: The locations of target models by alias (default: transient URIs).
    ///   - atlOptions: The behaviours of the ATL language in which the module is written.
    public init(
        moduleURL: URL, metamodels: [EPackage], sourceAliases: [String: Resource] = [:],
        targetAliases: [String] = [], parameters: [String: any EcoreValue] = [:],
        nativeHelpers: [ATLNativeHelper] = [], metamodelSearchPaths: [URL] = [],
        unsetFeatureReads: UnsetFeatureReads = .defaults, targetURIs: [String: URL] = [:],
        atlOptions: ATLOptions
    ) {
        self.init(
            moduleURL: moduleURL, metamodels: ATLMetamodelRegistry(packages: metamodels),
            sourceAliases: sourceAliases, targetAliases: targetAliases, parameters: parameters,
            nativeHelpers: nativeHelpers, metamodelSearchPaths: metamodelSearchPaths,
            unsetFeatureReads: unsetFeatureReads, targetURIs: targetURIs, atlOptions: atlOptions)
    }

    /// Parses the transformation module.
    ///
    /// - Returns: The parsed module.
    /// - Throws: ``ModelPipelineError/transformationUnreadable(_:_:)`` if the module cannot be read
    ///   or parsed, or a metamodel it names cannot be loaded.
    @MainActor
    public func parseModule() async throws -> ATLModule {
        let searchPaths = metamodelSearchPaths.isEmpty ? [moduleURL.deletingLastPathComponent()] : metamodelSearchPaths
        do {
            let source = try String(contentsOf: moduleURL, encoding: .utf8)
            return try await ATLParser(options: atlOptions).parseContent(
                source, filename: moduleURL.path, searchPaths: searchPaths.map(\.path),
                continueAfterErrors: false, metamodelRegistry: metamodels)
        } catch {
            throw ModelPipelineError.transformationUnreadable(moduleURL.path, String(describing: error))
        }
    }

    /// Runs the transformation.
    ///
    /// The source models are those of ``sourceAliases``, together with the models of `sources`
    /// whose aliases the module declares and ``sourceAliases`` does not give.
    ///
    /// - Parameters:
    ///   - sources: Further source models by alias; aliases that the module does not declare are
    ///     ignored (default: none).
    ///   - targetResourceSet: The resource set that receives the target resources, with the
    ///     target metamodels of the module registered (default: a new resource set).
    /// - Returns: The target resources by alias.
    /// - Throws: ``ModelPipelineError/transformationUnreadable(_:_:)`` if the module cannot be
    ///   parsed, and ``ModelPipelineError/transformationFailed(_:_:)`` if a source model is missing,
    ///   a parameter is wrong, or a rule fails.
    @MainActor
    public func run(sources: [String: Resource] = [:], targetResourceSet: ResourceSet = ResourceSet())
        async throws -> [String: Resource]
    {
        let module = try await parseModule()
        var sourceModels = OrderedDictionary<String, Resource>()
        for alias in module.sourceMetamodels.keys {
            if let resource = sourceAliases[alias] ?? sources[alias] { sourceModels[alias] = resource }
        }
        for (alias, resource) in sourceAliases.sorted(by: { $0.key < $1.key }) where sourceModels[alias] == nil {
            sourceModels[alias] = resource
        }
        for package in module.targetMetamodels.values {
            await targetResourceSet.registerMetamodel(package, uri: package.nsURI)
        }
        let aliases = targetAliases.isEmpty ? Array(module.targetMetamodels.keys) : targetAliases
        var targetModels = OrderedDictionary<String, Resource>()
        for alias in aliases {
            let uri = targetURIs[alias]?.absoluteString ?? "\(Self.transientScheme):\(alias)"
            targetModels[alias] = await targetResourceSet.createResource(uri: uri)
        }
        let machine = ATLVirtualMachine(
            module: module, unsetFeatureReads: unsetFeatureReads, nativeHelpers: nativeHelpers)
        do {
            try await machine.execute(sources: sourceModels, targets: targetModels, parameters: parameters)
        } catch {
            throw ModelPipelineError.transformationFailed(module.name, String(describing: error))
        }
        return Dictionary(uniqueKeysWithValues: targetModels.map { ($0.key, $0.value) })
    }
}
