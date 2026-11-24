//
// DocumentRelocation.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// Gives several resources the locations of the files they are about to be saved as, together.
///
/// Saving a resource as a new document, as
/// [`ModelIO.saveAs`](https://mipalgu.github.io/swift-ecore/documentation/ecore/modelio/)
/// does, gives it the URI of that document, so that the other resources of its set refer to
/// it there. When several resources that refer to each other are saved one after the other,
/// a resource written early would still refer to a resource written later at its previous
/// location. A relocation therefore gives every resource its new URI before any document is
/// written, so that all of them are written against the new locations, whichever is written
/// first. Resources may also trade places, each taking the file of another.
///
/// The first file given for a resource becomes its URI. A further file for the same resource
/// is a ``Placement/isCopy`` copy that leaves the URI as it is.
///
/// Nothing changes if the files cannot be given: two resources for the same file are a
/// ``DocumentRelocationError/sameFile(_:_:)`` error, and a file that is the document of
/// another resource of the set, which is not saved, is a
/// ``DocumentRelocationError/fileInUse(_:)`` error. If a document then cannot be written,
/// ``restore()`` gives the resources their previous URIs again.
public struct DocumentRelocation: Sendable {
    /// A resource and a file that it is saved as.
    public struct Placement: Sendable {
        /// The resource to save.
        public let resource: Resource

        /// The location of the file, as it was given.
        public let url: URL

        /// Whether the file is a further copy of a resource that is saved as another file
        /// first, so that the URI of the resource is not that of this file.
        public let isCopy: Bool
    }

    /// The placements in the order in which they were given, without a file given twice for
    /// the same resource.
    public let placements: [Placement]

    /// The resources whose URIs changed, with the URIs they had before.
    private let previousURIs: [(resource: Resource, uri: String)]

    /// The scheme of the URI that a resource holds briefly while resources trade places.
    static let interimURIPrefix = "urn:uuid:"

    /// Gives each resource the URI of the first file it is saved as.
    ///
    /// - Parameter requests: The resources and the locations of the files they are saved as,
    ///   in the order in which they are to be written.
    /// - Returns: The relocation, whose ``placements`` say which file is a copy.
    /// - Throws: ``DocumentRelocationError/sameFile(_:_:)`` if two different resources are to
    ///   be saved as the same file, and ``DocumentRelocationError/fileInUse(_:)`` if a file is
    ///   the document of another resource of the set of the resource. Nothing changes then.
    public static func relocate(_ requests: [(resource: Resource, url: URL)]) async throws -> DocumentRelocation {
        var placements: [Placement] = []
        var owners: [String: (resource: Resource, url: URL)] = [:]
        var targets: [ObjectIdentifier: String] = [:]
        var order: [Resource] = []
        for (resource, url) in requests {
            let uri = canonicalURI(of: url)
            if let owner = owners[uri] {
                guard owner.resource === resource else { throw DocumentRelocationError.sameFile(owner.url, url) }
                continue
            }
            owners[uri] = (resource, url)
            let key = ObjectIdentifier(resource)
            let isCopy = targets[key] != nil
            if !isCopy {
                targets[key] = uri
                order.append(resource)
            }
            placements.append(Placement(resource: resource, url: url, isCopy: isCopy))
        }
        var moving: [(resource: Resource, uri: String, target: String)] = []
        for resource in order {
            let uri = resource.uri
            let target = targets[ObjectIdentifier(resource)] ?? uri
            if uri != target { moving.append((resource, uri, target)) }
        }
        let previousURIs = moving.map { (resource: $0.resource, uri: $0.uri) }
        try await move(moving.map { ($0.resource, $0.target) }, from: previousURIs, owners: owners)
        return DocumentRelocation(placements: placements, previousURIs: previousURIs)
    }

    /// Gives the resources the URIs that they had before they were relocated.
    public func restore() async {
        try? await Self.move(previousURIs.map { ($0.resource, $0.uri) }, from: nil, owners: [:])
    }

    /// Gives resources new URIs by way of interim URIs, so that resources can trade places.
    ///
    /// - Parameters:
    ///   - moves: The resources and the URIs that they are to have.
    ///   - previous: The URIs to give the resources again if a move fails, or `nil` to stop
    ///     at the failure.
    ///   - owners: The files of the relocation by URI, to name a file in an error.
    /// - Throws: ``DocumentRelocationError/fileInUse(_:)`` if another resource of the set of a
    ///   resource has the URI that it is to have.
    private static func move(
        _ moves: [(Resource, String)], from previous: [(resource: Resource, uri: String)]?,
        owners: [String: (resource: Resource, url: URL)]
    ) async throws {
        for (resource, _) in moves {
            try await resource.setURI(interimURIPrefix + UUID().uuidString)
        }
        for (index, (resource, uri)) in moves.enumerated() {
            do {
                try await resource.setURI(uri)
            } catch ResourceSetError.uriInUse {
                if let previous {
                    for (moved, _) in moves[..<index] { try? await moved.setURI(interimURIPrefix + UUID().uuidString) }
                    for (resource, uri) in previous { try? await resource.setURI(uri) }
                }
                throw DocumentRelocationError.fileInUse(owners[uri]?.url ?? URL(string: uri) ?? URL(fileURLWithPath: uri))
            }
        }
    }

    /// The canonical URI of the document at a location.
    ///
    /// - Parameter url: The location.
    /// - Returns: The URI that a resource saved there has.
    public static func canonicalURI(of url: URL) -> String {
        URIReference.canonicalise(url.absoluteURL.absoluteString)
    }
}

/// An error that prevents resources from being saved together as new documents.
public enum DocumentRelocationError: Error, Sendable, Hashable, CustomStringConvertible, LocalizedError {
    /// Two different resources are to be saved as the same file.
    ///
    /// The associated values are the locations as given, first the earlier and then the later,
    /// which may be spelt differently.
    case sameFile(URL, URL)

    /// A file is the document of another resource of the resource set, which is not saved.
    ///
    /// The associated value is the location of the file as given.
    case fileInUse(URL)

    /// A sentence that names the files involved.
    public var description: String {
        switch self {
        case .sameFile(let first, let second):
            let names = first.path == second.path ? first.path : "\(first.path) and \(second.path)"
            return "Cannot write two models to the same file: \(names)"
        case .fileInUse(let url):
            return "Cannot write \(url.path): it is the file of another model that is read but not written"
        }
    }

    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
