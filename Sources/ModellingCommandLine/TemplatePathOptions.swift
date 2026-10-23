//
// TemplatePathOptions.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ArgumentParser
import Foundation

/// The command line option that names directories to search for imported template modules.
///
/// A module that a template imports is searched in the directory of the importing template
/// first and then in each `--template-path` directory, in command line order.
///
/// Commands include the option with `@OptionGroup`, and obtain the checked directories from
/// ``directories()`` when they run.
public struct TemplatePathOptions: ParsableArguments, Sendable {
    /// The long name of the option.
    public static let optionName = "template-path"

    /// The directories as given on the command line, in command line order.
    @Option(
        name: .customLong(TemplatePathOptions.optionName),
        help: "A directory to search for imported modules (can be specified multiple times)")
    public var templatePaths: [String] = []

    /// Creates the option with no directories.
    public init() {}

    /// Whether at least one directory was given on the command line.
    public var isGiven: Bool { !templatePaths.isEmpty }

    /// The file locations of the directories, in command line order, without checking them.
    public var urls: [URL] { templatePaths.map { URL(fileURLWithPath: $0) } }

    /// The file locations of the directories, each checked to be an existing directory.
    ///
    /// - Returns: The locations in command line order.
    /// - Throws: ``TemplatePathError/notADirectory(_:)`` for the first path that is not an
    ///   existing directory.
    public func directories() throws -> [URL] {
        let urls = self.urls
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                isDirectory.boolValue
            else {
                throw TemplatePathError.notADirectory(url.path)
            }
        }
        return urls
    }
}

/// A problem with a template directory given on the command line.
public enum TemplatePathError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The path does not name an existing directory.
    ///
    /// The associated value is the path of the file location.
    case notADirectory(String)

    /// A sentence that names the path and says what is wrong with it.
    public var description: String {
        switch self {
        case .notADirectory(let path):
            return "The template path '\(path)' is not a directory"
        }
    }
}

extension TemplatePathError: LocalizedError {
    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
