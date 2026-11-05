//
// MetamodelComparer.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The names that a comparison leaves out.
///
/// A name leaves out every feature, metamodel element or property of that name. A qualified
/// name such as `Order.note` leaves out one feature of one class, or the metamodel element at
/// that path.
struct ComparisonFilter: Sendable, Equatable {
    /// The names and qualified names to leave out.
    let names: Set<String>

    /// Creates a filter from the names given on the command line.
    ///
    /// - Parameter names: The names and qualified names to leave out.
    init(_ names: [String]) {
        self.names = Set(names)
    }

    /// Whether a metamodel element is left out, together with everything it contains.
    ///
    /// - Parameters:
    ///   - name: The name of the element.
    ///   - path: The qualified name of the element, such as `Order.note`.
    /// - Returns: `true` if the name, the path or a trailing part of the path is left out.
    func ignoresElement(named name: String, path: String) -> Bool {
        names.contains(name) || names.contains(path)
            || names.contains { path.hasSuffix(ComparisonVocabulary.pathSeparator + $0) }
    }

    /// Whether changes of a property of metamodel elements are left out.
    ///
    /// - Parameter property: The property.
    /// - Returns: `true` if the name of the property is left out.
    func ignoresProperty(_ property: ComparisonVocabulary.Property) -> Bool {
        names.contains(property.rawValue)
    }

    /// Whether a feature of the objects of a class is left out.
    ///
    /// - Parameters:
    ///   - feature: The name of the feature.
    ///   - classNames: The name of the class of the object and the names of its supertypes.
    /// - Returns: `true` if the feature is left out everywhere or for one of the classes.
    func ignoresFeature(_ feature: String, ofClassesNamed classNames: [String]) -> Bool {
        names.contains(feature)
            || classNames.contains { names.contains($0 + ComparisonVocabulary.pathSeparator + feature) }
    }
}

/// Finds the differences between two metamodels.
///
/// Packages and subpackages are matched by name; when both metamodels have a single root
/// package, the two root packages are matched whatever their names. Classifiers are matched by
/// name within their package, features and operations by name within their class, and
/// literals by name within their enumeration. Elements of the same name are matched in
/// document order.
struct MetamodelComparer {
    /// The elements and properties to leave out.
    let filter: ComparisonFilter

    /// The classes of the original metamodel.
    let originalCatalogue: MetamodelCatalogue

    /// The classes of the revised metamodel.
    let revisedCatalogue: MetamodelCatalogue

    /// The differences found so far, in document order.
    private(set) var differences: [Difference] = []

    /// Compares two metamodels.
    ///
    /// - Parameters:
    ///   - original: The root packages of the original metamodel.
    ///   - revised: The root packages of the revised metamodel.
    ///   - filter: The elements and properties to leave out.
    /// - Returns: The differences in document order.
    static func compare(original: [EPackage], revised: [EPackage], filter: ComparisonFilter) -> [Difference] {
        var comparer = MetamodelComparer(
            filter: filter, originalCatalogue: MetamodelCatalogue(roots: original),
            revisedCatalogue: MetamodelCatalogue(roots: revised))
        if original.count == 1, revised.count == 1 {
            comparer.comparePackage(original[0], revised[0], path: original[0].name, scope: "", isSingleRoot: true)
        } else {
            comparer.compareMatching(
                original, revised, name: \.name, scope: "",
                describe: { package, _ in package.nsURI }, element: { _ in .package }
            ) { comparer, original, revised, path in
                comparer.comparePackage(original, revised, path: path, scope: path, isSingleRoot: false)
            }
        }
        return comparer.differences
    }

