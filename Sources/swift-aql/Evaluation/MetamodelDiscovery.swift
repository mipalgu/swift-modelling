//
// MetamodelDiscovery.swift
// swift-aql
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import ModellingCommandLine

/// Finds the metamodels of models that are given without `--metamodel`.
///
/// A model refers to its metamodels by their namespace URIs, for example through a namespace
/// declaration such as `xmlns:company="http://www.example.org/company"` in XMI, or a class
/// reference such as `"http://www.example.org/company#//Company"` in JSON. Discovery looks at
/// the files in the directory of each model whose format may hold a metamodel, such as Ecore,
/// JSON and KM3 files, and selects every file whose root package declares a namespace URI that
/// the model refers to. The format registry decides from the extension and the contents of
/// each file whether it may hold a metamodel, so an EMOF metamodel in an `.xmi` file is found
/// as well as the metamodels of the textual formats, such as Emfatic or a grammar. A KM3
/// package has no namespace URI and is registered under its name, so a model refers to it by a
/// namespace declaration with that name, such as `xmlns:company="Company"`. Files that cannot
/// be read, and files that are models themselves, are left out.
///
/// When several files in one directory declare the same namespace URI that a model refers to,
/// discovery cannot tell which one is meant and reports them, so that one can be chosen with
/// `--metamodel`.
struct MetamodelDiscovery: Sendable {
    /// The options with which metamodels in formats that need them, such as grammars, are read.
    let options: EcoreLoadOptions

    /// Creates a discovery.
    ///
    /// - Parameter options: The options with which metamodels are read, so that a grammar
    ///   import declares the namespace URI that it registers (default options).
    init(options: EcoreLoadOptions = EcoreLoadOptions()) {
        self.options = options
    }

