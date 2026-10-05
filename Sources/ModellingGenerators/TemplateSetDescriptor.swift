//
// TemplateSetDescriptor.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import MTL

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
///   "options": { "lineDelimiter": "\n" },
///   "styles": {
///     "tabs": { "sourceIndent": "  ", "targetIndent": "\t", "openerPlacement": "sameLine", "files": ["*.java"] },
///     "spaces": { "sourceIndent": "  ", "targetIndent": "  " }
///   },
///   "defaultStyle": "tabs"
/// }
/// ```
///
/// ## Code styles
///
/// A template set writes its text in one layout. The optional `styles` section names other layouts
/// as data, and `defaultStyle` names the one that applies when the caller does not choose. A style
/// converts indentation and the placement of block openers, using only lexical knowledge, so the
/// generator needs no knowledge of the target language. See ``Style``.
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

    /// A code style: the conversion of the layout that a template set writes into another layout.
    ///
    /// Every member is optional in the descriptor. A style that changes nothing, because the
    /// indentation units are equal and openers keep their own line, selects the layout that the
    /// templates write.
    ///
    /// ## Example
    ///
    /// ```json
    /// { "summary": "Tabs, brace on the same line", "sourceIndent": "  ", "targetIndent": "\t",
    ///   "openerPlacement": "sameLine", "files": ["*.java"] }
    /// ```
    public struct Style: Codable, Sendable, Equatable {
        /// A block comment with its start and end delimiters.
        public struct BlockComment: Codable, Sendable, Equatable {
            /// The text that starts the comment.
            public var start: String

            /// The text that ends the comment.
            public var end: String

            /// Creates a block comment description.
            ///
            /// - Parameters:
            ///   - start: The text that starts the comment.
            ///   - end: The text that ends the comment.
            public init(start: String, end: String) {
                self.start = start
                self.end = end
            }
        }

        /// A one-line description of the style, shown in help and listings.
        public var summary: String?

        /// The indentation unit that the templates write; `nil` means one tab.
        public var sourceIndent: String?

        /// The indentation unit to produce; `nil` means one tab.
        public var targetIndent: String?

        /// Where block openers are written; `ownLine` leaves the text as the templates write it.
        public var openerPlacement: MTLOpenerPlacement

        /// The glob patterns of the files that the style applies to; empty means every file.
        public var files: [String]

        /// The character that opens a block; `nil` keeps the brace convention.
        public var openerToken: String?

        /// The markers that start a comment running to the end of the line; `nil` keeps the default.
        public var lineComments: [String]?

        /// The delimiters of comments that may span lines; `nil` keeps the default.
        public var blockComments: [BlockComment]?

        /// The characters that delimit string and character literals; `nil` keeps the default.
        public var quotes: String?

        /// The characters that end a statement; `nil` keeps the default.
        public var terminators: String?

        /// Creates a style.
        ///
        /// - Parameters:
        ///   - summary: A one-line description.
        ///   - sourceIndent: The indentation unit that the templates write.
        ///   - targetIndent: The indentation unit to produce.
        ///   - openerPlacement: Where block openers are written.
        ///   - files: The glob patterns of the files that the style applies to.
        ///   - openerToken: The character that opens a block.
        ///   - lineComments: The markers of line comments.
        ///   - blockComments: The delimiters of block comments.
        ///   - quotes: The characters that delimit literals.
        ///   - terminators: The characters that end a statement.
        public init(
            summary: String? = nil, sourceIndent: String? = nil, targetIndent: String? = nil,
            openerPlacement: MTLOpenerPlacement = .ownLine, files: [String] = [],
            openerToken: String? = nil, lineComments: [String]? = nil,
            blockComments: [BlockComment]? = nil, quotes: String? = nil, terminators: String? = nil
        ) {
            self.summary = summary
            self.sourceIndent = sourceIndent
            self.targetIndent = targetIndent
            self.openerPlacement = openerPlacement
            self.files = files
            self.openerToken = openerToken
            self.lineComments = lineComments
            self.blockComments = blockComments
            self.quotes = quotes
            self.terminators = terminators
        }

        /// Reads a style, with missing members at their defaults.
        ///
        /// - Throws: `DecodingError` if the opener token is not a single character.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            summary = try container.decodeIfPresent(String.self, forKey: .summary)
            sourceIndent = try container.decodeIfPresent(String.self, forKey: .sourceIndent)
            targetIndent = try container.decodeIfPresent(String.self, forKey: .targetIndent)
            openerPlacement =
                try container.decodeIfPresent(MTLOpenerPlacement.self, forKey: .openerPlacement) ?? .ownLine
            files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
            openerToken = try container.decodeIfPresent(String.self, forKey: .openerToken)
            lineComments = try container.decodeIfPresent([String].self, forKey: .lineComments)
            blockComments = try container.decodeIfPresent([BlockComment].self, forKey: .blockComments)
            quotes = try container.decodeIfPresent(String.self, forKey: .quotes)
            terminators = try container.decodeIfPresent(String.self, forKey: .terminators)
            if let openerToken, openerToken.count != 1 {
                throw DecodingError.dataCorruptedError(
                    forKey: .openerToken, in: container,
                    debugDescription: "the opener token must be a single character")
            }
        }

        /// The layout conversion that the style describes.
        ///
        /// Members that the style leaves out keep the defaults of the generator's layout conversion.
        ///
        /// - Returns: The configuration to give the generator.
        public var layoutConfiguration: MTLLayoutConfiguration {
            var syntax = MTLLayoutConfiguration().syntax
            if let openerToken, let character = openerToken.first { syntax.opener = character }
            if let lineComments { syntax.lineComments = lineComments }
            if let blockComments {
                syntax.blockComments = blockComments.map {
                    MTLMergeSyntax.BlockComment(start: $0.start, end: $0.end)
                }
            }
            if let quotes { syntax.quotes = Array(quotes) }
            if let terminators { syntax.terminators = Array(terminators) }
            return MTLLayoutConfiguration(
                sourceIndent: sourceIndent ?? MTLLayoutConfiguration.defaultIndent,
                targetIndent: targetIndent ?? MTLLayoutConfiguration.defaultIndent,
                openerPlacement: openerPlacement, syntax: syntax, filePatterns: files)
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

    /// The code styles of the set by name; empty if the set offers no choice of layout.
    public var styles: [String: Style]

    /// The name of the style that applies when the caller chooses none; `nil` leaves the text as
    /// the templates write it.
    public var defaultStyle: String?

    /// The names of the code styles, sorted.
    public var styleNames: [String] { styles.keys.sorted() }

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
    ///   - styles: The code styles by name.
    ///   - defaultStyle: The name of the style that applies by default.
    public init(
        name: String, summary: String? = nil, mainModule: String, mainTemplate: String,
        fileCountTemplate: String? = nil, dataModels: [DataModel] = [], layout: Layout = Layout(),
        options: Options = Options(), styles: [String: Style] = [:], defaultStyle: String? = nil
    ) {
        self.name = name
        self.summary = summary
        self.mainModule = mainModule
        self.mainTemplate = mainTemplate
        self.fileCountTemplate = fileCountTemplate
        self.dataModels = dataModels
        self.layout = layout
        self.options = options
        self.styles = styles
        self.defaultStyle = defaultStyle
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
        styles = try container.decodeIfPresent([String: Style].self, forKey: .styles) ?? [:]
        defaultStyle = try container.decodeIfPresent(String.self, forKey: .defaultStyle)
        if let defaultStyle, styles[defaultStyle] == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .defaultStyle, in: container,
                debugDescription: "the default style '\(defaultStyle)' is not one of the styles")
        }
    }

    /// The layout conversion for a code style.
    ///
    /// - Parameter requested: The name of the style the caller chose, or `nil` for the default style.
    /// - Returns: The layout conversion, or `nil` if neither a style was requested nor a default
    ///   style exists, in which case the text stays as the templates write it.
    /// - Throws: ``GenerationError/unknownCodeStyle(_:_:_:)`` if the requested name is not a style
    ///   of the set.
    public func layoutConfiguration(forStyle requested: String?) throws -> MTLLayoutConfiguration? {
        guard let name = requested ?? defaultStyle else { return nil }
        guard let style = styles[name] else {
            throw GenerationError.unknownCodeStyle(name, self.name, styleNames)
        }
        return style.layoutConfiguration
    }
}
