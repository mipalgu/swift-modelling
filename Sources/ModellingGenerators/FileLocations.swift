//
// FileLocations.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Gives file locations one canonical form, so that locations can be compared and related to each other.
enum FileLocations {
    /// The canonical form of a file location.
    ///
    /// Symbolic links are resolved in the directory part of the path, up to its longest existing prefix,
    /// and the rest of the path is kept as given. A file that does not exist yet (such as an output file)
    /// is therefore resolved in the same way as one that does, and a file that is itself a link keeps its
    /// name. Redundant components such as `..` are removed.
    ///
    /// - Parameter url: A file URL.
    /// - Returns: The canonical file URL.
    static func canonical(_ url: URL) -> URL {
        let standard = url.standardizedFileURL
        let name = standard.lastPathComponent
        var existing = standard.deletingLastPathComponent()
        var remainder: [String] = []
        while !FileManager.default.fileExists(atPath: existing.path) {
            let parent = existing.deletingLastPathComponent()
            guard parent.path != existing.path else { break }
            remainder.insert(existing.lastPathComponent, at: 0)
            existing = parent
        }
        var resolved = existing.resolvingSymlinksInPath()
        for component in remainder { resolved.appendPathComponent(component) }
        return resolved.appendingPathComponent(name).standardizedFileURL
    }
}
