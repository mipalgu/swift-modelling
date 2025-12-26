//
// CodeGenerator.swift
// swift-modelling
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// An actor responsible for generating production-quality source code from Ecore metamodels.
///
/// The `CodeGenerator` processes Ecore resources and translates them into target programming
/// languages such as Swift or C++. It handles complex EMF features including inheritance,
/// bidirectional references, enumerations, and reflective access.
///
/// For Swift generation, the actor follows a one-file-per-class pattern, organises output
/// into package-based directory structures, and includes comprehensive DocC documentation.
actor CodeGenerator {
    /// The target language for code generation (e.g., "swift", "cpp").
    let language: String

    /// The base output directory where generated files and directories will be created.
    let outputDirectory: URL

    /// Internal cache to ensure each `EClass` is only processed and resolved once.
    private var classCache: [UUID: EClass] = [:]

    /// Internal cache to ensure each `EEnum` is only processed and resolved once.
    private var enumCache: [UUID: EEnum] = [:]

    /// Initialise a new code generator for the specified language and output path.
    ///
    /// - Parameters:
    ///   - language: The target programming language (must be "swift", "cpp", "c", or "llvm").
    ///   - outputDirectory: The URL of the directory where code will be generated.
    /// - Throws: `GenerationError.unsupportedLanguage` if the specified language is not supported.
    init(language: String, outputDirectory: URL) throws {
        guard ["swift", "cpp", "c", "llvm"].contains(language) else {
            throw GenerationError.unsupportedLanguage(language)
        }
        self.language = language
        self.outputDirectory = outputDirectory
    }

    /// Generate source code from the provided Ecore resource.
    ///
    /// This is the primary entry point for the generation process. It identifies the root
    /// objects in the resource and delegates to language-specific generation methods.
    ///
    /// - Parameters:
    ///   - resource: The Ecore resource containing the metamodel to generate code for.
    ///   - verbose: Whether to output detailed progress information to the console.
    /// - Throws: `GenerationError` or file I/O errors if the generation process fails.
    func generate(from resource: Resource, verbose: Bool) async throws {
        if language == "swift" {
            try await generateSwift(from: resource, verbose: verbose)
        } else if language == "cpp" {
            try await generateCpp(from: resource, verbose: verbose)
        }
    }

    // MARK: - Swift Generation

    /// Orchestrate the generation of Swift source code.
    ///
    /// This method performs a two-pass analysis: first building a reference map for
    /// bidirectional relationships, and then generating files for each package and class.
    ///
    /// - Parameters:
    ///   - resource: The resource to generate Swift code from.
    ///   - verbose: Whether to print progress details.
    private func generateSwift(from resource: Resource, verbose: Bool) async throws {
        if verbose { print("Analysing model for Swift generation...") }
        let objects = await resource.getRootObjects()
        classCache.removeAll()
        enumCache.removeAll()

        let referenceMap = await buildReferenceMap(from: objects, in: resource)

        if verbose { print("Generating Swift files in: \(outputDirectory.path)") }

        for obj in objects {
            if let pkg = await resolvePackage(obj, in: resource) {
                try await generateSwiftPackageFiles(from: pkg, in: resource, referenceMap: referenceMap, verbose: verbose)
            } else if let cls = await resolveClass(obj, in: resource) {
                let content = generateSwiftFileHeader() + (await generateSwiftClass(from: cls, in: resource, referenceMap: referenceMap))
                try writeGeneratedFile(named: "\(cls.name).swift", content: content)
            } else if let enm = await resolveEnum(obj, in: resource) {
                let content = generateSwiftFileHeader() + generateSwiftEnum(from: enm)
                try writeGeneratedFile(named: "\(enm.name).swift", content: content)
            }
        }
    }

    /// Generate all files associated with a specific Ecore package.
    ///
    /// Create a directory for the package and generates individual files for each
    /// classifier, the package descriptor, and the factory.
    ///
    /// - Parameters:
    ///   - pkg: The resolved `EPackage` instance.
    ///   - resource: The source resource.
    ///   - referenceMap: A map of identifiers to references for cross-linking.
    ///   - verbose: Whether to print progress details.
    private func generateSwiftPackageFiles(from pkg: EPackage, in resource: Resource, referenceMap: [UUID: EReference], verbose: Bool) async throws {
        let pkgDir = outputDirectory.appendingPathComponent(pkg.name)
        try FileManager.default.createDirectory(at: pkgDir, withIntermediateDirectories: true)

        if verbose { print("  Processing package: \(pkg.name)") }

        for classifier in pkg.eClassifiers {
            if let cls = classifier as? EClass {
                let content = generateSwiftFileHeader() + (await generateSwiftClass(from: cls, in: resource, referenceMap: referenceMap))
                try writeGeneratedFile(named: "\(cls.name).swift", content: content, in: pkgDir)
            } else if let enm = classifier as? EEnum {
                let content = generateSwiftFileHeader() + generateSwiftEnum(from: enm)
                try writeGeneratedFile(named: "\(enm.name).swift", content: content, in: pkgDir)
            } else if let o = classifier as? any EObject {
                if let rc = await resolveClass(o, in: resource) {
                    let content = generateSwiftFileHeader() + (await generateSwiftClass(from: rc, in: resource, referenceMap: referenceMap))
                    try writeGeneratedFile(named: "\(rc.name).swift", content: content, in: pkgDir)
                } else if let re = await resolveEnum(o, in: resource) {
                    let content = generateSwiftFileHeader() + generateSwiftEnum(from: re)
                    try writeGeneratedFile(named: "\(re.name).swift", content: content, in: pkgDir)
                }
            }
        }

        // Generate Factory
        let factoryContent = generateSwiftFileHeader() + generateSwiftFactory(from: pkg)
        try writeGeneratedFile(named: "\(pkg.name.capitalized)Factory.swift", content: factoryContent, in: pkgDir)

        // Generate Package Descriptor
        let packageDescContent = generateSwiftFileHeader() + generateSwiftPackageDescriptor(from: pkg)
        try writeGeneratedFile(named: "\(pkg.name.capitalized)Package.swift", content: packageDescContent, in: pkgDir)
    }

    /// Write generated content to a file.
    ///
    /// - Parameters:
    ///   - name: The name of the file to create.
    ///   - content: The string content to write.
    ///   - directory: The URL of the directory to write into.
    private func writeGeneratedFile(named name: String, content: String, in directory: URL? = nil) throws {
        let targetDir = directory ?? outputDirectory
        let fileURL = targetDir.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate a standard header for Swift files.
    ///
    /// - Returns: A string containing the file header.
    private func generateSwiftFileHeader() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: Date())

        return """
        //
        //  Generated by Swift Ecore on \(dateString).
        //  This file was automatically generated and should not be edited manually.
        //
        import Foundation
        import ECore

        """
    }

    /// Build a map of all structural references in the model to facilitate bidirectional linking.
    ///
    /// - Parameters:
    ///   - objects: The root objects to scan.
    ///   - resource: The resource containing the objects.
    /// - Returns: A dictionary mapping reference IDs to reference instances.
    private func buildReferenceMap(from objects: [any EObject], in resource: Resource) async -> [UUID: EReference] {
        var map: [UUID: EReference] = [:]
        for obj in objects {
            if let cls = await resolveClass(obj, in: resource) {
                for f in cls.eStructuralFeatures { if let r = f as? EReference { map[r.id] = r } }
            } else if let pkg = await resolvePackage(obj, in: resource) {
                for c in pkg.eClassifiers {
                    if let cO = c as? any EObject, let cC = await resolveClass(cO, in: resource) {
                        for f in cC.eStructuralFeatures { if let r = f as? EReference { map[r.id] = r } }
                    }
                }
            }
        }
        return map
    }

    /// Resolve an object to its concrete `EPackage` representation.
    ///
    /// - Parameters:
    ///   - obj: The object to resolve.
    ///   - resource: The resource context.
    /// - Returns: A resolved `EPackage` or nil.
    private func resolvePackage(_ obj: any EObject, in resource: Resource) async -> EPackage? {
        if let p = obj as? EPackage { return p }
        guard let d = obj as? DynamicEObject, d.eClass.name == EcoreClassifier.ePackage.rawValue || d.eClass.name == EcoreDataType.eResource.rawValue else { return nil }
        var pkg = EPackage(id: d.id, name: d.eGet("name") as? String ?? "Unknown")
        if let ids = d.eGet(XMIElement.eClassifiers.rawValue) as? [UUID] {
            for id in ids { if let child = await resource.getObject(id), let c = await resolveClassifier(child, in: resource) { pkg.eClassifiers.append(c) } }
        }
        return pkg
    }

    /// Resolve an object to its concrete `EEnum` representation.
    ///
    /// - Parameters:
    ///   - obj: The object to resolve.
    ///   - resource: The resource context.
    /// - Returns: A resolved `EEnum` or nil.
    private func resolveEnum(_ obj: any EObject, in resource: Resource) async -> EEnum? {
        if let e = obj as? EEnum { return e }
        if let cached = enumCache[obj.id] { return cached }
        guard let d = obj as? DynamicEObject, d.eClass.name == EcoreClassifier.eEnum.rawValue else { return nil }
        let name = d.eGet(XMIAttribute.name.rawValue) as? String ?? "Unknown"
        var lits: [EEnumLiteral] = []
        if let lIds = d.eGet(XMIElement.eLiterals.rawValue) as? [UUID] ?? d.eGet(XMIElement.eClassifiers.rawValue) as? [UUID] {
            for (index, id) in lIds.enumerated() {
                if let lObj = await resource.getObject(id), let dL = lObj as? DynamicEObject {
                    let lName = dL.eGet(XMIAttribute.name.rawValue) as? String ?? "unknown"
                    var lVal = dL.eGet(XMIAttribute.value.rawValue) as? Int ?? 0
                    if lVal == 0 && index > 0 { lVal = index }
                    lits.append(EEnumLiteral(id: dL.id, name: lName, value: lVal))
                }
            }
        }
        let enm = EEnum(id: d.id, name: name, literals: lits)
        enumCache[d.id] = enm
        return enm
    }

    /// Resolve an object to its concrete `EClass` representation, recursively resolving supertypes and features.
    ///
    /// - Parameters:
    ///   - obj: The object to resolve.
    ///   - resource: The resource context.
    /// - Returns: A resolved `EClass` or nil.
    private func resolveClass(_ obj: any EObject, in resource: Resource) async -> EClass? {
        if let c = obj as? EClass { return c }
        if let cached = classCache[obj.id] { return cached }
        guard let d = obj as? DynamicEObject, d.eClass.name == EcoreClassifier.eClass.rawValue else { return nil }
        var cls = EClass(id: d.id, name: d.eGet(XMIAttribute.name.rawValue) as? String ?? "Unknown", isAbstract: d.eGet(XMIAttribute.abstract.rawValue) as? Bool ?? false, isInterface: d.eGet(XMIAttribute.interface.rawValue) as? Bool ?? false)
        classCache[d.id] = cls
        if let ids = d.eGet(XMIElement.eStructuralFeatures.rawValue) as? [UUID] {
            for id in ids {
                if let child = await resource.getObject(id), let dC = child as? DynamicEObject {
                    let n = dC.eGet(XMIAttribute.name.rawValue) as? String ?? "unknown", l = dC.eGet(XMIAttribute.lowerBound.rawValue) as? Int ?? 0, u = dC.eGet(XMIAttribute.upperBound.rawValue) as? Int ?? 1
                    let typeName = await resolveTypeName(dC.eGet(XMIAttribute.eType.rawValue), in: resource)
                    if dC.eClass.name == EcoreClassifier.eAttribute.rawValue {
                        cls.eStructuralFeatures.append(EAttribute(id: dC.id, name: n, eType: EDataType(name: typeName), lowerBound: l, upperBound: u, defaultValueLiteral: dC.eGet(XMIAttribute.defaultValueLiteral.rawValue) as? String))
                    } else if dC.eClass.name == EcoreClassifier.eReference.rawValue {
                        var r = EReference(id: dC.id, name: n, eType: EClass(name: typeName), lowerBound: l, upperBound: u, containment: dC.eGet(XMIAttribute.containment.rawValue) as? Bool ?? false)
                        if let oId = (dC.eGet(XMIAttribute.eOpposite.rawValue) as? UUID) ?? (dC.eGet(XMIAttribute.opposite.rawValue) as? UUID) { r.opposite = oId }
                        cls.eStructuralFeatures.append(r)
                    }
                }
            }
        }
        let sIds = (d.eGet(XMIElement.eSuperTypes.rawValue) as? [UUID]) ?? (d.eGet(XMIElement.eSuperTypes.rawValue) as? UUID).map({ [$0] }) ?? []
        for id in sIds { if let sO = await resource.getObject(id), let sC = await resolveClass(sO, in: resource) { cls.eSuperTypes.append(sC) } }
        classCache[d.id] = cls
        return cls
    }

    /// Resolve the name of a type from a reference identifier.
    ///
    /// - Parameters:
    ///   - typeObj: The identifier of the type object.
    ///   - resource: The resource context.
    /// - Returns: The resolved name of the type.
    private func resolveTypeName(_ typeObj: Any?, in resource: Resource) async -> String {
        if let id = typeObj as? UUID {
            if let obj = await resource.getObject(id) {
                if let d = obj as? DynamicEObject { return d.eGet(XMIAttribute.name.rawValue) as? String ?? "EObject" }
                if let n = obj as? any ENamedElement { return n.name }
            }
        }
        return "EObject"
    }

    /// Resolve an object to its most specific concrete classifier representation.
    ///
    /// - Parameters:
    ///   - obj: The object to resolve.
    ///   - resource: The resource context.
    /// - Returns: A resolved `EClassifier` or nil.
    private func resolveClassifier(_ obj: any EObject, in resource: Resource) async -> (any EClassifier)? {
        if let c = obj as? any EClassifier { return c }
        if let e = await resolveEnum(obj, in: resource) { return e }
        return await resolveClass(obj, in: resource)
    }

    /// Generate code for a Swift enum from an `EEnum`.
    ///
    /// - Parameter enm: The enumeration metamodel element.
    /// - Returns: The generated Swift source code for the enum.
    private func generateSwiftEnum(from enm: EEnum) -> String {
        let summary = "The \(enm.name) enumeration."
        let description = "This enumeration represents the \(enm.name) type defined in the metamodel."

        var res = "\n/// \(summary)\n///\n/// \(description)"
        res += "\nenum \(enm.name): Int, Sendable, Codable, CaseIterable {"
        for l in enm.literals {
            res += "\n    /// The \(l.name) literal value."
            res += "\n    case \(l.name) = \(l.value)"
        }
        res += "\n}\n"
        return res
    }

    /// Generate code for a Swift class or protocol from an `EClass`.
    ///
    /// - Parameters:
    ///   - cls: The class metamodel element.
    ///   - resource: The source resource.
    ///   - referenceMap: The reference map for bidirectional resolution.
    /// - Returns: The generated Swift source code for the class or protocol.
    private func generateSwiftClass(from cls: EClass, in resource: Resource, referenceMap: [UUID: EReference]) async -> String {
        let isInterface = cls.isAbstract || cls.isInterface
        let kw = isInterface ? "protocol" : "class"

        let summary = "The \(cls.name) \(kw)."
        let description = "An implementation of the \(cls.name) type from the Ecore metamodel."

        var res = ""
        let modelDoc = extractDocumentationFromAnnotations(cls.eAnnotations)
        if !modelDoc.isEmpty {
            res += modelDoc
        } else {
            res += "\n/// \(summary)\n///\n/// \(description)"
        }

        if isInterface {
            res += "protocol \(cls.name): EObject {"
            for f in cls.eStructuralFeatures {
                let featureDoc = generateFeatureDocumentation(for: f)
                res += "\n    \(featureDoc)"
                if let a = f as? EAttribute { res += "\n    var \(a.name): \(swiftPropertyType(for: a)) { get set }" }
                else if let r = f as? EReference { res += "\n    var \(r.name): \(swiftPropertyType(for: r)) { get set }" }
            }
        } else {
            var parents = ["EObject", "Hashable"]
            if let first = cls.eSuperTypes.first(where: { !$0.isAbstract && !$0.isInterface }) { parents[0] = first.name }
            for s in cls.eSuperTypes.filter({ $0.isAbstract || $0.isInterface }) { parents.append(s.name) }

            res += "class \(cls.name): \(parents.joined(separator: ", ")) {"
            if !cls.eSuperTypes.contains(where: { !$0.isAbstract && !$0.isInterface }) {
                res += "\n    /// The unique identifier for this object instance."
                res += "\n    let id: UUID = UUID()"
                res += "\n    /// The Ecore metaclass describing this object's structure."
                res += "\n    let eClass: EClass"
            }

            var inherited = Set<String>()
            for s in cls.eSuperTypes { for f in s.eStructuralFeatures { inherited.insert(f.name) } }
            for f in cls.eStructuralFeatures.filter({ !inherited.contains($0.name) }) {
                let featureDoc = generateFeatureDocumentation(for: f)
                res += "\n    \(featureDoc)"
                if let a = f as? EAttribute { res += "\n    \(generateSwiftProperty(for: a))" }
                else if let r = f as? EReference { res += "\n    \(generateSwiftProperty(for: r, referenceMap: referenceMap))" }
            }

            res += "\n\n    /// Initialise a new \(cls.name) with the specified metaclass.\n    ///\n    /// - Parameter eClass: The Ecore metaclass for this object."
            res += "\n    init(eClass: EClass) {"
            if cls.eSuperTypes.contains(where: { !$0.isAbstract && !$0.isInterface }) { res += "\n        super.init(eClass: eClass)" }
            else { res += "\n        self.eClass = eClass" }
            res += "\n    }"

            res += "\n\n    /// Compare two \(cls.name) instances for equality based on their unique identifiers.\n    ///\n    /// - Parameters:\n    ///   - lhs: The first instance to compare.\n    ///   - rhs: The second instance to compare.\n    /// - Returns: True if the identifiers match."
            res += "\n    static func == (lhs: \(cls.name), rhs: \(cls.name)) -> Bool { lhs.id == rhs.id }"
            res += "\n    /// Hash the essential components of this instance into the provided hasher.\n    ///\n    /// - Parameter hasher: The hasher to use for combining identity."
            res += "\n    func hash(into hasher: inout Hasher) { hasher.combine(id) }"

            res += "\n    /// Reflectively retrieve the value of a structural feature.\n    ///\n    /// - Parameter feature: The structural feature to retrieve.\n    /// - Returns: The feature's current value, or nil if not set."
            res += "\n    func eGet(_ feature: some EStructuralFeature) -> (any EcoreValue)? {"
            res += "\n        switch feature.name {"
            for f in cls.allStructuralFeatures { res += "\n        case \"\(f.name)\": return \(f.name)" }
            res += "\n        default: return nil"
            res += "\n        }\n    }"

            res += "\n\n    /// Reflectively set the value of a structural feature.\n    ///\n    /// - Parameters:\n    ///   - feature: The structural feature to modify.\n    ///   - value: The new value to set, or nil to unset."
            res += "\n    func eSet(_ feature: some EStructuralFeature, value: (any EcoreValue)?) {"
            res += "\n        switch feature.name {"
            for f in cls.allStructuralFeatures {
                let type = swiftBaseType(for: f)
                let isMulti = isMultiValued(f)
                res += "\n        case \"\(f.name)\": if let v = value as? \(isMulti ? "[\(type)]" : type) { \(f.name) = v }"
            }
            res += "\n        default: break"
            res += "\n        }\n    }"
        }
        res += "\n}\n"
        return res
    }

    /// Determine if a structural feature is multi-valued.
    ///
    /// - Parameter f: The structural feature to check.
    /// - Returns: True if the feature supports multiple values.
    private func isMultiValued(_ f: any EStructuralFeature) -> Bool {
        if let a = f as? EAttribute { return a.upperBound == -1 || a.upperBound > 1 }
        if let r = f as? EReference { return r.upperBound == -1 || r.upperBound > 1 }
        return false
    }

    /// Determine the base Swift type for a structural feature.
    ///
    /// - Parameter f: The structural feature to analyse.
    /// - Returns: A string representing the Swift type name.
    private func swiftBaseType(for f: any EStructuralFeature) -> String {
        if let a = f as? EAttribute { return mapEcoreType(a.eType.name) }
        if let r = f as? EReference { return r.eType.name }
        return "EObject"
    }

    /// Determine the property type string for a structural feature, handling multiplicity and optionality.
    ///
    /// - Parameter f: The structural feature to analyse.
    /// - Returns: A formatted Swift type string.
    private func swiftPropertyType(for f: any EStructuralFeature) -> String {
        let base = swiftBaseType(for: f), isMulti = isMultiValued(f)
        return isMulti ? "[\(base)]" : "\(base)?"
    }

    /// Map standard Ecore primitive types to their Swift equivalents.
    ///
    /// - Parameter name: The Ecore type name.
    /// - Returns: The corresponding Swift type name.
    private func mapEcoreType(_ name: String) -> String {
        switch name {
        case "EString": return "String"
        case "EInt", "EIntegerObject": return "Int"
        case "EBoolean", "EBooleanObject": return "Bool"
        case "EDouble", "EDoubleObject": return "Double"
        case "EFloat", "EFloatObject": return "Float"
        case "ELong", "ELongObject": return "Int64"
        case "EShort", "EShortObject": return "Int16"
        case "EByte", "EByteObject": return "Int8"
        default: return name
        }
    }

    /// Generate code for a Swift factory struct.
    ///
    /// - Parameter pkg: The Ecore package to create a factory for.
    /// - Returns: The generated Swift source code for the factory.
    private func generateSwiftFactory(from pkg: EPackage) -> String {
        let name = "\(pkg.name.capitalized)Factory"
        let summary = "A factory for creating instances of classes defined in the \(pkg.name) package."
        let description = "The factory provides typed methods for instantiating each concrete class in the metamodel."

        var res = "\n\n/// \(summary)\n///\n/// \(description)"
        res += "\nstruct \(name) {"
        let concretes = pkg.eClassifiers.compactMap { $0 as? EClass }.filter { !$0.isAbstract && !$0.isInterface }
        for c in concretes {
            res += "\n    /// Create a new \(c.name) instance.\n    ///\n    /// - Returns: A fresh \(c.name) object."
            res += "\n    func create\(c.name)() -> \(c.name) { return \(c.name)(eClass: \(pkg.name.capitalized)Package.shared.e\(c.name)) }"
        }
        res += "\n\n    /// Create a new object instance for the specified Ecore class.\n    ///\n    /// - Parameter eClass: The Ecore metaclass to instantiate.\n    /// - Returns: A new object instance conforming to the specified class."
        res += "\n    func create(_ eClass: EClass) -> any EObject {"
        res += "\n        switch eClass.id {"
        for c in concretes { res += "\n        case \(pkg.name.capitalized)Package.shared.e\(c.name).id: return create\(c.name)()" }
        res += "\n        default: fatalError(\"Unknown EClass: \\(eClass.name)\")"
        res += "\n        }\n    }\n}"
        return res
    }

    /// Generate code for a Swift package descriptor.
    ///
    /// - Parameter pkg: The Ecore package to describe.
    /// - Returns: The generated Swift source code for the package descriptor.
    private func generateSwiftPackageDescriptor(from pkg: EPackage) -> String {
        let name = "\(pkg.name.capitalized)Package"
        let summary = "The descriptor for the \(pkg.name) Ecore package."
        let description = "This structure holds the singleton package instance and its associated metadata elements."

        var res = "\n\n/// \(summary)\n///\n/// \(description)"
        res += "\nstruct \(name) {"
        res += "\n    /// The shared singleton instance of the package descriptor."
        res += "\n    static let shared = \(name)()"
        res += "\n    /// The underlying Ecore package element."
        res += "\n    let ePackage: EPackage"
        res += "\n    /// The factory associated with this package."
        res += "\n    let factory = \(pkg.name.capitalized)Factory()"
        let classes = pkg.eClassifiers.compactMap { $0 as? EClass }
        for c in classes {
            res += "\n    /// The EClass descriptor for the \(c.name) type."
            res += "\n    let e\(c.name): EClass"
        }
        res += "\n\n    /// Internal initialiser to configure the package descriptor."
        res += "\n    private init() {"
        res += "\n        ePackage = EPackage(name: \"\(pkg.name)\")"
        for c in classes {
            res += "\n        e\(c.name) = EClass(name: \"\(c.name)\", isAbstract: \(c.isAbstract), isInterface: \(c.isInterface))"
            res += "\n        var p = ePackage; p.eClassifiers.append(e\(c.name))"
        }
        res += "\n    }\n}"
        return res
    }

    /// Generate DocC documentation for a structural feature.
    ///
    /// - Parameter feature: The structural feature to document.
    /// - Returns: A DocC comment string.
    private func generateFeatureDocumentation(for feature: any EStructuralFeature) -> String {
        let annotations: [EAnnotation]
        if let a = feature as? EAttribute { annotations = a.eAnnotations }
        else if let r = feature as? EReference { annotations = r.eAnnotations }
        else { annotations = [] }

        let modelDoc = extractDocumentationFromAnnotations(annotations)
        if !modelDoc.isEmpty { return modelDoc.trimmingCharacters(in: .whitespacesAndNewlines) }

        let typeName = feature is EAttribute ? "attribute" : "reference"
        return "/// The \(feature.name) \(typeName)."
    }

    /// Generate a Swift property declaration for an attribute.
    ///
    /// - Parameter a: The Ecore attribute.
    /// - Returns: A Swift property declaration string.
    private func generateSwiftProperty(for a: EAttribute) -> String {
        let type = mapEcoreType(a.eType.name), isMulti = a.upperBound == -1 || a.upperBound > 1
        let base = "var \(a.name): \(isMulti ? "[\(type)]" : "\(type)?")"
        if let def = a.defaultValueLiteral { return "\(base) = \(formatDefaultValue(def, for: type))" }
        return isMulti ? "\(base) = []" : base
    }

    /// Generate a Swift property declaration for a reference, including bidirectional logic.
    ///
    /// - Parameters:
    ///   - r: The Ecore reference.
    ///   - referenceMap: The map for bidirectional resolution.
    ///   - isProtocol: Whether to generate a protocol requirement.
    /// - Returns: A Swift property declaration string.
    private func generateSwiftProperty(for r: EReference, referenceMap: [UUID: EReference], isProtocol: Bool = false) -> String {
        let name = r.name, isMulti = r.upperBound == -1 || r.upperBound > 1, type = r.eType.name
        let opposite = r.opposite.flatMap { referenceMap[$0] }
        if isProtocol { return "var \(name): \(isMulti ? "[\(type)]" : "\(type)?")" }
        var res = ""
        if let opp = opposite {
            res += "/// Bidirectional reference to \(type) (opposite: \(opp.name))\n    "
            if isMulti { res += "var \(name): [\(type)] = []" }
            else {
                let strength = r.containment ? "" : "weak "
                let oppName = opp.name, oppIsMulti = opp.upperBound == -1 || opp.upperBound > 1
                res += "\(strength)var \(name): \(type)? {\n        didSet {\n"
                if oppIsMulti {
                    res += "            if let old = oldValue, let index = old.\(oppName).firstIndex(where: { $0 === self }) { old.\(oppName).remove(at: index) }\n"
                    res += "            if let new = \(name), !new.\(oppName).contains(where: { $0 === self }) { new.\(oppName).append(self) }\n"
                } else {
                    res += "            if let old = oldValue, old.\(oppName) === self { old.\(oppName) = nil }\n"
                    res += "            if let new = \(name), new.\(oppName) !== self { new.\(oppName) = self }\n"
                }
                res += "        }\n    }"
            }
        } else {
            let strength = (r.containment || isMulti) ? "" : "weak "
            res += "\(strength)var \(name): \(isMulti ? "[\(type)] = []" : "\(type)?")"
        }
        return res
    }

    /// Extract and format documentation from Ecore annotations.
    ///
    /// - Parameter annotations: The list of annotations to scan.
    /// - Returns: A formatted documentation string.
    private func extractDocumentationFromAnnotations(_ annotations: [EAnnotation]) -> String {
        for annotation in annotations {
            if annotation.source == "http://www.eclipse.org/emf/2002/GenModel" || annotation.source == "documentation" {
                for (key, value) in annotation.details {
                    if key == "documentation" || key == "body" {
                        let lines = value.split(separator: "\n")
                        if lines.count == 1 { return "\n/// \(value)\n" }
                        var res = "\n/**"
                        for line in lines { res += "\n * \(line)" }
                        res += "\n */\n"
                        return res
                    }
                }
            }
        }
        return ""
    }

    /// Format a default value literal for inclusion in Swift source code.
    ///
    /// - Parameters:
    ///   - literal: The raw default value literal.
    ///   - typeName: The Swift type name.
    /// - Returns: A formatted Swift literal.
    private func formatDefaultValue(_ literal: String, for typeName: String) -> String {
        switch typeName {
        case "String": return "\"\(literal)\""
        case "Bool": return literal.lowercased()
        case "Int", "Int8", "Int16", "Int64", "Double", "Float", "Decimal": return literal
        case "Character": return "\"\(literal.prefix(1))\""
        default: return ".\(literal)"
        }
    }

    // MARK: - C++ Generation

    /// Generate C++ source code from the provided resource.
    ///
    /// - Parameters:
    ///   - resource: The resource containing the metamodel.
    ///   - verbose: Whether to print progress details.
    private func generateCpp(from resource: Resource, verbose: Bool) async throws {
        let objects = await resource.getRootObjects()
        let headerFile = outputDirectory.appendingPathComponent("Generated.hpp")
        var headerContent = "#pragma once\n#include <string>\n#include <vector>\n"
        for obj in objects {
            if let cls = await resolveClass(obj, in: resource) {
                headerContent += "\nclass \(cls.name) {\npublic:\n"
                for f in cls.eStructuralFeatures { if let a = f as? EAttribute { headerContent += "    std::string get\(a.name.capitalized)() const;\n"; headerContent += "    void set\(a.name.capitalized)(std::string v);\n" } }
                headerContent += "};\n"
            }
        }
        try headerContent.write(to: headerFile, atomically: true, encoding: .utf8)
    }
}