    /// The counts of packages, classifiers and features of a metamodel.
    ///
    /// - Parameter roots: The root packages of the metamodel.
    /// - Returns: The count for every name of ``ComparisonVocabulary/ElementCount``.
    static func counts(of roots: [EPackage]) -> [ComparisonVocabulary.ElementCount: Int] {
        let packages = roots.flatMap(\.allPackages)
        let classifiers = packages.flatMap(\.eClassifiers)
        let classes = classifiers.compactMap { $0 as? EClass }
        let features = classes.flatMap(\.eStructuralFeatures)
        return [
            .packages: packages.count,
            .classes: classes.count,
            .enumerations: classifiers.filter { $0 is EEnum }.count,
            .dataTypes: classifiers.filter { $0 is EDataType }.count,
            .attributes: features.filter { $0 is EAttribute }.count,
            .references: features.filter { $0 is EReference }.count,
            .operations: classes.map(\.eOperations.count).reduce(0, +),
        ]
    }

    // MARK: - Matching

    /// Matches two lists of elements by name and reports the removed, matched and added ones.
    ///
    /// Removed and matched elements are reported in the order of the original list, followed
    /// by the added elements in the order of the revised list.
    ///
    /// - Parameters:
    ///   - original: The elements of the original metamodel.
    ///   - revised: The elements of the revised metamodel.
    ///   - name: The name of an element.
    ///   - scope: The qualified name of the container, or empty for none.
    ///   - describe: The description of an added or removed element, if any, given the
    ///     catalogue of the metamodel that holds it.
    ///   - element: The kind of an element.
    ///   - compareMatched: Compares two matched elements, given their qualified name.
    private mutating func compareMatching<Element>(
        _ original: [Element], _ revised: [Element], name: (Element) -> String, scope: String,
        describe: (Element, MetamodelCatalogue) -> String?, element: (Element) -> Difference.Element,
        compareMatched: (inout MetamodelComparer, Element, Element, String) -> Void
    ) {
        var unmatched = Array(revised.indices)
        for item in original {
            let path = Self.qualify(scope, name(item))
            let index = unmatched.firstIndex { name(revised[$0]) == name(item) }
            if filter.ignoresElement(named: name(item), path: path) {
                if let index { unmatched.remove(at: index) }
                continue
            }
            guard let index else {
                differences.append(
                    Difference(change: .removed, element: element(item), path: path, original: describe(item, originalCatalogue)))
                continue
            }
            let counterpart = revised[unmatched.remove(at: index)]
            compareMatched(&self, item, counterpart, path)
        }
        for index in unmatched {
            let item = revised[index]
            let path = Self.qualify(scope, name(item))
            guard !filter.ignoresElement(named: name(item), path: path) else { continue }
            differences.append(
                Difference(change: .added, element: element(item), path: path, revised: describe(item, revisedCatalogue)))
        }
    }

    /// Reports a property that differs between two matched elements.
    ///
    /// - Parameters:
    ///   - property: The property.
    ///   - element: The kind of element.
    ///   - path: The qualified name of the element.
    ///   - original: The original value.
    ///   - revised: The revised value.
    private mutating func property(
        _ property: ComparisonVocabulary.Property, of element: Difference.Element, path: String,
        _ original: String, _ revised: String
    ) {
        guard original != revised, !filter.ignoresProperty(property) else { return }
        differences.append(
            Difference(change: .changed, element: element, path: path, property: property.rawValue, original: original, revised: revised))
    }

    /// Joins a scope and a name into a qualified name.
    ///
    /// - Parameters:
    ///   - scope: The qualified name of the container, or empty for none.
    ///   - name: The name.
    /// - Returns: For example `billing.Invoice`, or the name alone without a scope.
    static func qualify(_ scope: String, _ name: String) -> String {
        scope.isEmpty ? name : scope + ComparisonVocabulary.pathSeparator + name
    }

    // MARK: - Packages

    /// Compares two matched packages, their classifiers and their subpackages.
    private mutating func comparePackage(
        _ original: EPackage, _ revised: EPackage, path: String, scope: String, isSingleRoot: Bool
    ) {
        if isSingleRoot { property(.name, of: .package, path: path, original.name, revised.name) }
        property(.nsURI, of: .package, path: path, original.nsURI, revised.nsURI)
        property(.nsPrefix, of: .package, path: path, original.nsPrefix, revised.nsPrefix)
        compareMatching(
            original.eClassifiers, revised.eClassifiers, name: \.name, scope: scope,
            describe: { classifier, _ in Self.description(of: classifier) }, element: Self.element(of:)
        ) { comparer, original, revised, path in
            comparer.compareClassifier(original, revised, path: path)
        }
        compareMatching(
            original.eSubpackages, revised.eSubpackages, name: \.name, scope: scope,
            describe: { package, _ in package.nsURI }, element: { _ in .package }
        ) { comparer, original, revised, path in
            comparer.comparePackage(original, revised, path: path, scope: path, isSingleRoot: false)
        }
    }

