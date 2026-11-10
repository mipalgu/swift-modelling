//
// MetamodelRegistration.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// Loads the Ecore metamodels named on a command line and registers them with a resource set.
///
/// A parser that has a resource set with registered metamodels builds the objects of a model
/// from the classes of those metamodels, and a serialiser writes the classes of the objects of
/// a resource in the set in the namespaces of their metamodels. The commands of the tools
/// register each Ecore file given on their command line, and each metamodel package they have
/// already loaded, through this helper, so that every command reads and writes models in the
/// same way.
public enum MetamodelRegistration {
    /// The file extension of an Ecore metamodel, without the leading dot.
    public static let ecoreExtension = "ecore"

    /// The text that announces the loading of a metamodel in verbose output.
    public static let defaultAnnouncement = "Loading metamodel"

    /// Reports whether a path names an Ecore metamodel file.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension is ``ecoreExtension``, ignoring case.
    public static func isEcoreFile(_ path: String) -> Bool {
        URL(fileURLWithPath: path).pathExtension.lowercased() == ecoreExtension
    }

    /// Reports whether a path names a file in a format that holds only metamodels.
    ///
    /// The formats are those whose built-in handler has the role `ModelFormatRole.metamodel`,
    /// such as Ecore (`.ecore`) and KM3 (`.km3`). A JSON file may hold a model or a metamodel,
    /// so it is not one of them.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension, ignoring case, is one of such a format.
    public static func isMetamodelFile(_ path: String) -> Bool {
        handler(for: path).map { $0.role == .metamodel } ?? false
    }

    /// Reports whether a path names a file in a format that may hold a metamodel.
    ///
    /// The formats are those whose built-in handler does not have the role
    /// `ModelFormatRole.model`, such as Ecore, KM3 and JSON.
    ///
    /// - Parameter path: The file path to examine.
    /// - Returns: `true` if the file extension, ignoring case, is one of such a format.
    public static func mayHoldMetamodel(_ path: String) -> Bool {
        handler(for: path).map { $0.role != .model } ?? false
    }

    /// The built-in handler of the format that the extension of a path names.
    ///
    /// - Parameter path: The file path.
    /// - Returns: The handler, or `nil` if the extension names no built-in format.
    private static func handler(for path: String) -> (any ModelFormatHandler)? {
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        guard !fileExtension.isEmpty else { return nil }
        return ModelFormatRegistry.builtInHandlers.first { $0.fileExtensions.contains(fileExtension) }
    }

    /// Reports whether a file holds a document in a format that holds only metamodels.
    ///
    /// Unlike ``isMetamodelFile(_:)``, the registry examines the contents of the file as well
    /// as its extension, as `ModelFormatRegistry.handler(for:contents:)` does, so that an EMOF
    /// metamodel in an `.xmi` file counts as a metamodel while an XMI model does not. A file
    /// whose extension names no format counts only if a format that recognises its documents
    /// by a distinctive start, such as KM3, recognises it.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - registry: The registry that provides the format handlers (default
    ///     `ModelFormatRegistry.shared`).
    /// - Returns: `true` if the handler of the document has the role `ModelFormatRole.metamodel`.
    public static func holdsMetamodel(at path: String, registry: ModelFormatRegistry = .shared) async -> Bool {
        await metamodelCandidateHandler(at: path, registry: registry).map { $0.role == .metamodel } ?? false
    }

    /// Reports whether a file holds a document in a format that may hold a metamodel.
    ///
    /// The file is examined as ``holdsMetamodel(at:registry:)`` examines it, and counts if
    /// the handler of the document does not have the role `ModelFormatRole.model`, such as
    /// the handler of Ecore, JSON, KM3 or EMOF.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - registry: The registry that provides the format handlers (default
    ///     `ModelFormatRegistry.shared`).
    /// - Returns: `true` if the document may hold a metamodel.
    public static func mayHoldMetamodel(at path: String, registry: ModelFormatRegistry = .shared) async -> Bool {
        await metamodelCandidateHandler(at: path, registry: registry).map { $0.role != .model } ?? false
    }

