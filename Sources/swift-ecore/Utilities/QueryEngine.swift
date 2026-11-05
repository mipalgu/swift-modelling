//
// QueryEngine.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

// MARK: - Query Engine

/// Runs queries against a model or a metamodel.
///
/// Every query looks at the whole document: the objects of a model however deeply they are
/// contained, and every element of a metamodel. See ``QueryKind`` for the queries.
struct QueryEngine: Sendable {
    /// The document to query.
    let document: ModelDocument

    /// Creates a query engine.
    ///
    /// - Parameter document: The document to query.
    init(document: ModelDocument) {
        self.document = document
    }

    /// Runs a query.
    ///
    /// - Parameter query: The query expression: the name of a query, followed by a class name
    ///   for ``QueryKind/find``.
    /// - Returns: The result as text.
    /// - Throws: ``QueryError`` if the query is empty, unknown or lacks its argument.
    func execute(_ query: String) async throws -> String {
        let parts = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let name = parts.first else {
            throw QueryError.invalidQuery("Empty query")
        }
        guard let kind = QueryKind.named(name) else {
            throw QueryError.unsupportedQuery(name)
        }
        if kind == .find && parts.count < 2 {
            throw QueryError.invalidQuery("find requires a class name")
        }
        return document.isMetamodel ? metamodelQuery(kind, parts) : await modelQuery(kind, parts)
    }

    // MARK: - Models

    /// Runs a query against a model.
    private func modelQuery(_ kind: QueryKind, _ parts: [String]) async -> String {
        let objects = await ModelCatalogue.build(for: document)
        switch kind {
        case .info:
            var lines = Self.heading("Model Information")
            lines.append("File: \(document.fileName) (\(document.formatName))")
            if document.hasMetamodel { lines.append("Metamodels: " + document.metamodels.map(\.nsURI).joined(separator: ", ")) }
            lines.append("Root objects: \(objects.roots.count)")
            lines.append("Total objects: \(objects.entries.count)")
            if !objects.entries.isEmpty {
                lines.append("")
                lines.append("Classes:")
                for (name, count) in objects.classCounts { lines.append("  * \(name): \(count)") }
            }
            return Self.text(lines)
        case .count:
            return "Total objects: \(objects.entries.count)\n"
        case .listClasses:
            var lines = Self.heading("Classes")
            let counts = Dictionary(uniqueKeysWithValues: objects.classCounts.map { ($0.name, $0.count) })
            for eClass in objects.instantiatedClasses {
                lines.append("* \(eClass.name): \(counts[eClass.name] ?? 0)" + Self.qualifiers(of: eClass))
            }
            return Self.text(lines)
        case .hierarchy:
            return hierarchy(fallback: objects.instantiatedClasses)
        case .find:
            let matches = objects.entries(ofClassNamed: parts[1])
            var lines = Self.heading("Objects matching '\(parts[1])'")
            lines.append("Found \(matches.count) match(es)")
            for (index, entry) in matches.enumerated() {
                lines.append("")
                lines.append("\(index + 1). \(objects.labelWithLocation(of: entry.object))")
                lines += await featureLines(of: entry, objects: objects, indent: "   ")
            }
            return Self.text(lines)
        case .tree:
            let roots = objects.entries.filter { $0.container == nil }.map { treeNode($0, objects: objects) }
            return Self.text(Self.heading("Object Tree") + TreeText.lines(of: roots))
        }
    }

    /// The lines that show the features an object sets.
    private func featureLines(of entry: ModelCatalogue.Entry, objects: ModelCatalogue, indent: String) async -> [String] {
        let object = entry.object
        let eClass = objects.eClass(of: object)
        var lines: [String] = []
        for attribute in MetamodelCatalogue.attributes(of: eClass) where object.eIsSet(attribute.name) {
            lines.append(indent + "\(attribute.name) = " + ValueText.describe(object.eGet(attribute.name), of: attribute))
        }
        for reference in MetamodelCatalogue.references(of: eClass) where object.eIsSet(reference.name) && !reference.containment && !reference.container {
            let targets = await objects.describeTargets(of: object.eGet(reference.name))
            lines.append(indent + "\(reference.name) -> " + (targets.count == 1 ? targets[0] : "[" + targets.joined(separator: ", ") + "]"))
        }
        for reference in MetamodelCatalogue.references(of: eClass) where reference.containment {
            let children = objects.children(of: object.id).filter { $0.feature == reference.name }
            if !children.isEmpty { lines.append(indent + "\(reference.name): \(children.count) contained object(s)") }
        }
        let declared = Set(eClass.eAllStructuralFeatures.map(\.name))
        for name in object.getFeatureNames() where !declared.contains(name) {
            lines.append(indent + "\(name) = " + ValueText.describe(object.eGet(name)))
        }
        return lines
    }