    // MARK: - Classifiers

    /// The kind of a classifier.
    private static func element(of classifier: any EClassifier) -> Difference.Element {
        switch classifier {
        case is EClass: return .class
        case is EEnum: return .enumeration
        default: return .dataType
        }
    }

    /// The description of an added or removed classifier.
    private static func description(of classifier: any EClassifier) -> String? {
        switch classifier {
        case let eClass as EClass:
            var parts = MetamodelCatalogue.flags(of: eClass)
            if !eClass.eSuperTypes.isEmpty {
                parts.append(ComparisonVocabulary.extendsWord + " " + list(eClass.eSuperTypes.map(\.name)))
            }
            return parts.isEmpty ? nil : parts.joined(separator: ComparisonVocabulary.listSeparator)
        case let eEnum as EEnum:
            return eEnum.literals.isEmpty ? nil : list(eEnum.literals.map(\.name))
        case let dataType as EDataType:
            return dataType.instanceClassName
        default:
            return nil
        }
    }

    /// Compares two matched classifiers.
    private mutating func compareClassifier(_ original: any EClassifier, _ revised: any EClassifier, path: String) {
        let originalKind = Self.element(of: original)
        let revisedKind = Self.element(of: revised)
        guard originalKind == revisedKind else {
            property(.kind, of: .classifier, path: path, originalKind.text, revisedKind.text)
            return
        }
        switch (original, revised) {
        case let (original as EClass, revised as EClass):
            compareClass(original, revised, path: path)
        case let (original as EEnum, revised as EEnum):
            compareMatching(
                original.literals, revised.literals, name: \.name, scope: path,
                describe: { literal, _ in "\(literal.value)" }, element: { _ in .literal }
            ) { comparer, original, revised, path in
                comparer.property(.value, of: .literal, path: path, "\(original.value)", "\(revised.value)")
            }
        case let (original as EDataType, revised as EDataType):
            property(
                .instanceClass, of: .dataType, path: path, original.instanceClassName ?? ComparisonVocabulary.none,
                revised.instanceClassName ?? ComparisonVocabulary.none)
        default:
            break
        }
    }

    /// Compares two matched classes, their features and their operations.
    private mutating func compareClass(_ original: EClass, _ revised: EClass, path: String) {
        property(.abstract, of: .class, path: path, "\(original.isAbstract)", "\(revised.isAbstract)")
        property(.interface, of: .class, path: path, "\(original.isInterface)", "\(revised.isInterface)")
        property(
            .supertypes, of: .class, path: path, Self.list(originalCatalogue.supertypes(of: original).map(\.name)),
            Self.list(revisedCatalogue.supertypes(of: revised).map(\.name)))
        compareMatching(
            original.eStructuralFeatures, revised.eStructuralFeatures, name: \.name, scope: path,
            describe: { feature, catalogue in
                Self.description(of: feature, opposite: Self.opposite(of: feature, in: catalogue))
            },
            element: Self.element(of:)
        ) { comparer, original, revised, path in
            comparer.compareFeature(original, revised, path: path)
        }
        compareMatching(
            original.eOperations, revised.eOperations, name: \.name, scope: path,
            describe: { operation, _ in Self.signature(of: operation) }, element: { _ in .operation }
        ) { comparer, original, revised, path in
            comparer.property(.signature, of: .operation, path: path, Self.signature(of: original), Self.signature(of: revised))
        }
    }

    // MARK: - Features

    /// The kind of a structural feature.
    private static func element(of feature: any EStructuralFeature) -> Difference.Element {
        feature is EReference ? .reference : .attribute
    }

