//
// InspectionTextRenderer.swift
// swift-ecore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// Writes an inspection report as indented text.
enum InspectionTextRenderer {
    /// One level of indentation.
    static let indent = "  "

    /// The arrow between the source and the target of a reference.
    static let arrow = " -> "

    /// The text of a report.
    ///
    /// - Parameter report: The report.
    /// - Returns: The text, ending with a line break.
    static func render(_ report: InspectionReport) -> String {
        var lines: [String] = []
        let title = Self.titlePrefix(of: report.kind) + "\(report.file) (\(report.format))"
        lines.append(title)
        lines.append(String(repeating: "=", count: title.count))
        if let multiLevel = report.multiLevel { render(multiLevel, into: &lines) }
        for package in report.packages ?? [] {
            lines.append("")
            render(package, depth: 0, into: &lines)
        }
        if let model = report.model { render(model, into: &lines) }
        if let hierarchy = report.hierarchy {
            lines.append("")
            lines.append("Inheritance hierarchy:")
            for node in hierarchy { render(node, depth: 1, into: &lines) }
        }
        if let graph = report.referenceGraph {
            lines.append("")
            lines.append(report.kind == .metamodel ? "Reference graph:" : "Cross references:")
            if graph.isEmpty { lines.append(indent + "(none)") }
            for edge in graph { lines.append(indent + text(of: edge)) }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// The text that starts the title of a report.
    ///
    /// - Parameter kind: The kind of document.
    /// - Returns: `Metamodel: `, `Model: ` or `Multi-level model: `.
    static func titlePrefix(of kind: InspectionReport.Kind) -> String {
        switch kind {
        case .metamodel: return "Metamodel: "
        case .model: return "Model: "
        case .multiLevelModel: return "Multi-level model: "
        }
    }

    // MARK: - Multi-level models

    /// Adds the lines of the levels of a multi-level model.
    ///
    /// - Parameters:
    ///   - report: The levels of the model.
    ///   - lines: The lines to add to.
    private static func render(_ report: MultiLevelReport, into lines: inout [String]) {
        lines.append("")
        lines.append("Potency scheme: \(report.potencyVariant)")
        lines.append("Level crossing: \(report.levelCrossing)")
        for level in report.levels {
            lines.append("")
            let instantiates = level.typeModel.map { " (instance of \($0))" } ?? ""
            lines.append("Level \(level.level): \(level.name)\(instantiates)")
            if level.clabjects.isEmpty { lines.append(indent + "(no clabjects)") }
            for clabject in level.clabjects {
                var line = indent + (clabject.isAbstract ? "abstract " : "") + (clabject.isEdge ? "Edge " : "")
                line += clabject.name + (clabject.type.map { " : \($0)" } ?? "")
                if let potency = clabject.potency { line += " @\(potency)" }
                if !clabject.features.isEmpty { line += " { " + clabject.features.joined(separator: ", ") + " }" }
                lines.append(line)
            }
        }
    }

    // MARK: - Metamodels

    /// Adds the lines of a package and its subpackages.
    private static func render(_ package: PackageReport, depth: Int, into lines: inout [String]) {
        let pad = String(repeating: indent, count: depth)
        lines.append(pad + "Package \(package.name)")
        lines.append(pad + indent + "Namespace URI: \(package.nsURI)")
        lines.append(pad + indent + "Namespace prefix: \(package.nsPrefix)")
        let abstract = package.classes.filter { $0.abstract && !$0.interface }.count
        let interfaces = package.classes.filter(\.interface).count
        var classSummary = "Classes: \(package.classes.count)"
        var qualifiers: [String] = []
        if abstract > 0 { qualifiers.append("\(abstract) abstract") }
        if interfaces > 0 { qualifiers.append("\(interfaces) \(interfaces == 1 ? "interface" : "interfaces")") }
        if !qualifiers.isEmpty { classSummary += " (" + qualifiers.joined(separator: ", ") + ")" }
        lines.append(pad + indent + classSummary)
        lines.append(pad + indent + "Enumerations: \(package.enumerations.count)")
        lines.append(pad + indent + "Data types: \(package.dataTypes.count)")
        for enumeration in package.enumerations {
            lines.append("")
            lines.append(pad + indent + "Enumeration \(enumeration.name)")
            for literal in enumeration.literals {
                lines.append(pad + indent + indent + "\(literal.name) = \(literal.value)")
            }
        }
        for dataType in package.dataTypes {
            lines.append("")
            let instance = dataType.instanceClassName.map { " (\($0))" } ?? ""
            lines.append(pad + indent + "Data type \(dataType.name)\(instance)")
        }
        var previousHadSections = true
        for eClass in package.classes {
            var block: [String] = []
            render(eClass, pad: pad + indent, into: &block)
            if previousHadSections || block.count > 1 { lines.append("") }
            lines += block
            previousHadSections = block.count > 1
        }
        for subpackage in package.subpackages {
            lines.append("")
            render(subpackage, depth: depth + 1, into: &lines)
        }
    }

    /// Adds the lines of a class.
    private static func render(_ eClass: ClassReport, pad: String, into lines: inout [String]) {
        var header = (eClass.interface ? "Interface " : eClass.abstract ? "Abstract class " : "Class ") + eClass.name
        if !eClass.supertypes.isEmpty { header += " extends " + eClass.supertypes.joined(separator: ", ") }
        lines.append(pad + header)
        let inner = pad + indent
        if let all = eClass.allSupertypes, all.count > eClass.supertypes.count {
            lines.append(inner + "All supertypes: " + all.joined(separator: ", "))
        }
        if let subclasses = eClass.subclasses, !subclasses.isEmpty {
            lines.append(inner + "Subclasses: " + subclasses.joined(separator: ", "))
        }
        section("Attributes", eClass.attributes, pad: inner, into: &lines)
        section("References", eClass.references, pad: inner, into: &lines)
        section("Inherited features", eClass.inheritedFeatures, pad: inner, into: &lines)
        if let operations = eClass.operations, !operations.isEmpty {
            lines.append(inner + "Operations:")
            for operation in operations {
                let parameters = operation.parameters.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
                lines.append(inner + indent + "\(operation.name)(\(parameters)): \(operation.returnType)")
            }
        }
        if let constraints = eClass.constraints, !constraints.isEmpty {
            lines.append(inner + "Invariants: " + constraints.joined(separator: ", "))
        }
    }

    /// Adds a titled list of features, unless the list was not asked for or is empty.
    private static func section(_ title: String, _ features: [FeatureReport]?, pad: String, into lines: inout [String]) {
        guard let features, !features.isEmpty else { return }
        lines.append(pad + title + ":")
        for feature in features { lines.append(pad + indent + text(of: feature)) }
    }

    /// The text of a feature, such as `employees: Person [0..*], containment, opposite Person.employer`.
    static func text(of feature: FeatureReport) -> String {
        var parts = ["\(feature.name): \(feature.type) \(feature.multiplicity)"]
        parts += feature.flags
        if let defaultValue = feature.defaultValue { parts.append("default \(defaultValue)") }
        if let opposite = feature.opposite { parts.append("opposite \(opposite)") }
        if let owner = feature.declaredBy { parts.append("from \(owner)") }
        return parts.joined(separator: ", ")
    }

    /// Adds the lines of a class and the classes that extend it.
    private static func render(_ node: HierarchyNode, depth: Int, into lines: inout [String]) {
        let flags = node.flags.isEmpty ? "" : " (" + node.flags.joined(separator: ", ") + ")"
        lines.append(String(repeating: indent, count: depth) + node.name + flags)
        for subclass in node.subclasses { render(subclass, depth: depth + 1, into: &lines) }
    }

    /// The text of a reference between classes or objects.
    static func text(of edge: ReferenceEdge) -> String {
        var text = "\(edge.source).\(edge.reference)\(arrow)\(edge.target)"
        if let multiplicity = edge.multiplicity { text += " \(multiplicity)" }
        var flags: [String] = []
        if edge.containment { flags.append(ModelVocabulary.containmentFlag) }
        if let opposite = edge.opposite { flags.append("opposite \(opposite)") }
        if !flags.isEmpty { text += ", " + flags.joined(separator: ", ") }
        return text
    }

    // MARK: - Models

    /// Adds the lines of a model.
    private static func render(_ model: ModelReport, into lines: inout [String]) {
        if !model.metamodels.isEmpty { lines.append("Metamodels: " + model.metamodels.joined(separator: ", ")) }
        lines.append("Root objects: \(model.rootObjects)")
        lines.append("Objects: \(model.objects)")
        lines.append("")
        lines.append("Classes:")
        for entry in model.classes {
            let supertypes = entry.supertypes.flatMap { $0.isEmpty ? nil : " (extends " + $0.joined(separator: ", ") + ")" } ?? ""
            lines.append(indent + "\(entry.name): \(entry.count)\(supertypes)")
        }
        if let tree = model.tree {
            lines.append("")
            lines.append("Objects:")
            for object in tree { render(object, depth: 1, into: &lines) }
        }
    }

    /// Adds the lines of an object and everything it contains.
    private static func render(_ object: ObjectReport, depth: Int, into lines: inout [String]) {
        let pad = String(repeating: indent, count: depth)
        lines.append(pad + "\(object.label) (\(object.location))")
        for attribute in object.attributes {
            lines.append(pad + indent + "\(attribute.name) = " + list(attribute.values))
        }
        for reference in object.references {
            lines.append(pad + indent + reference.name + arrow + list(reference.values))
        }
        for contained in object.contents {
            lines.append(pad + indent + "\(contained.feature):")
            for child in contained.objects { render(child, depth: depth + 2, into: &lines) }
        }
    }

    /// One value as it is, several values in brackets.
    private static func list(_ values: [String]) -> String {
        values.count == 1 ? values[0] : "[" + values.joined(separator: ", ") + "]"
    }
}
