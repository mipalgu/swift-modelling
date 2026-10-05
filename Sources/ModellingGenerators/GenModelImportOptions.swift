//
// GenModelImportOptions.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The settings of an import of Ecore models into a generator model.
///
/// The options mirror the settings of the Eclipse Ecore importer application. Every
/// option is optional: an option that is `nil` takes the importer's default, which is
/// described on the individual property. The settings that the Eclipse tools write
/// differently for headless and interactive use come from a preset, ``defaults``, which
/// ``operationReflection``, ``rootExtendsClass`` and ``importOrganizing`` override.
///
/// When an existing generator model is reloaded, the settings of that model are kept
/// unless an option is given explicitly, in which case the option wins.
///
/// ## Example
///
/// ```swift
/// var options = GenModelImportOptions()
/// options.basePackage = "org.example"
/// options.complianceLevel = "17.0"
/// let result = try await GenerationPipeline.ecoreToGenModel(ecoreURLs: [libraryURL], options: options)
/// ```
public struct GenModelImportOptions: Sendable, Equatable {
    /// The base package of the root packages; none by default.
    public var basePackage: String?

    /// The prefix of the root packages.
    ///
    /// By default the prefix is the package name with its first letter in upper case.
    public var prefix: String?

    /// The prefixes of individual packages, by package name.
    ///
    /// An entry here takes precedence over ``prefix``.
    public var packagePrefixes: [String: String]

    /// The name of the model project.
    ///
    /// By default the project is the parent directory of a source model that lives in a
    /// directory named `model`, and the name of the root package otherwise.
    public var modelProject: String?

    /// The plug-in identifier of the model project; the project name made valid by default.
    public var modelPluginID: String?

    /// The source directory of the model project; `/<project>/src` by default.
    public var modelDirectory: String?

    /// The copyright text; none by default.
    public var copyright: String?

    /// The compliance level of the generated code, such as `17.0`.
    ///
    /// New generator models use ``GenModelImportConstants/defaultComplianceLevel`` unless this is set;
    /// a reloaded generator model keeps its level unless this is set.
    public var complianceLevel: String?

    /// The existing generator model whose settings are kept; none by default.
    public var reload: URL?

    /// The generator model file to write.
    ///
    /// By default the file is named after the first source model, with the extension `genmodel`,
    /// and written beside it.
    public var output: URL?

    /// A transformation that replaces the bundled one; the bundled transformation by default.
    ///
    /// The location is either a transformation file, or a directory that holds a file named
    /// `Ecore2GenModel.atl`. The replacement receives the same parameters as the bundled
    /// transformation.
    public var transformation: URL?

    /// The preset of the settings that the Eclipse tools write differently for headless and interactive use.
    ///
    /// A new generator model uses ``GenModelDefaults/headless`` if this is `nil`. A reloaded generator
    /// model keeps its own values of those settings if this is `nil`; a preset given explicitly
    /// replaces them, and the individual overrides replace the preset.
    public var defaults: GenModelDefaults?

    /// Whether generated models include operation reflection; `nil` takes the value of the preset.
    public var operationReflection: Bool?

    /// The class that generated root objects extend; `nil` takes the value of the preset.
    public var rootExtendsClass: String?

    /// Whether the generated code organises its imports; `nil` takes the value of the preset.
    public var importOrganizing: Bool?

    /// Creates options with the importer's defaults.
    ///
    /// - Parameters:
    ///   - basePackage: The base package of the root packages.
    ///   - prefix: The prefix of the root packages.
    ///   - packagePrefixes: The prefixes of individual packages, by package name.
    ///   - modelProject: The name of the model project.
    ///   - modelPluginID: The plug-in identifier of the model project.
    ///   - modelDirectory: The source directory of the model project.
    ///   - copyright: The copyright text.
    ///   - complianceLevel: The compliance level of the generated code.
    ///   - reload: The existing generator model whose settings are kept.
    ///   - output: The generator model file to write.
    ///   - transformation: A transformation file or directory that replaces the bundled transformation.
    ///   - defaults: The preset of the settings that differ between headless and interactive use.
    ///   - operationReflection: Whether generated models include operation reflection, overriding the preset.
    ///   - rootExtendsClass: The class that generated root objects extend, overriding the preset.
    ///   - importOrganizing: Whether the generated code organises its imports, overriding the preset.
    public init(
        basePackage: String? = nil,
        prefix: String? = nil,
        packagePrefixes: [String: String] = [:],
        modelProject: String? = nil,
        modelPluginID: String? = nil,
        modelDirectory: String? = nil,
        copyright: String? = nil,
        complianceLevel: String? = nil,
        reload: URL? = nil,
        output: URL? = nil,
        transformation: URL? = nil,
        defaults: GenModelDefaults? = nil,
        operationReflection: Bool? = nil,
        rootExtendsClass: String? = nil,
        importOrganizing: Bool? = nil
    ) {
        self.basePackage = basePackage
        self.prefix = prefix
        self.packagePrefixes = packagePrefixes
        self.modelProject = modelProject
        self.modelPluginID = modelPluginID
        self.modelDirectory = modelDirectory
        self.copyright = copyright
        self.complianceLevel = complianceLevel
        self.reload = reload
        self.output = output
        self.transformation = transformation
        self.defaults = defaults
        self.operationReflection = operationReflection
        self.rootExtendsClass = rootExtendsClass
        self.importOrganizing = importOrganizing
    }

    /// Applies a prefix given as text.
    ///
    /// The text is either a prefix for the root packages (`Name`) or a prefix for one package
    /// (`package=Name`, using ``GenModelImportConstants/assignmentSeparator``).
    ///
    /// - Parameter argument: The prefix as given on a command line.
    public mutating func addPrefix(_ argument: String) {
        guard let separator = argument.firstIndex(of: GenModelImportConstants.assignmentSeparatorCharacter)
        else {
            prefix = argument
            return
        }
        let name = String(argument[..<separator])
        packagePrefixes[name] = String(argument[argument.index(after: separator)...])
    }
}