    /// The opposite of a reference as `Class.reference`, if it has one.
    private static func opposite(of feature: any EStructuralFeature, in catalogue: MetamodelCatalogue) -> String? {
        guard let reference = feature as? EReference, let opposite = catalogue.opposite(of: reference) else { return nil }
        return opposite.owner.name + ComparisonVocabulary.pathSeparator + opposite.reference.name
    }

    /// The description of an added or removed feature, such as `Product [0..*], containment`.
    private static func description(of feature: any EStructuralFeature, opposite: String?) -> String {
        let shape = FeatureShape(feature)
        let report = FeatureReport(
            name: feature.name, type: shape.type.name, multiplicity: shape.multiplicity,
            flags: MetamodelCatalogue.flags(of: feature), defaultValue: shape.defaultValueLiteral, opposite: opposite)
        return String(InspectionTextRenderer.text(of: report).dropFirst(feature.name.count + 2))
    }

    /// Compares two matched features.
    private mutating func compareFeature(_ original: any EStructuralFeature, _ revised: any EStructuralFeature, path: String) {
        let originalKind = Self.element(of: original)
        let element = Self.element(of: revised)
        property(.kind, of: .feature, path: path, originalKind.text, element.text)
        let originalShape = FeatureShape(original)
        let revisedShape = FeatureShape(revised)
        property(.type, of: element, path: path, originalShape.type.name, revisedShape.type.name)
        property(.multiplicity, of: element, path: path, originalShape.multiplicity, revisedShape.multiplicity)
        property(
            .containment, of: element, path: path, "\((original as? EReference)?.containment ?? false)",
            "\((revised as? EReference)?.containment ?? false)")
        property(
            .opposite, of: element, path: path,
            Self.opposite(of: original, in: originalCatalogue) ?? ComparisonVocabulary.none,
            Self.opposite(of: revised, in: revisedCatalogue) ?? ComparisonVocabulary.none)
        property(
            .id, of: element, path: path, "\((original as? EAttribute)?.isID ?? false)", "\((revised as? EAttribute)?.isID ?? false)")
        property(.derived, of: element, path: path, "\(originalShape.derived)", "\(revisedShape.derived)")
        property(.transient, of: element, path: path, "\(originalShape.transient)", "\(revisedShape.transient)")
        property(.readOnly, of: element, path: path, "\(!originalShape.changeable)", "\(!revisedShape.changeable)")
        property(
            .defaultValue, of: element, path: path, originalShape.defaultValueLiteral ?? ComparisonVocabulary.none,
            revisedShape.defaultValueLiteral ?? ComparisonVocabulary.none)
    }

    // MARK: - Operations

    /// The signature of an operation, such as `total(includeTax: EBoolean): EDouble`.
    ///
    /// - Parameter operation: The operation.
    /// - Returns: The name, the parameters with their types, and the type of the result.
    static func signature(of operation: EOperation) -> String {
        let parameters = operation.eParameters.map { parameter in
            "\(parameter.name): " + typeText(parameter.eType, lower: parameter.lowerBound, upper: parameter.upperBound)
        }
        let result = typeText(operation.eType, lower: operation.lowerBound, upper: operation.upperBound)
        return "\(operation.name)(\(parameters.joined(separator: ComparisonVocabulary.listSeparator))): \(result)"
    }

    /// The type of a typed element, with its multiplicity unless that is the default `[0..1]`.
    private static func typeText(_ type: (any EClassifier)?, lower: Int, upper: Int) -> String {
        let name = MetamodelCatalogue.typeName(type)
        guard lower != 0 || upper != 1 else { return name }
        return name + " " + MetamodelCatalogue.multiplicity(lower: lower, upper: upper)
    }

    /// A list of names, or ``ComparisonVocabulary/none`` if it is empty.
    private static func list(_ names: [String]) -> String {
        names.isEmpty ? ComparisonVocabulary.none : names.joined(separator: ComparisonVocabulary.listSeparator)
    }
}
