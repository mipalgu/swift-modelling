//
// QueryEngine.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

// MARK: - Query Engine

/// Actor responsible for executing queries against model resources.
///
/// The query engine provides various inspection and analysis capabilities
/// for examining model content and structure.
actor QueryEngine {
    /// The resource to query against.
    let resource: Resource

    /// Initialises a new query engine.
    ///
    /// - Parameter resource: The resource to query against.
    init(resource: Resource) {
        self.resource = resource
    }

    /// Executes a query against the resource.
    ///
    /// - Parameter query: The query string to execute.
    /// - Returns: The query result as a formatted string.
    /// - Throws: `QueryError` if the query is invalid or fails.
    func execute(_ query: String) async throws -> String {
        let parts = query.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines)
        guard let command = parts.first else {
            throw QueryError.invalidQuery("Empty query")
        }

        let objects = await resource.getRootObjects()

        switch command {
        case "info":
            return generateInfo(for: objects)
        case "count":
            return "Total objects: \(objects.count)"
        case "list-classes":
            return generateClassList(for: objects)
        case "find":
            guard parts.count > 1 else {
                throw QueryError.invalidQuery("find requires a class name")
            }
            return findObjects(matching: parts[1], in: objects)
        case "tree":
            return generateTree(for: objects)
        default:
            throw QueryError.unsupportedQuery(command)
        }
    }

    /// Generates general information about the model objects.
    ///
    /// - Parameter objects: The objects to analyse.
    /// - Returns: Formatted information string.
    private func generateInfo(for objects: [any EObject]) -> String {
        var result = "Model Information\n"
        result += "=================\n"
        result += "Total objects: \(objects.count)\n\n"

        var classCount: [String: Int] = [:]
        for obj in objects {
            if let dynamicObj = obj as? DynamicEObject {
                let className = dynamicObj.eClass.name
                classCount[className, default: 0] += 1
            } else {
                let className = String(describing: type(of: obj))
                classCount[className, default: 0] += 1
            }
        }

        if !classCount.isEmpty {
            result += "Classes:\n"
            for (className, count) in classCount.sorted(by: { $0.key < $1.key }) {
                result += "  * \(className): \(count)\n"
            }
        }

        return result
    }

    /// Generates a list of available classes in the model.
    ///
    /// - Parameter objects: The objects to analyse.
    /// - Returns: Formatted class list string.
    private func generateClassList(for objects: [any EObject]) -> String {
        var result = "Available Classes\n"
        result += "=================\n"

        let classNames = Set(
            objects.compactMap { obj -> String? in
                if let dynamicObj = obj as? DynamicEObject {
                    return dynamicObj.eClass.name
                } else {
                    return String(describing: type(of: obj))
                }
            })

        for className in classNames.sorted() {
            result += "* \(className)\n"
        }

        return result
    }

    /// Finds objects matching a specific class name.
    ///
    /// - Parameters:
    ///   - className: The class name to match.
    ///   - objects: The objects to search within.
    /// - Returns: Formatted results string.
    private func findObjects(matching className: String, in objects: [any EObject]) -> String {
        let matches = objects.filter { obj in
            if let dynamicObj = obj as? DynamicEObject {
                return dynamicObj.eClass.name.lowercased() == className.lowercased()
            } else {
                return String(describing: type(of: obj)).lowercased().contains(
                    className.lowercased())
            }
        }

        var result = "Objects matching '\(className)'\n"
        result += String(repeating: "=", count: "Objects matching '\(className)'".count) + "\n"
        result += "Found \(matches.count) match(es)\n\n"

        for (index, obj) in matches.enumerated() {
            if let dynamicObj = obj as? DynamicEObject {
                result += "\(index + 1). \(dynamicObj.eClass.name) (id: \(dynamicObj.id))\n"

                // Show some features
                let featureNames = dynamicObj.getFeatureNames()
                for featureName in featureNames.prefix(3) {
                    if let value = dynamicObj.eGet(featureName) {
                        result += "   \(featureName): \(value)\n"
                    }
                }
                if featureNames.count > 3 {
                    result += "   ... (\(featureNames.count - 3) more features)\n"
                }
            } else {
                result += "\(index + 1). \(String(describing: type(of: obj)))\n"
            }
            result += "\n"
        }

        return result
    }

    /// Generates a tree view of objects and their relationships.
    ///
    /// - Parameter objects: The objects to display in tree format.
    /// - Returns: Formatted tree string.
    private func generateTree(for objects: [any EObject]) -> String {
        var result = "Object Tree\n"
        result += "===========\n"

        for (index, obj) in objects.enumerated() {
            result += generateTreeNode(for: obj, prefix: "", isLast: index == objects.count - 1)
        }

        return result
    }

    /// Generates a single tree node representation.
    ///
    /// - Parameters:
    ///   - obj: The object to represent.
    ///   - prefix: The prefix for indentation.
    ///   - isLast: Whether this is the last node at this level.
    /// - Returns: Formatted tree node string.
    private func generateTreeNode(for obj: any EObject, prefix: String, isLast: Bool) -> String {
        var result = ""
        let nodePrefix = isLast ? "+-- " : "|-- "

        if let dynamicObj = obj as? DynamicEObject {
            result += "\(prefix)\(nodePrefix)\(dynamicObj.eClass.name) (id: \(dynamicObj.id))\n"
        } else {
            result += "\(prefix)\(nodePrefix)\(String(describing: type(of: obj)))\n"
        }

        return result
    }
}
