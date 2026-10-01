//
// TemplateSetConstants.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The single authoritative source of names that template sets share.
///
/// A template set is a directory named after its language that holds a descriptor, template
/// modules and data models. The constants here name the descriptor, the bundled directory
/// and the file extensions that the loader recognises.
public enum TemplateSetConstants {
    /// The name of the directory that holds the bundled template sets.
    public static let bundledDirectory = "Templates"

    /// The name of the descriptor file in every template set.
    public static let descriptorFileName = "templateset.json"

    /// The file extension of template modules.
    public static let moduleFileExtension = "mtl"

    /// The file extension of data model metamodels.
    public static let metamodelFileExtension = "ecore"

    /// The prefix of the temporary directory in which template sets are assembled.
    public static let scratchDirectoryPrefix = "swift-modelling-templates"

    /// The name of the model alias under which the generator model is registered.
    public static let genModelAlias = "GENMODEL"

    /// The prefix of the model alias under which each data model is registered.
    public static let dataModelAliasPrefix = "DATA_"

    /// The redirection pattern written for `--diff`: the generated text of an existing file goes beside it.
    public static let diffRedirectionPattern = ".{0}.new"
}