    /// The metamodel files that the models refer to.
    ///
    /// - Parameter models: The paths of the model files, as given on the command line.
    /// - Returns: The paths of the metamodel files, without repetitions, in the order in which
    ///   the models and the files of their directories are listed.
    /// - Throws: ``SwiftAQLError/ambiguousMetamodels(_:_:)`` if several files beside a model
    ///   declare a namespace URI that the model refers to.
    func metamodels(for models: [String]) async throws -> [String] {
        let modelPaths = Set(models.map { URL(fileURLWithPath: $0).standardizedFileURL.path })
        var found: [String] = []
        for model in models {
            let url = URL(fileURLWithPath: model)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let candidates = await metamodelFiles(in: url.deletingLastPathComponent())
                .filter { !modelPaths.contains($0.standardizedFileURL.path) }
            var byNamespace: [String: [String]] = [:]
            var order: [String] = []
            for candidate in candidates {
                for namespace in await namespaces(ofMetamodelAt: candidate)
                where namespace.isReferred(by: text, in: self) {
                    if byNamespace[namespace.uri] == nil { order.append(namespace.uri) }
                    byNamespace[namespace.uri, default: []].append(candidate.path)
                }
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

    /// The files in a directory whose format may hold a metamodel, sorted by name.
    ///
    /// - Parameter directory: The directory.
    /// - Returns: The files whose format may hold a metamodel, such as Ecore, JSON, KM3 or EMOF
    ///   (see `MetamodelRegistration.mayHoldMetamodel(at:registry:)`), or no files if the
    ///   directory cannot be read.
    func metamodelFiles(in directory: URL) async -> [URL] {
        let contents =
            (try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        var files: [URL] = []
        for url in contents where await MetamodelRegistration.mayHoldMetamodel(at: url.path) {
            files.append(url)
        }
        return files.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// A namespace under which a metamodel file registers a root package.
    struct Namespace: Equatable {
        /// The namespace URI, or the name of a package without one.
        let uri: String

        /// Whether the package is registered under its name, as a KM3 package is.
        let isName: Bool

        /// Whether the text of a model refers to the namespace.
        ///
        /// - Parameters:
        ///   - text: The text of a model file.
        ///   - discovery: The discovery whose rules apply.
        /// - Returns: For a namespace URI, whether ``MetamodelDiscovery/refers(_:to:)``; for a
        ///   name, whether ``MetamodelDiscovery/declares(_:namespace:)``.
        func isReferred(by text: String, in discovery: MetamodelDiscovery) -> Bool {
            isName ? discovery.declares(text, namespace: uri) : discovery.refers(text, to: uri)
        }
    }

    /// The namespaces under which a metamodel file registers its root packages.
    ///
    /// An Ecore document and other XML documents declare the first `nsURI` attribute (see
    /// ``namespaceURI(ofMetamodelAt:)``). A JSON metamodel declares the `nsURI` of each root
    /// package. A KM3 document registers each root package under its name. A document in any
    /// other metamodel format, such as EMOF, Emfatic or a grammar, is read, and declares the
    /// namespace URI of each root package, or the name of a package without one.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: The namespaces, or none if the file declares none or cannot be read.
    func namespaces(ofMetamodelAt url: URL) async -> [Namespace] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        switch await MetamodelRegistration.documentHandler(at: url.path)?.format ?? ModelFormat.detect(data: data) {
        case .json?:
            return namespaceURIs(declaredInJSON: data).map { Namespace(uri: $0, isName: false) }
        case .km3?:
            guard let text = try? DecodedText(decoding: data).text else { return [] }
            return KM3Reader.parse(text, sourceName: url.lastPathComponent).packages.compactMap { package in
                if !package.nsURI.isEmpty { return Namespace(uri: package.nsURI, isName: false) }
                return package.name.isEmpty ? nil : Namespace(uri: package.name, isName: true)
            }
        case .xmi?, .ecore?, .uml?, nil:
            return namespaceURI(ofMetamodelAt: url).map { [Namespace(uri: $0, isName: false)] } ?? []
        case let format?:
            return await namespaces(ofPackagesIn: url, format: format)
        }
    }

    /// The namespaces of the root packages of a metamodel document, read in its format.
    ///
    /// The document is read into a resource set of its own, so that nothing is registered for
    /// the run, and its diagnostics are not reported.
    ///
    /// - Parameters:
    ///   - url: The location of the document.
    ///   - format: The format of the document.
    /// - Returns: The namespace URI of each root package, or its name if it has none; none if the
    ///   document cannot be read.
    func namespaces(ofPackagesIn url: URL, format: ModelFormat) async -> [Namespace] {
        guard
            let loaded = try? await ModelIO.load(
                url: url, format: format, resourceSet: ResourceSet(),
                options: ModelIO.LoadOptions(requiresMetamodel: false, ecoreLoadOptions: options))
        else { return [] }
        return loaded.packages.compactMap { package in
            if !package.nsURI.isEmpty { return Namespace(uri: package.nsURI, isName: false) }
            return package.name.isEmpty ? nil : Namespace(uri: package.name, isName: true)
        }
    }

    /// The namespace URIs of the root packages of a JSON metamodel.
    ///
    /// - Parameter data: The JSON document: a package object, or an array of package objects.
    /// - Returns: The non-empty `nsURI` values of the root objects, in order; none for a
    ///   document that is not JSON or whose roots declare none, such as a model.
    func namespaceURIs(declaredInJSON data: Data) -> [String] {
        guard let document = try? JSONSerialization.jsonObject(with: data) else { return [] }
        let roots = (document as? [Any]) ?? [document]
        return roots.compactMap { root in
            guard let value = (root as? [String: Any])?[SwiftAQLVocabulary.Discovery.namespaceURIAttribute] as? String,
                !value.isEmpty
            else { return nil }
            return value
        }
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

    /// Whether the text of a model declares a namespace that is the name of a package.
    ///
    /// A package without a namespace URI, such as one from a KM3 metamodel, is registered under
    /// its name. A name is a common word, so a model refers to it only by a namespace
    /// declaration, such as `xmlns:company="Company"`, or a class reference, such as
    /// `"Company#//Employee"`, and not by any quoted text.
    ///
    /// - Parameters:
    ///   - text: The text of a model file.
    ///   - name: The name of a package.
    /// - Returns: `true` if an `xmlns` attribute has the name as its value, or the name is
    ///   quoted and followed by `#`.
    func declares(_ text: String, namespace name: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let pattern = #"xmlns(:[^\s=]+)?\s*=\s*(["'])"# + escaped + #"\2|["']"# + escaped + "#"
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return false }
        return expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
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
