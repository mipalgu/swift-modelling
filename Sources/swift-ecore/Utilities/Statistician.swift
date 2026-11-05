//
// Statistician.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import ModellingGenerators

/// Measures the size and shape of a metamodel or a model.
enum Statistician {
    /// Measures a document.
    ///
    /// - Parameter document: The metamodel or model.
    /// - Returns: The report.
    static func measure(_ document: ModelDocument) async -> StatisticsReport {
        var report = StatisticsReport(
            file: document.fileName, kind: document.isMetamodel ? .metamodel : .model, format: document.formatName)
        if document.isMetamodel {
            report.metamodel = measure(metamodel: document.packages)
        } else {
            report.model = await measure(model: document)
        }
        return report
    }

    // MARK: - Metamodels

    /// Measures a metamodel.
    ///
    /// - Parameter roots: The root packages of the metamodel.
    /// - Returns: The measurements.
    static func measure(metamodel roots: [EPackage]) -> MetamodelStatistics {
        let catalogue = MetamodelCatalogue(roots: roots)
        let counts = MetamodelComparer.counts(of: roots)
        let classifiers = catalogue.packages.flatMap(\.eClassifiers)
        let classes = catalogue.classes
        let references = classes.flatMap { $0.eStructuralFeatures.compactMap { $0 as? EReference } }
        let paired = references.filter { catalogue.opposite(of: $0) != nil }.count
        let features = classes.map { eClass in
            let canonical = catalogue.canonical(eClass)
            let inherited = canonical.eAllSuperTypes.map { catalogue.canonical($0).eStructuralFeatures.count }.reduce(0, +)
            return ClassFeatureCount(
                name: eClass.name, features: canonical.eStructuralFeatures.count + inherited,
                declared: canonical.eStructuralFeatures.count)
        }
        return MetamodelStatistics(
            packages: counts[.packages] ?? 0,
            classes: classes.count,
            abstractClasses: classes.filter { $0.isAbstract && !$0.isInterface }.count,
            interfaces: classes.filter(\.isInterface).count,
            enumerations: counts[.enumerations] ?? 0,
            literals: classifiers.compactMap { $0 as? EEnum }.map(\.literals.count).reduce(0, +),
            dataTypes: counts[.dataTypes] ?? 0,
            attributes: counts[.attributes] ?? 0,
            references: references.count,
            containmentReferences: references.filter(\.containment).count,
            bidirectionalPairs: paired / 2,
            operations: counts[.operations] ?? 0,
            invariants: classes.map { OCLInvariant.invariants(declaredBy: $0).count }.reduce(0, +),
            maximumInheritanceDepth: Extreme.largest(
                of: classes.map { ($0.name, inheritanceDepth(of: $0, in: catalogue, visiting: [])) }),
            maximumDirectSubclasses: Extreme.largest(of: classes.map { ($0.name, catalogue.directSubclasses(of: $0).count) }),
            declaredFeatures: FeatureDistribution(features.map { ($0.name, $0.declared) }),
            allFeatures: FeatureDistribution(features.map { ($0.name, $0.features) }),
            classesByFeatures: features.sorted { ($1.features, $0.name) < ($0.features, $1.name) })
    }

    /// The longest chain of supertypes above a class.
    ///
    /// - Parameters:
    ///   - eClass: The class.
    ///   - catalogue: The catalogue that holds the canonical supertypes.
    ///   - visiting: The classes of the chain so far, which ends a cyclic hierarchy.
    /// - Returns: Zero for a class without supertypes, else one more than the deepest supertype.
    private static func inheritanceDepth(of eClass: EClass, in catalogue: MetamodelCatalogue, visiting: Set<EUUID>) -> Int {
        let supertypes = catalogue.supertypes(of: eClass).filter { !visiting.contains($0.id) }
        let path = visiting.union([eClass.id])
        return supertypes.map { 1 + inheritanceDepth(of: $0, in: catalogue, visiting: path) }.max() ?? 0
    }

    // MARK: - Models

    /// Measures a model.
    ///
    /// On an interactive terminal, a progress bar shows how many objects have been measured.
    ///
    /// - Parameter document: The model document.
    /// - Returns: The measurements.
    static func measure(model document: ModelDocument) async -> ModelStatistics {
        let objects = await ModelCatalogue.build(for: document)
        let progress = GenerationProgressBar(verbose: false)
        var attributeValues = 0
        var crossReferences = 0
        var external = 0
        var unresolved = 0
        for (index, entry) in objects.entries.enumerated() {
            progress.show(GenerationProgressUpdate(message: StatisticsVocabulary.progressMessage, completed: index, total: objects.entries.count))
            for slot in ObjectFeatures.slots(of: entry.object, eClass: objects.eClass(of: entry.object)) {
                switch slot.role {
                case .attribute:
                    attributeValues += 1
                case .crossReference:
                    for element in ValueElements.of(slot.value) {
                        crossReferences += 1
                        if let id = ObjectFeatures.identifier(of: element), objects.entry(for: id) != nil { continue }
                        switch await location(of: element, in: objects.resourceSet) {
                        case .otherDocument:
                            external += 1
                        case .unresolvedDocument:
                            external += 1
                            unresolved += 1
                        case .nowhere:
                            unresolved += 1
                        }
                    }
                case .containment, .container:
                    continue
                }
            }
        }
        progress.finish()
        let counts = objects.classCounts
        var withoutInstances: [String]?
        if document.hasMetamodel {
            let instantiated = Set(counts.map(\.name))
            withoutInstances = MetamodelCatalogue(roots: document.metamodels).classes
                .filter { !$0.isAbstract && !$0.isInterface && !instantiated.contains($0.name) }
                .map(\.name).sorted()
        }
        return ModelStatistics(
            objects: objects.entries.count,
            rootObjects: objects.roots.count,
            classesInstantiated: counts.count,
            classes: counts.map { ClassCount(name: $0.name, count: $0.count) },
            maximumContainmentDepth: objects.entries.map(\.depth).max() ?? 0,
            attributeValues: attributeValues,
            containmentLinks: objects.entries.filter { $0.container != nil }.count,
            crossReferences: crossReferences,
            externalReferences: external,
            unresolvedReferences: unresolved,
            classesWithoutInstances: withoutInstances,
            metamodels: document.metamodels.map(\.nsURI))
    }

    /// Where a reference to an object outside the model leads.
    private enum TargetLocation {
        /// To an object of another document.
        case otherDocument

        /// Into another document that holds no such object, or that cannot be read.
        case unresolvedDocument

        /// To no object of any document.
        case nowhere
    }

    /// Finds where a reference to an object outside the model leads.
    ///
    /// - Parameters:
    ///   - element: The element of the reference value.
    ///   - resourceSet: The resource set that resolves references into other documents.
    /// - Returns: Whether the reference leads into another document, and whether the object is found.
    private static func location(of element: any EcoreValue, in resourceSet: ResourceSet) async -> TargetLocation {
        if let proxy = element as? ResourceProxy {
            return await proxy.resolveObject(in: resourceSet) == nil ? .unresolvedDocument : .otherDocument
        }
        guard let id = ObjectFeatures.identifier(of: element), await resourceSet.resolve(id)?.object is DynamicEObject else {
            return .nowhere
        }
        return .otherDocument
    }
}