    /// The node of an object and the objects it contains.
    private func treeNode(_ entry: ModelCatalogue.Entry, objects: ModelCatalogue) -> TreeText.Node {
        let prefix = entry.feature.map { "\($0): " } ?? ""
        return TreeText.Node(
            text: prefix + objects.labelWithLocation(of: entry.object),
            children: objects.children(of: entry.object.id).map { treeNode($0, objects: objects) })
    }

    // MARK: - Metamodels

    /// Runs a query against a metamodel.
    private func metamodelQuery(_ kind: QueryKind, _ parts: [String]) -> String {
        let catalogue = MetamodelCatalogue(roots: document.packages)
        let index = MetamodelIndex(roots: document.packages)
        let elements = Self.elements(of: document.packages)
        switch kind {
        case .info:
            var lines = Self.heading("Metamodel Information")
            lines.append("File: \(document.fileName) (\(document.formatName))")
            let roots = document.packages.map { "EPackage \($0.name)" }.joined(separator: ", ")
            lines.append("Root objects: \(document.packages.count) (\(roots))")
            lines.append("Total objects: \(elements.count)")
            lines.append("")
            lines.append("Packages:")
            for package in catalogue.packages {
                let classes = package.eClassifiers.filter { $0 is EClass }.count
                let enumerations = package.eClassifiers.filter { $0 is EEnum }.count
                let dataTypes = package.eClassifiers.count - classes - enumerations
                lines.append(
                    "  * \(package.name) (\(package.nsURI)): \(classes) class(es), \(enumerations) enumeration(s), \(dataTypes) data type(s)")
            }
            lines.append("")
            lines.append("Objects by kind:")
            var counts: [String: Int] = [:]
            for element in elements { counts[element.eClass.name, default: 0] += 1 }
            for (name, count) in counts.sorted(by: { $0.key < $1.key }) { lines.append("  * \(name): \(count)") }
            return Self.text(lines)
        case .count:
            return "Total objects: \(elements.count)\n"
        case .listClasses:
            var lines = Self.heading("Classes")
            for eClass in catalogue.classes { lines.append("* \(eClass.name)" + Self.qualifiers(of: eClass)) }
            return Self.text(lines)
        case .hierarchy:
            return hierarchy(fallback: [])
        case .find:
            let wanted = parts[1].lowercased()
            let matches = elements.filter { $0.eClass.name.lowercased() == wanted }
            var lines = Self.heading("Objects matching '\(parts[1])'")
            lines.append("Found \(matches.count) match(es)")
            for (position, element) in matches.enumerated() {
                let location = index.fragment(of: element.id).map { " (\($0))" } ?? ""
                lines.append("\(position + 1). \(Self.label(of: element))\(location)")
            }
            return Self.text(lines)
        case .tree:
            return Self.text(Self.heading("Metamodel Tree") + TreeText.lines(of: document.packages.map(Self.node(of:))))
        }
    }

    /// The elements of packages in document order, without annotations.
    private static func elements(of packages: [EPackage]) -> [any EObject] {
        var result: [any EObject] = []
        func add(_ package: EPackage) {
            result.append(package)
            for classifier in package.eClassifiers {
                if let object = classifier as? any EObject { result.append(object) }
                switch classifier {
                case let eClass as EClass:
                    result += eClass.eStructuralFeatures.compactMap { $0 as? any EObject }
                    for operation in eClass.eOperations {
                        result.append(operation)
                        result += operation.eParameters.map { $0 as any EObject }
                    }
                case let eEnum as EEnum:
                    result += eEnum.literals.map { $0 as any EObject }
                default:
                    break
                }
            }
            package.eSubpackages.forEach(add)
        }
        packages.forEach(add)
        return result
    }

    /// The name of the metaclass of an attribute or a reference.
    private static func metaclassName(of feature: any EStructuralFeature) -> String {
        switch feature {
        case let attribute as EAttribute: return attribute.eClass.name
        case let reference as EReference: return reference.eClass.name
        default: return feature.name
        }
    }

    /// The description of a metamodel element: its metaclass and its name.
    private static func label(of element: any EObject) -> String {
        guard let named = element as? any ENamedElement else { return element.eClass.name }
        return "\(element.eClass.name) \(named.name)"
    }

