//
// XMIIdentifierIndex.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

#if canImport(FoundationXML)
    import FoundationXML
#endif

/// The position of an object of an XMI document within the containment tree of its model.
///
/// The position starts with the index of the root object among the root objects of the
/// document, followed by one step for each containment reference from the root to the object.
struct ContainmentPath: Sendable, Equatable, CustomStringConvertible {
    /// One step from a container to one of the objects it contains.
    struct Step: Sendable, Equatable {
        /// The name of the containment reference.
        let feature: String

        /// The position of the object among the objects of the reference, from 0.
        let index: Int
    }

    /// The position of the root object among the root objects of the document, from 0.
    let root: Int

    /// The steps from the root object to the object.
    let steps: [Step]

    /// Creates a position from its parts.
    ///
    /// - Parameters:
    ///   - root: The position of the root object among the root objects of the document.
    ///   - steps: The steps from the root object to the object.
    init(root: Int, steps: [Step]) {
        self.root = root
        self.steps = steps
    }

    /// Reads a position from an XMI fragment path.
    ///
    /// The path starts with a slash and may name the root object by its position, as in
    /// `/1/@employees.0`; without one, as in `//@departments.0/@employees.1`, it starts at the
    /// first root object. Each further segment is `@` followed by the name of a containment
    /// reference and, for a many-valued reference, a full stop and the position of the object
    /// from 0.
    ///
    /// - Parameter fragment: The fragment path.
    /// - Returns: The position, or `nil` if the text is not a fragment path.
    init?(fragment: String) {
        typealias Syntax = SwiftAQLVocabulary.Fragment
        guard fragment.hasPrefix(String(Syntax.separator)) else { return nil }
        var segments = fragment.split(separator: Syntax.separator)
        var root = 0
        if let first = segments.first, let index = Int(first) {
            guard index >= 0 else { return nil }
            root = index
            segments.removeFirst()
        }
        var steps: [Step] = []
        for segment in segments {
            guard segment.first == Syntax.featureMarker else { return nil }
            let body = segment.dropFirst()
            let parts = body.split(separator: Syntax.indexSeparator, omittingEmptySubsequences: false)
            guard let name = parts.first, !name.isEmpty, parts.count <= 2 else { return nil }
            var index = 0
            if parts.count == 2 {
                guard let position = Int(parts[1]), position >= 0 else { return nil }
                index = position
            }
            steps.append(Step(feature: String(name), index: index))
        }
        self.init(root: root, steps: steps)
    }

    /// The path as an XMI fragment, such as `/0/@departments.1/@employees.0`.
    var description: String {
        typealias Syntax = SwiftAQLVocabulary.Fragment
        let separator = String(Syntax.separator)
        return separator + String(root)
            + steps.map { separator + String(Syntax.featureMarker) + $0.feature + String(Syntax.indexSeparator) + String($0.index) }
            .joined()
    }
}

/// The identifiers that the elements of an XMI document declare with `xmi:id`, and where the
/// objects they identify are.
///
/// The index reads the document as XML, without a metamodel, so that an object can be found by
/// the identifier that the document gives it even though the loaded model does not keep it.
struct XMIIdentifierIndex: Sendable {
    /// The positions of the identified objects, by identifier.
    let paths: [String: ContainmentPath]

    /// Reads the identifiers of an XMI document.
    ///
    /// - Parameter data: The document.
    /// - Returns: The index, which is empty if the document is not well-formed XML.
    init(data: Data) {
        let collector = Collector()
        let parser = XMLParser(data: data)
        parser.delegate = collector
        parser.shouldProcessNamespaces = false
        paths = parser.parse() ? collector.paths : [:]
    }

    /// The position of the object with an identifier.
    ///
    /// - Parameter identifier: The identifier.
    /// - Returns: The position, or `nil` if no element declares the identifier.
    func path(of identifier: String) -> ContainmentPath? {
        paths[identifier]
    }

    /// Follows the elements of a document and records where each identified element is.
    private final class Collector: NSObject, XMLParserDelegate {
        /// The positions of the identified objects, by identifier.
        var paths: [String: ContainmentPath] = [:]

        /// One open element of the document.
        private struct Frame {
            /// The step that leads to the element, if it is an object below a root object.
            let step: ContainmentPath.Step?

            /// The number of child elements with each name seen so far.
            var childCounts: [String: Int] = [:]
        }

        /// The open elements, outermost first.
        private var frames: [Frame] = []

        /// Whether the document element wraps the root objects.
        private var hasWrapper = false

        /// The number of root objects seen so far.
        private var rootCount = 0

        /// The position of the current root object.
        private var currentRoot = 0

        /// Records the position of an element that starts, and its identifier if it has one.
        ///
        /// - Parameters:
        ///   - parser: The parser of the document.
        ///   - elementName: The qualified name of the element.
        ///   - namespaceURI: The namespace of the element, if namespaces are processed.
        ///   - qName: The qualified name, if namespaces are processed.
        ///   - attributes: The attributes of the element.
        func parser(
            _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
            qualifiedName qName: String?, attributes: [String: String] = [:]
        ) {
            let localName = String(
                elementName.split(separator: SwiftAQLVocabulary.XMI.prefixSeparator).last ?? Substring(elementName))
            var step: ContainmentPath.Step?
            if frames.isEmpty {
                hasWrapper = localName == SwiftAQLVocabulary.XMI.documentElement
                if !hasWrapper { startRoot() }
            } else if hasWrapper && frames.count == 1 {
                startRoot()
            } else {
                let index = frames[frames.count - 1].childCounts[elementName, default: 0]
                frames[frames.count - 1].childCounts[elementName] = index + 1
                step = ContainmentPath.Step(feature: elementName, index: index)
            }
            frames.append(Frame(step: step))
            guard let identifier = attributes[SwiftAQLVocabulary.XMI.identifierAttribute],
                !(hasWrapper && frames.count == 1)
            else { return }
            paths[identifier] = ContainmentPath(root: currentRoot, steps: frames.compactMap(\.step))
        }

        /// Closes the element that ends.
        ///
        /// - Parameters:
        ///   - parser: The parser of the document.
        ///   - elementName: The qualified name of the element.
        ///   - namespaceURI: The namespace of the element, if namespaces are processed.
        ///   - qName: The qualified name, if namespaces are processed.
        func parser(
            _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            frames.removeLast()
        }

        /// Starts a new root object.
        private func startRoot() {
            currentRoot = rootCount
            rootCount += 1
        }
    }
}
