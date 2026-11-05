//
// MetamodelDiscovery.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import ModellingCommandLine

/// Finds the Ecore metamodels of models that are given without `--metamodel`.
///
/// A model refers to its metamodels by their namespace URIs, for example through a namespace
/// declaration such as `xmlns:company="http://www.example.org/company"` in XMI, or a class
/// reference such as `"http://www.example.org/company#//Company"` in JSON. Discovery looks at
/// the Ecore files in the directory of each model and selects every file whose root package
/// declares a namespace URI that the model refers to. Files that cannot be read, and files
/// that are models themselves, are left out.
///
/// When several files in one directory declare the same namespace URI that a model refers to,
/// discovery cannot tell which one is meant and reports them, so that one can be chosen with
/// `--metamodel`.
struct MetamodelDiscovery: Sendable {
    /// Creates a discovery.
    init() {}

    /// The metamodel files that the models refer to.
    ///
    /// - Parameter models: The paths of the model files, as given on the command line.
    /// - Returns: The paths of the metamodel files, without repetitions, in the order in which
    ///   the models and the files of their directories are listed.
    /// - Throws: ``SwiftAQLError/ambiguousMetamodels(_:_:)`` if several files beside a model
    ///   declare a namespace URI that the model refers to.
    func metamodels(for models: [String]) throws -> [String] {
        let modelPaths = Set(models.map { URL(fileURLWithPath: $0).standardizedFileURL.path })
        var found: [String] = []
        for model in models {
            let url = URL(fileURLWithPath: model)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let candidates = ecoreFiles(in: url.deletingLastPathComponent())
                .filter { !modelPaths.contains($0.standardizedFileURL.path) }
            var byNamespace: [String: [String]] = [:]
            var order: [String] = []
            for candidate in candidates {
                guard let namespace = namespaceURI(ofMetamodelAt: candidate),
                    refers(text, to: namespace)
                else { continue }
                if byNamespace[namespace] == nil { order.append(namespace) }
                byNamespace[namespace, default: []].append(candidate.path)
            }
            for namespace in order {
                let paths = byNamespace[namespace] ?? []
                guard paths.count == 1, let path = paths.first else {
                    throw SwiftAQLError.ambiguousMetamodels(namespace, paths)
                }
                if !found.contains(path) { found.append(path) }
            }
        }
        return found
    }

    /// The Ecore files in a directory, sorted by name.
    ///
    /// - Parameter directory: The directory.
    /// - Returns: The files whose extension names an Ecore metamodel, or no files if the
    ///   directory cannot be read.
    func ecoreFiles(in directory: URL) -> [URL] {
        let contents =
            (try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return contents
            .filter { MetamodelRegistration.isEcoreFile($0.path) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// The namespace URI of the root package of a metamodel file.
    ///
    /// - Parameter url: The location of the Ecore file.
    /// - Returns: The first namespace URI that the file declares, or `nil` if it declares none
    ///   or cannot be read.
    func namespaceURI(ofMetamodelAt url: URL) -> String? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return namespaceURI(declaredIn: text)
    }

    /// The first namespace URI that the text of an Ecore file declares.
    ///
    /// - Parameter text: The text of an Ecore file.
    /// - Returns: The value of the first `nsURI` attribute, or `nil` if there is none or it is
    ///   empty.
    func namespaceURI(declaredIn text: String) -> String? {
        let attribute = SwiftAQLVocabulary.Discovery.namespaceURIAttribute
        var remainder = text[...]
        while let range = remainder.range(of: attribute) {
            remainder = remainder[range.upperBound...]
            let afterName = remainder.drop { $0.isWhitespace }
            guard afterName.first == "=" else { continue }
            let afterEquals = afterName.dropFirst().drop { $0.isWhitespace }
            guard let quote = afterEquals.first, quote == "\"" || quote == "'" else { continue }
            let value = afterEquals.dropFirst().prefix { $0 != quote }
            return value.isEmpty ? nil : String(value)
        }
        return nil
    }

    /// Whether the text of a model refers to a namespace URI.
    ///
    /// - Parameters:
    ///   - text: The text of a model file.
    ///   - namespace: The namespace URI of a metamodel.
    /// - Returns: `true` if the URI occurs in the text followed by a quote or by `#`.
    func refers(_ text: String, to namespace: String) -> Bool {
        var remainder = text[...]
        while let range = remainder.range(of: namespace) {
            remainder = remainder[range.upperBound...]
            if let next = remainder.first, SwiftAQLVocabulary.Discovery.namespaceURITerminators.contains(next) {
                return true
            }
        }
        return false
    }
}
