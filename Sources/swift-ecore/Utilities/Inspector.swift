//
// Inspector.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import ModellingCommandLine
import MultiLevel

/// What an inspection includes.
struct InspectionOptions: Sendable, Equatable {
    /// How much detail the inspection shows.
    var detail: InspectionDetail = .summary

    /// Whether the attributes of every class are listed, also in a summary.
    var showAttributes = false

    /// Whether the references of every class are listed, together with the reference graph.
    var showReferences = false

    /// Whether inherited features, subclasses and the inheritance hierarchy are listed.
    var showSupertypes = false

    /// Whether classes list their attributes.
    var includesAttributes: Bool { detail == .full || showAttributes }

    /// Whether classes list their references.
    var includesReferences: Bool { detail == .full || showReferences }

    /// Whether classes list their operations and invariants, and models their objects.
    var includesEverything: Bool { detail == .full }
}

/// Builds the inspection report of a metamodel or a model.
enum Inspector {
    /// Inspects a document.
    ///
    /// - Parameters:
    ///   - document: The metamodel or model.
    ///   - options: What the inspection includes.
    /// - Returns: The report.
    static func inspect(
        _ document: ModelDocument, options: InspectionOptions,
        levelCrossing: LevelCrossingMode = LevelCrossingOptions.defaultMode
    ) async -> InspectionReport {
        if let deepModel = document.deepModel {
            var report = InspectionReport(
                file: document.fileName, kind: .multiLevelModel, format: document.formatName, detail: options.detail.rawValue)
            report.multiLevel = multiLevelReport(deepModel, levelCrossing: levelCrossing)
            return report
        }
        var report = InspectionReport(
            file: document.fileName, kind: document.isMetamodel ? .metamodel : .model,
            format: document.formatName, detail: options.detail.rawValue)
        let catalogue = MetamodelCatalogue(roots: document.describingPackages)
        if document.isMetamodel {
            report.packages = document.packages.map { packageReport($0, catalogue: catalogue, options: options) }
            if options.showReferences { report.referenceGraph = referenceGraph(of: catalogue) }
        } else {
            let objects = await ModelCatalogue.build(for: document)
            report.model = await modelReport(document, objects: objects, catalogue: catalogue, options: options)
            if options.showReferences { report.referenceGraph = await referenceGraph(of: objects) }
        }
        if options.showSupertypes, !catalogue.classes.isEmpty {
            report.hierarchy = catalogue.hierarchyRoots.map { hierarchyNode($0, catalogue: catalogue) }
        }
        return report
    }

    // MARK: - Multi-level models

    /// The levels and clabjects of a multi-level model.
    ///
    /// - Parameters:
    ///   - model: The model.
    ///   - levelCrossing: The level crossing mode of the command.
    /// - Returns: The report.
    static func multiLevelReport(_ model: DeepModel, levelCrossing: LevelCrossingMode) -> MultiLevelReport {
        let levels = model.levels.enumerated().map { position, level in
            LevelReport(
                level: model.levelNumber(ofModelAt: position), name: level.name, typeModel: level.typeModel,
                clabjects: level.clabjects.map { clabject in
                    ClabjectReport(
                        name: clabject.name, type: clabject.type.flatMap { model.clabject($0)?.name },
                        potency: model.potency(of: clabject.id)?.description, isEdge: clabject.isEdge,
                        isAbstract: clabject.isAbstract, features: clabject.features.map(\.name))
                })
        }
        return MultiLevelReport(
            potencyVariant: model.potencyVariant.rawValue, levelCrossing: levelCrossing.rawValue, levels: levels)
    }

    // MARK: - Metamodels