    /// The node of a package and its contents.
    private static func node(of package: EPackage) -> TreeText.Node {
        var children: [TreeText.Node] = []
        for classifier in package.eClassifiers {
            switch classifier {
            case let eClass as EClass:
                let features = eClass.eStructuralFeatures.map { feature in
                    let shape = FeatureShape(feature)
                    let flags = MetamodelCatalogue.flags(of: feature)
                    let suffix = flags.isEmpty ? "" : " (" + flags.joined(separator: ", ") + ")"
                    return TreeText.Node(
                        text: "\(Self.metaclassName(of: feature)) \(feature.name): \(shape.type.name) \(shape.multiplicity)\(suffix)",
                        children: [])
                }
                let operations = eClass.eOperations.map { operation in
                    TreeText.Node(
                        text: "EOperation \(operation.name): \(MetamodelCatalogue.typeName(operation.eType))",
                        children: operation.eParameters.map {
                            TreeText.Node(text: "EParameter \($0.name): \(MetamodelCatalogue.typeName($0.eType))", children: [])
                        })
                }
                children.append(TreeText.Node(text: "EClass \(eClass.name)" + qualifiers(of: eClass), children: features + operations))
            case let eEnum as EEnum:
                children.append(
                    TreeText.Node(
                        text: "EEnum \(eEnum.name)",
                        children: eEnum.literals.map { TreeText.Node(text: "EEnumLiteral \($0.name) = \($0.value)", children: []) }))
            default:
                children.append(TreeText.Node(text: "EDataType \(classifier.name)", children: []))
            }
        }
        children += package.eSubpackages.map(node(of:))
        return TreeText.Node(text: "EPackage \(package.name) (\(package.nsURI))", children: children)
    }

    // MARK: - Shared

    /// The inheritance hierarchy of the classes that describe the document.
    ///
    /// - Parameter fallback: The classes to list when no metamodel describes the document.
    private func hierarchy(fallback: [EClass]) -> String {
        let catalogue = MetamodelCatalogue(roots: document.describingPackages)
        func node(_ eClass: EClass) -> TreeText.Node {
            TreeText.Node(text: eClass.name + Self.flags(of: eClass), children: catalogue.directSubclasses(of: eClass).map(node))
        }
        let roots = catalogue.classes.isEmpty ? fallback : catalogue.hierarchyRoots
        return Self.text(Self.heading("Class Hierarchy") + TreeText.lines(of: roots.map(node)))
    }

    /// The flags of a class in parentheses, such as ` (abstract)`, or nothing.
    private static func flags(of eClass: EClass) -> String {
        let flags = MetamodelCatalogue.flags(of: eClass)
        return flags.isEmpty ? "" : " (" + flags.joined(separator: ", ") + ")"
    }

    /// The flags and direct supertypes of a class in parentheses, or nothing.
    private static func qualifiers(of eClass: EClass) -> String {
        var parts = MetamodelCatalogue.flags(of: eClass)
        if !eClass.eSuperTypes.isEmpty { parts.append("extends " + eClass.eSuperTypes.map(\.name).joined(separator: ", ")) }
        return parts.isEmpty ? "" : " (" + parts.joined(separator: ", ") + ")"
    }

    /// A title underlined with equals signs.
    private static func heading(_ title: String) -> [String] {
        [title, String(repeating: "=", count: title.count)]
    }

    /// Lines joined into a text that ends with a line break.
    private static func text(_ lines: [String]) -> String {
        lines.joined(separator: "\n") + "\n"
    }
}

/// Draws trees with text branches.
enum TreeText {
    /// A line of a tree and the lines below it.
    struct Node: Sendable {
        /// The text of the line.
        let text: String

        /// The nodes below this one.
        let children: [Node]
    }

    /// The branch before a node that has siblings after it.
    static let branch = "|-- "

    /// The branch before the last node of its siblings.
    static let lastBranch = "+-- "

    /// The continuation below a node that has siblings after it.
    static let continuation = "|   "

    /// The continuation below the last node of its siblings.
    static let lastContinuation = "    "

    /// The lines of a forest of trees.
    ///
    /// - Parameter nodes: The roots of the trees.
    /// - Returns: One line per node, with branches that show the structure.
    static func lines(of nodes: [Node]) -> [String] {
        var lines: [String] = []
        func add(_ node: Node, prefix: String, isLast: Bool) {
            lines.append(prefix + (isLast ? lastBranch : branch) + node.text)
            let next = prefix + (isLast ? lastContinuation : continuation)
            for (index, child) in node.children.enumerated() {
                add(child, prefix: next, isLast: index == node.children.count - 1)
            }
        }
        for (index, node) in nodes.enumerated() { add(node, prefix: "", isLast: index == nodes.count - 1) }
        return lines
    }
}