    /// The handler that the registry chooses for a file from its extension and contents.
    ///
    /// The start of the file is read and given to `ModelFormatRegistry.handler(for:contents:)`,
    /// so that a format that recognises its documents, such as EMOF or UML, takes precedence
    /// over a generic format that merely claims the extension, such as XMI. A file that cannot
    /// be read is judged by its extension alone.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - registry: The registry that provides the format handlers (default
    ///     `ModelFormatRegistry.shared`).
    /// - Returns: The handler, or `nil` if neither the extension nor the contents name a format.
    public static func documentHandler(
        at path: String, registry: ModelFormatRegistry = .shared
    ) async -> (any ModelFormatHandler)? {
        let url = URL(fileURLWithPath: path)
        guard let prefix = documentPrefix(of: url) else { return await registry.handler(for: url) }
        return await registry.handler(for: url, contents: prefix)
    }

    /// The handler of a file that may name it a metamodel.
    ///
    /// A file whose extension names a format is examined as ``documentHandler(at:registry:)``
    /// examines it. A file whose extension names none is recognised only by a format with a
    /// priority above `ModelFormatPriority.generic`, so that an XML or JSON file with an
    /// unknown extension is still read as a model.
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - registry: The registry that provides the format handlers.
    /// - Returns: The handler, or `nil` if the file is in no format that may name it a metamodel.
    private static func metamodelCandidateHandler(
        at path: String, registry: ModelFormatRegistry
    ) async -> (any ModelFormatHandler)? {
        let url = URL(fileURLWithPath: path)
        if await registry.handler(for: url) != nil { return await documentHandler(at: path, registry: registry) }
        guard let prefix = documentPrefix(of: url), let recognised = await registry.handler(recognising: prefix),
            recognised.priority > .generic
        else { return nil }
        return recognised
    }