    /// The report of a package and its subpackages.
    private static func packageReport(
        _ package: EPackage, catalogue: MetamodelCatalogue, options: InspectionOptions
    ) -> PackageReport {
        var classes: [ClassReport] = []
        var enumerations: [EnumerationReport] = []
        var dataTypes: [DataTypeReport] = []
        for classifier in package.eClassifiers {
            switch classifier {
            case let eClass as EClass:
                classes.append(classReport(eClass, catalogue: catalogue, options: options))
            case let eEnum as EEnum:
                enumerations.append(
                    EnumerationReport(name: eEnum.name, literals: eEnum.literals.map { LiteralReport(name: $0.name, value: $0.value) }))
            case let dataType as EDataType:
                dataTypes.append(DataTypeReport(name: dataType.name, instanceClassName: dataType.instanceClassName))
            default:
                break
            }
        }
        return PackageReport(
            name: package.name, nsURI: package.nsURI, nsPrefix: package.nsPrefix, classes: classes,
            enumerations: enumerations, dataTypes: dataTypes,
            subpackages: package.eSubpackages.map { packageReport($0, catalogue: catalogue, options: options) })
    }

    /// The report of a class.
    private static func classReport(_ eClass: EClass, catalogue: MetamodelCatalogue, options: InspectionOptions) -> ClassReport {
        var report = ClassReport(
            name: eClass.name, abstract: eClass.isAbstract, interface: eClass.isInterface,
            supertypes: catalogue.supertypes(of: eClass).map(\.name))
        let declared = eClass.eStructuralFeatures
        if options.includesAttributes {
            report.attributes = declared.compactMap { $0 as? EAttribute }.map { featureReport($0, catalogue: catalogue) }
        }
        if options.includesReferences {
            report.references = declared.compactMap { $0 as? EReference }.map { featureReport($0, catalogue: catalogue) }
        }
        if options.includesEverything {
            report.operations = eClass.eOperations.map { operation in
                OperationReport(
                    name: operation.name, returnType: MetamodelCatalogue.typeName(operation.eType),
                    parameters: operation.eParameters.map { parameter in
                        FeatureReport(
                            name: parameter.name, type: MetamodelCatalogue.typeName(parameter.eType),
                            multiplicity: MetamodelCatalogue.multiplicity(lower: parameter.lowerBound, upper: parameter.upperBound),
                            flags: [])
                    })
            }
            let invariants = OCLInvariant.invariants(declaredBy: eClass).map(\.name)
            report.constraints = invariants.isEmpty ? nil : invariants
        }
        if options.showSupertypes {
            let canonical = catalogue.canonical(eClass)
            report.allSupertypes = canonical.eAllSuperTypes.map { catalogue.canonical($0).name }
            report.subclasses = catalogue.directSubclasses(of: eClass).map(\.name)
            report.inheritedFeatures = canonical.eAllSuperTypes.flatMap { supertype in
                catalogue.canonical(supertype).eStructuralFeatures.map { feature in
                    var inherited = featureReport(feature, catalogue: catalogue)
                    inherited.declaredBy = supertype.name
                    return inherited
                }
            }
        }
        return report
    }

    /// The report of an attribute or reference.
    private static func featureReport(_ feature: any EStructuralFeature, catalogue: MetamodelCatalogue) -> FeatureReport {
        let shape = FeatureShape(feature)
        var report = FeatureReport(
            name: feature.name, type: shape.type.name, multiplicity: shape.multiplicity,
            flags: MetamodelCatalogue.flags(of: feature), defaultValue: shape.defaultValueLiteral)
        if let reference = feature as? EReference, let opposite = catalogue.opposite(of: reference) {
            report.opposite = "\(opposite.owner.name).\(opposite.reference.name)"
        }
        return report
    }

    /// A class and, recursively, the classes that extend it.
    private static func hierarchyNode(_ eClass: EClass, catalogue: MetamodelCatalogue) -> HierarchyNode {
        HierarchyNode(
            name: eClass.name, flags: MetamodelCatalogue.flags(of: eClass),
            subclasses: catalogue.directSubclasses(of: eClass).map { hierarchyNode($0, catalogue: catalogue) })
    }

