//
// TemplateSetDescriptor.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The description of a template set, read from its `templateset.json` file.
///
/// The descriptor tells the pipeline which module and template drive the generation, which data
/// models to load for the templates, where to write the output by default and which generator
/// options to apply. Only `name`, `mainModule` and `mainTemplate` are required.
///
/// ## Example
///
/// ```json
/// {
///   "name": "java",
///   "summary": "Java model code",
///   "mainModule": "generate",
///   "mainTemplate": "generate",
///   "fileCountTemplate": "fileCount",
///   "dataModels": [
///     { "name": "types", "metamodel": "TypeMapping.ecore", "model": "java-types.xmi" }
///   ],
///   "layout": { "sourceRootSetting": "modelDirectory", "includeSourceRoot": false },
///   "options": { "lineDelimiter": "\n" }
/// }
/// ```
public struct TemplateSetDescriptor: Codable, Sendable, Equatable {
    /// A data model that the templates read.
    public struct DataModel: Codable, Sendable, Equatable {
        /// The name under which templates reach the model with `templateData('name')`.
        public var name: String

        /// The file name of the metamodel, relative to the template set.
        public var metamodel: String

        /// The file name of the model, an instance of the metamodel, relative to the template set.
        public var model: String

        /// Creates a data model description.
        ///
        /// - Parameters:
        ///   - name: The name that templates use for the model.
        ///   - metamodel: The file name of the metamodel.
        ///   - model: The file name of the model.
        public init(name: String, metamodel: String, model: String) {
            self.name = name
            self.metamodel = metamodel
            self.model = model
        }
    }

    /// Where the output of the template set is written, relative to the output directory.
    public struct Layout: Codable, Sendable, Equatable {
        /// The name of the generator model setting that holds a source directory, such as the
        /// directory that the model's code belongs in; `nil` if the set has no such notion.
        public var sourceRootSetting: String?

        /// Whether the directory named by ``sourceRootSetting`` is appended to the output
        /// directory unless the caller decides otherwise.
        public var includeSourceRoot: Bool

        /// Creates a layout description.
        ///
        /// - Parameters:
        ///   - sourceRootSetting: The setting that names the source directory, if any.
        ///   - includeSourceRoot: Whether the source directory is part of the default layout.
        public init(sourceRootSetting: String? = nil, includeSourceRoot: Bool = false) {
            self.sourceRootSetting = sourceRootSetting
            self.includeSourceRoot = includeSourceRoot
        }

        /// Reads a layout, with missing members at their defaults.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sourceRootSetting = try container.decodeIfPresent(String.self, forKey: .sourceRootSetting)
            includeSourceRoot = try container.decodeIfPresent(Bool.self, forKey: .includeSourceRoot) ?? false
        }
    }

    /// The generator options that the template set prescribes.
    public struct Options: Codable, Sendable, Equatable {
        /// The line delimiter written to files; `nil` keeps the line feed.
        public var lineDelimiter: String?

        /// Creates generator options.
        ///
        /// - Parameter lineDelimiter: The line delimiter written to files.
        public init(lineDelimiter: String? = nil) {
            self.lineDelimiter = lineDelimiter
        }
    }

    /// The name of the template set, which is also its language.
    public var name: String

    /// A one-line description of what the set generates.
    public var summary: String?

    /// The name of the module that holds the main template, without extension.
    public var mainModule: String

    /// The name of the main template. It takes the generator model as its only argument.
    public var mainTemplate: String

    /// The name of an optional template of the main module that takes the generator model and
    /// writes the number of files that the main template writes, as the only content of one
    /// file. The pipeline runs it without writing to disk and uses the number to report progress.
    public var fileCountTemplate: String?

    /// The data models that the templates read.
    public var dataModels: [DataModel]

    /// The default output layout.
    public var layout: Layout

    /// The generator options of the set.
    public var options: Options

    /// Creates a descriptor.
    ///
    /// - Parameters:
    ///   - name: The name and language of the set.
    ///   - summary: A one-line description.
    ///   - mainModule: The module that holds the main template.
    ///   - mainTemplate: The main template.
    ///   - fileCountTemplate: The query that counts the files to write, if any.
    ///   - dataModels: The data models for the templates.
    ///   - layout: The default output layout.
    ///   - options: The generator options.
    public init(
        name: String, summary: String? = nil, mainModule: String, mainTemplate: String,
        fileCountTemplate: String? = nil, dataModels: [DataModel] = [], layout: Layout = Layout(),
        options: Options = Options()
    ) {
        self.name = name
        self.summary = summary
        self.mainModule = mainModule
        self.mainTemplate = mainTemplate
        self.fileCountTemplate = fileCountTemplate
        self.dataModels = dataModels
        self.layout = layout
        self.options = options
    }

    /// Reads a descriptor, with optional members at their defaults.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        mainModule = try container.decode(String.self, forKey: .mainModule)
        mainTemplate = try container.decode(String.self, forKey: .mainTemplate)
        fileCountTemplate = try container.decodeIfPresent(String.self, forKey: .fileCountTemplate)
        dataModels = try container.decodeIfPresent([DataModel].self, forKey: .dataModels) ?? []
        layout = try container.decodeIfPresent(Layout.self, forKey: .layout) ?? Layout()
        options = try container.decodeIfPresent(Options.self, forKey: .options) ?? Options()
    }
}