    /// The start of a file, as much as the registry examines to recognise a format.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: The first bytes of the file, or `nil` if it cannot be read.
    private static func documentPrefix(of url: URL) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        return try? handle.read(upToCount: ModelFormatRegistry.recognitionPrefixLength) ?? Data()
    }

    /// Names formats in prose, for messages that list the formats of the registry.
    ///
    /// Each format is named by its file extension, followed by its prose name in parentheses
    /// where the two differ in more than case, such as `emf (Emfatic)`.
    ///
    /// - Parameter formats: The formats, in the order in which they are listed.
    /// - Returns: The names, separated by commas, such as `ecore, json, km3, emf (Emfatic)`.
    public static func formatList(_ formats: [ModelFormat]) -> String {
        formats.map { format in
            format.description.lowercased() == format.rawValue ? format.rawValue : "\(format.rawValue) (\(format.description))"
        }.joined(separator: ", ")
    }

    /// The formats whose built-in handlers can write documents and whose role suits a document.
    ///
    /// - Parameters:
    ///   - preferred: The formats that come first, in order, if they qualify.
    ///   - accepts: Whether the role of a handler qualifies its format.
    /// - Returns: The preferred formats, followed by the other qualifying formats in the order
    ///   of the registry.
    public static func writableFormats(
        preferring preferred: [ModelFormat], where accepts: (ModelFormatRole) -> Bool
    ) -> [ModelFormat] {
        let qualifying = ModelFormatRegistry.builtInHandlers
            .filter { $0 is any WritableModelFormatHandler && accepts($0.role) }
            .compactMap(\.format)
        return preferred.filter(qualifying.contains) + qualifying.filter { !preferred.contains($0) }
    }

    /// Reports whether the built-in handler of a format can write documents.
    ///
    /// - Parameter format: The format.
    /// - Returns: `false` for a format that is only read, such as Langium, Xtext or SDF3.
    public static func isWritable(_ format: ModelFormat) -> Bool {
        ModelFormatRegistry.builtInHandlers.contains { $0.format == format && $0 is any WritableModelFormatHandler }
    }

    /// The line that reports a registered metamodel in verbose output.
    ///
    /// - Parameters:
    ///   - package: The root package of the registered metamodel.
    ///   - uri: The URI under which the package is registered, or `nil` for its namespace URI.
    /// - Returns: The line, naming the package and the URI.
    public static func registeredMessage(for package: EPackage, uri: String? = nil) -> String {
        "  ✓ Registered metamodel '\(package.name)' with URI: \(uri ?? package.nsURI)"
    }

    /// Loads every root package of a metamodel file.
    ///
    /// The file is read as `ModelIO.registerMetamodels(at:in:options:registry:)` reads it,
    /// in the metamodel format that its extension or its contents name: an Ecore document, a
    /// JSON metamodel or a KM3 document, for example. The root packages are loaded together,
    /// so that references between them and to files next to the metamodel resolve, but they
    /// are registered with no resource set. A root package without a namespace URI or prefix
    /// loads with an empty one, as in EMF. The diagnostics of reading the file, such as such a
    /// package, a file read as ISO-8859-1 or a syntax error of KM3, are written to standard
    /// error with ``FileDiagnosticReport`` and do not make the load fail.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - options: The options with which the file is read (default options).
    ///   - debug: Whether the parser prints its trace of an Ecore document to standard output.
    /// - Returns: The root packages, in document order.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded or has no root package.
    public static func loadPackages(
        at path: String, options: EcoreLoadOptions = EcoreLoadOptions(), debug: Bool = false
    ) async throws -> [EPackage] {
        let loaded = try await load(at: path, options: options, debug: debug)
        FileDiagnosticReport.write(loaded.diagnostics, file: path)
        guard !loaded.packages.isEmpty else { throw XMIError.noRootObject }
        return loaded.packages
    }

    /// Loads every root package of a metamodel file with the URIs under which it registers them.
    ///
    /// The diagnostics of reading the file are returned for the caller to report.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - options: The options with which the file is read.
    ///   - debug: Whether the parser prints its trace of an Ecore document to standard output.
    /// - Returns: The root packages in document order, which are none if the file has none; the
    ///   URI under which each package that is registered is registered: its namespace URI or,
    ///   for a package without one in a format such as KM3, its name; the resource that holds
    ///   the packages; and the diagnostics of reading the file.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist,
    ///   ``SourceFileError/malformed(path:encoding:)`` if a document in a text format is not
    ///   valid in the `textEncoding` of the options, or the error of the reader if the file
    ///   cannot be loaded.
    private static func load(
        at path: String, options: EcoreLoadOptions, debug: Bool
    ) async throws -> LoadedMetamodel {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetamodelRegistrationError.fileNotFound(path)
        }
        let url = URL(fileURLWithPath: path)
        let resourceSet = ResourceSet()
        if debug, await readsAsEcore(url) {
            _ = try await ModelIO.load(
                url: url, format: .ecore, resourceSet: resourceSet,
                options: ModelIO.LoadOptions(ecoreLoadOptions: options, enableDebugging: true))
        }
        let packages: [EPackage]
        do {
            packages = try await ModelIO.registerMetamodels(at: [url], in: resourceSet, options: options)
        } catch TextDecodingError.malformed(let encoding) {
            throw SourceFileError.malformed(path: path, encoding: encoding)
        }
        let uri = URIReference.canonicalise(url.absoluteString)
        let resource = await resourceSet.getResource(uri: uri)
        let diagnostics = await resource?.loadDiagnostics ?? []
        let identifiers = Set(packages.map(\.id))
        var registrations: [(uri: String, package: EPackage)] = []
        for registered in await resourceSet.getMetamodelURIs().sorted() {
            guard let package = await resourceSet.getMetamodel(uri: registered), identifiers.contains(package.id) else {
                continue
            }
            registrations.append((registered, package))
        }
        let order = Dictionary(packages.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        registrations.sort { (order[$0.package.id] ?? 0, $0.uri) < (order[$1.package.id] ?? 0, $1.uri) }
        return LoadedMetamodel(
            packages: packages, registrations: registrations, resource: resource, resourceSet: resourceSet,
            diagnostics: diagnostics)
    }

    /// A metamodel file as ``load(at:options:debug:)`` loads it.
    private struct LoadedMetamodel {
        /// The root packages, in document order.
        let packages: [EPackage]

        /// The URI under which each package is registered, with the package.
        let registrations: [(uri: String, package: EPackage)]

        /// The resource that holds the packages, if the reader kept one.
        let resource: Resource?

        /// The resource set that read the file and holds the resource.
        let resourceSet: ResourceSet

        /// The diagnostics of reading the file, in the order in which they were reported.
        let diagnostics: [SourceDiagnostic]
    }

    /// Whether a metamodel file is read as an Ecore document, whose reader can print a trace.
    ///
    /// The registry chooses the format from the extension and the contents of the file (see
    /// ``documentHandler(at:registry:)``), so an EMOF metamodel in an `.xmi` file is not read
    /// as an Ecore document.
    ///
    /// - Parameter url: The location of the file.
    /// - Returns: `true` unless the extension or the contents of the file name another
    ///   metamodel format, such as KM3 or EMOF, or a model format whose documents are converted
    ///   into metamodels, such as UML.
    private static func readsAsEcore(_ url: URL) async -> Bool {
        guard let handler = await documentHandler(at: url.path) else { return true }
        if handler is any MetamodelConvertingModelFormatHandler { return false }
        guard handler.role != .model else { return true }
        switch handler.format {
        case .xmi?, .json?, .ecore?: return true
        default: return false
        }
    }

    /// Loads a metamodel and registers it with a resource set.
    ///
    /// Every root package of the file is registered, as
    /// ``registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)``
    /// registers them, and the first is returned.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of the metamodel document to standard output.
    ///   - options: The options with which the file is read (default options).
    /// - Returns: The first root package of the file.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded.
    @MainActor
    @discardableResult
    public static func registerMetamodel(
        at path: String,
        into resourceSet: ResourceSet,
        announcement: String = defaultAnnouncement,
        verbose: Bool = false,
        debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> EPackage {
        let packages = try await registerMetamodels(
            at: path, into: resourceSet, announcement: announcement, verbose: verbose, debug: debug, options: options)
        guard let first = packages.first else { throw XMIError.noRootObject }
        return first
    }

    /// Loads a metamodel and registers each of its root packages with a resource set.
    ///
    /// The file may be in any metamodel format, such as Ecore, JSON or KM3 (see
    /// ``loadPackages(at:options:debug:)``). Each root package with a namespace URI is
    /// registered under it, so parsers that use the resource set find its classes, and
    /// resources of the set are written with its namespace. A root package without a namespace
    /// URI is loaded with the others, so that their references to it resolve. It is not
    /// registered if it comes from an Ecore or JSON document; one from a format without
    /// namespaces, such as KM3, is registered under its name, as the ATL tool chain does. A
    /// warning reports either. The diagnostics of reading the file, such as these warnings,
    /// are written with ``FileDiagnosticReport`` through `diagnosticOutput`, which writes them to
    /// standard error unless the caller supplies another writer.
    ///
    /// Verbose output names the file and each registered package. The trace of the XMI parser
    /// is a separate debugging aid that only `debug` turns on.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of the metamodel document to standard output.
    ///   - options: The options with which the file is read (default options).
    ///   - diagnosticOutput: The writer that receives the report of the diagnostics of reading
    ///     the file, if there are any (standard error by default).
    /// - Returns: The root packages of the file, in document order.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if the file does not exist, or
    ///   the error of the reader if the file cannot be loaded.
    @MainActor
    @discardableResult
    public static func registerMetamodels(
        at path: String,
        into resourceSet: ResourceSet,
        announcement: String = defaultAnnouncement,
        verbose: Bool = false,
        debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions(),
        diagnosticOutput: (String) -> Void = FileDiagnosticReport.writeToStandardError
    ) async throws -> [EPackage] {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetamodelRegistrationError.fileNotFound(path)
        }
        return try await register(
            at: path, into: resourceSet, announcement: announcement, verbose: verbose, debug: debug, options: options,
            diagnosticOutput: diagnosticOutput
        ).packages
    }

    /// Loads a metamodel and registers each of its root packages with a resource set.
    ///
    /// - Parameters:
    ///   - path: The path to the metamodel file, which exists.
    ///   - resourceSet: The resource set in which to register the metamodel.
    ///   - announcement: The text that introduces the path in verbose output.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of the metamodel document to standard output.
    ///   - options: The options with which the file is read.
    ///   - diagnosticOutput: The writer that receives the report of the diagnostics of reading
    ///     the file, if there are any.
    /// - Returns: The loaded metamodel.
    /// - Throws: The error of the reader if the file cannot be loaded or has no root package.
    @MainActor
    private static func register(
        at path: String, into resourceSet: ResourceSet, announcement: String, verbose: Bool, debug: Bool,
        options: EcoreLoadOptions, diagnosticOutput: (String) -> Void
    ) async throws -> LoadedMetamodel {
        if verbose {
            print("\(announcement): \(path)")
        }
        let loaded = try await load(at: path, options: options, debug: debug)
        FileDiagnosticReport.write(loaded.diagnostics, file: path, to: diagnosticOutput)
        guard !loaded.packages.isEmpty else { throw XMIError.noRootObject }
        for (uri, package) in loaded.registrations {
            await resourceSet.registerMetamodel(package, uri: uri)
            if verbose {
                print(registeredMessage(for: package, uri: uri))
            }
        }
        return loaded
    }

    /// Loads Ecore metamodels and registers them with a new resource set.
    ///
    /// Every root package of each file is registered, as
    /// ``registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)``
    /// registers them.
    ///
    /// - Parameters:
    ///   - paths: The paths to the `.ecore` files, in command line order.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of each metamodel document to standard output.
    ///   - options: The options with which the files are read (default options).
    /// - Returns: The resource set with every metamodel registered.
    /// - Throws: The error of
    ///   ``registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)``
    ///   for the first file that cannot be registered.
    @MainActor
    public static func resourceSet(
        registering paths: [String], verbose: Bool = false, debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> ResourceSet {
        try await resourceSet(
            registering: paths, applying: [], verbose: verbose, debug: debug, options: options)
    }

    /// Loads metamodels, registers them with a new resource set and constrains them with
    /// Complete OCL documents.
    ///
    /// Every root package of each file is registered, as
    /// ``registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)``
    /// registers them. Then each Complete OCL document is applied, in order, to the metamodels
    /// together, as ``applyCompleteOCL(_:to:in:verbose:diagnosticOutput:)`` describes, so that
    /// the registered packages carry the constraints of the documents.
    ///
    /// - Parameters:
    ///   - paths: The paths to the metamodel files, in command line order.
    ///   - documents: The paths to the Complete OCL documents (`.ocl`), in command line order.
    ///   - verbose: Whether to print progress to standard output.
    ///   - debug: Whether the parser prints its trace of each metamodel document to standard output.
    ///   - options: The options with which the files are read (default options).
    /// - Returns: The resource set with every metamodel registered.
    /// - Throws: The error of
    ///   ``registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)``
    ///   for the first file that cannot be registered, and the errors of
    ///   ``applyCompleteOCL(_:to:in:verbose:diagnosticOutput:)``.
    @MainActor
    public static func resourceSet(
        registering paths: [String], applying documents: [String], verbose: Bool = false, debug: Bool = false,
        options: EcoreLoadOptions = EcoreLoadOptions()
    ) async throws -> ResourceSet {
        let resourceSet = ResourceSet()
        var loaded: [LoadedMetamodel] = []
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else {
                throw MetamodelRegistrationError.fileNotFound(path)
            }
            loaded.append(
                try await register(
                    at: path, into: resourceSet, announcement: defaultAnnouncement, verbose: verbose, debug: debug,
                    options: options, diagnosticOutput: FileDiagnosticReport.writeToStandardError))
        }
        if !documents.isEmpty {
            try await applyCompleteOCL(
                documents, to: loaded.compactMap(\.resource), in: resourceSet, verbose: verbose,
                encoding: options.textEncoding)
        }
        withExtendedLifetime(loaded) {}
        return resourceSet
    }

    /// Constrains loaded metamodels with Complete OCL documents.
    ///
    /// Each document is applied in turn, as `ModelIO.applyCompleteOCL(at:to:in:options:)`
    /// applies it: its invariants, pre- and postconditions, definitions and derivations are
    /// added to the classes and features of the metamodels as OCL annotations, the constrained
    /// packages replace the root packages of the resources, and every registration of a
    /// replaced package with the resource set refers to the constrained package instead. What
    /// a document cannot express or apply, such as a context that no metamodel declares, is
    /// written with ``FileDiagnosticReport`` through `diagnosticOutput`, which writes it to
    /// standard error unless the caller supplies another writer, and does not make the command
    /// fail.
    ///
    /// - Parameters:
    ///   - documents: The paths to the Complete OCL documents, in the order in which they apply.
    ///   - resources: The resources of the metamodels, in the order in which contexts are looked up.
    ///   - resourceSet: The resource set with which the metamodels are registered.
    ///   - verbose: Whether to report each document and the number of constraints it added.
    ///   - encoding: The character encoding of the documents, or `nil` (the default) to read
    ///     UTF-8 with a fallback to ISO-8859-1.
    ///   - diagnosticOutput: The writer that receives the report of the diagnostics of applying
    ///     each document, if there are any (standard error by default).
    /// - Returns: The constrained root packages after the last document, in the order of the
    ///   resources.
    /// - Throws: ``MetamodelRegistrationError/fileNotFound(_:)`` if a document does not exist,
    ///   ``MetamodelRegistrationError/nothingToConstrain(_:)`` if there is no metamodel, and the
    ///   errors of `ModelIO.applyCompleteOCL(at:to:in:options:)`.
    @discardableResult
    public static func applyCompleteOCL(
        _ documents: [String], to resources: [Resource], in resourceSet: ResourceSet, verbose: Bool = false,
        encoding: TextEncoding? = nil,
        diagnosticOutput: (String) -> Void = FileDiagnosticReport.writeToStandardError
    ) async throws -> [EPackage] {
        var packages: [EPackage] = []
        for path in documents {
            guard FileManager.default.fileExists(atPath: path) else {
                throw MetamodelRegistrationError.fileNotFound(path)
            }
            guard !resources.isEmpty else { throw MetamodelRegistrationError.nothingToConstrain(path) }
            let applied: CompleteOCLApplication
            do {
                applied = try await ModelIO.applyCompleteOCL(
                    at: URL(fileURLWithPath: path), to: resources, in: resourceSet,
                    options: ModelIO.LoadOptions(textEncoding: encoding))
            } catch TextDecodingError.malformed(let malformed) {
                throw SourceFileError.malformed(path: path, encoding: malformed)
            }
            FileDiagnosticReport.write(applied.diagnostics, file: path, to: diagnosticOutput)
            if verbose {
                print(appliedMessage(count: applied.appliedCount, document: path))
            }
            packages = applied.packages
        }
        return packages
    }

    /// The line that reports an applied Complete OCL document in verbose output.
    ///
    /// - Parameters:
    ///   - count: The number of specifications that the document added.
    ///   - document: The path of the document.
    /// - Returns: The line, naming the document and the number.
    public static func appliedMessage(count: Int, document: String) -> String {
        "  ✓ Applied \(count) Complete OCL specification(s) from \(document)"
    }

    /// Registers loaded metamodel packages with a resource set.
    ///
    /// Each package is registered under its namespace URI; a later package with the same URI
    /// replaces an earlier one.
    ///
    /// - Parameters:
    ///   - packages: The root packages of the metamodels.
    ///   - resourceSet: The resource set in which to register them.
    public static func register(_ packages: some Sequence<EPackage>, into resourceSet: ResourceSet) async {
        for package in packages {
            await resourceSet.registerMetamodel(package, uri: package.nsURI)
        }
    }
}

/// An error that occurs while registering a metamodel named on the command line.
public enum MetamodelRegistrationError: Error, Equatable, CustomStringConvertible, LocalizedError {
    /// The metamodel file does not exist.
    ///
    /// The associated value is the path as given on the command line.
    case fileNotFound(String)

    /// A Complete OCL document was given, but no metamodel to constrain.
    ///
    /// The associated value is the path of the document as given on the command line.
    case nothingToConstrain(String)

    /// A description of the error, naming the path concerned.
    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .nothingToConstrain(let path):
            return "No metamodel to constrain with \(path): give the metamodel with --\(MetamodelOptions.optionName)"
        }
    }

    /// The localised description of the error, which is its ``description``.
    public var errorDescription: String? { description }
}