    /// Every reference that the classes of a metamodel declare.
    private static func referenceGraph(of catalogue: MetamodelCatalogue) -> [ReferenceEdge] {
        catalogue.classes.flatMap { eClass in
            eClass.eStructuralFeatures.compactMap { $0 as? EReference }.map { reference in
                ReferenceEdge(
                    source: eClass.name, reference: reference.name, target: reference.eType.name,
                    multiplicity: MetamodelCatalogue.multiplicity(lower: reference.lowerBound, upper: reference.upperBound),
                    containment: reference.containment,
                    opposite: catalogue.opposite(of: reference).map { "\($0.owner.name).\($0.reference.name)" })
            }
        }
    }

    // MARK: - Models

    /// The report of a model.
    private static func modelReport(
        _ document: ModelDocument, objects: ModelCatalogue, catalogue: MetamodelCatalogue, options: InspectionOptions
    ) async -> ModelReport {
        var classes: [ClassCount] = []
        for (name, count) in objects.classCounts {
            var entry = ClassCount(name: name, count: count)
            if options.showSupertypes, let eClass = objects.instantiatedClasses.first(where: { $0.name == name }) {
                entry.supertypes = eClass.eAllSuperTypes.map { catalogue.canonical($0).name }
            }
            classes.append(entry)
        }
        var report = ModelReport(
            rootObjects: objects.roots.count, objects: objects.entries.count, classes: classes,
            metamodels: document.metamodels.map { $0.nsURI.isEmpty ? $0.name : $0.nsURI })
        if options.includesEverything {
            var tree: [ObjectReport] = []
            for entry in objects.entries where entry.container == nil {
                tree.append(await objectReport(entry, objects: objects))
            }
            report.tree = tree
        }
        return report
    }

    /// The report of an object and everything it contains.
    private static func objectReport(_ entry: ModelCatalogue.Entry, objects: ModelCatalogue) async -> ObjectReport {
        let object = entry.object
        let eClass = objects.eClass(of: object)
        var attributes: [NamedValue] = []
        var references: [NamedValue] = []
        var contents: [ContainedObjects] = []
        for attribute in MetamodelCatalogue.attributes(of: eClass) where object.eIsSet(attribute.name) {
            let values = ValueElements.of(object.eGet(attribute.name)).map { ValueText.describe($0, of: attribute) }
            attributes.append(NamedValue(name: attribute.name, values: values))
        }
        for reference in MetamodelCatalogue.references(of: eClass) where object.eIsSet(reference.name) {
            if reference.containment {
                var contained: [ObjectReport] = []
                for child in objects.children(of: object.id) where child.feature == reference.name {
                    contained.append(await objectReport(child, objects: objects))
                }
                contents.append(ContainedObjects(feature: reference.name, objects: contained))
            } else if !reference.container {
                references.append(
                    NamedValue(name: reference.name, values: await objects.describeTargets(of: object.eGet(reference.name))))
            }
        }
        let declared = Set(eClass.eAllStructuralFeatures.map(\.name))
        for name in object.getFeatureNames() where !declared.contains(name) {
            let values = ValueElements.of(object.eGet(name)).map { ValueText.describe($0) }
            attributes.append(NamedValue(name: name, values: values))
        }
        return ObjectReport(
            className: eClass.name, label: objects.label(of: object), location: entry.location,
            attributes: attributes, references: references, contents: contents)
    }

    /// Every non-containment reference between the objects of a model.
    private static func referenceGraph(of objects: ModelCatalogue) async -> [ReferenceEdge] {
        var edges: [ReferenceEdge] = []
        for entry in objects.entries {
            let eClass = objects.eClass(of: entry.object)
            for reference in MetamodelCatalogue.references(of: eClass) where !reference.containment && !reference.container {
                for target in await objects.describeTargets(of: entry.object.eGet(reference.name)) {
                    edges.append(
                        ReferenceEdge(
                            source: objects.labelWithLocation(of: entry.object), reference: reference.name,
                            target: target, containment: false))
                }
            }
        }
        return edges
    }
}
