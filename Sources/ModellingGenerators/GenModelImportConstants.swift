//
// GenModelImportConstants.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import GenModel

/// The single authoritative source of names and default values of the Ecore to generator model import.
///
/// The names of the transformation parameters, the default settings of a freshly
/// imported model and the conventions for locating projects live here. The names of the
/// generator metamodel's own classes and features come from ``GenModelConstants``.
public enum GenModelImportConstants {
    /// The identifier that marks a generator model as produced by the Ecore importer.
    public static let importerID = "org.eclipse.emf.importer.ecore"

    /// The compliance level written to a new generator model unless another is requested.
    public static let defaultComplianceLevel = "17.0"

    /// The class that generated root objects extend by default.
    public static let defaultRootExtendsClass = "org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container"

    /// The number of model elements above which a package counts as a big model.
    public static let bigModelThreshold = 500

    /// Whether generated models include operation reflection by default.
    public static let defaultOperationReflection = true

    /// Whether generated code organises its imports by default.
    public static let defaultImportOrganizing = true

    /// Whether generated files carry copyright fields by default.
    public static let defaultCopyrightFields = false

    /// The directory name that marks the model folder of a project.
    public static let modelFolderName = "model"

    /// The file extension of source models.
    public static let ecoreFileExtension = "ecore"

    /// The namespace URI of the Ecore metamodel.
    public static let ecoreNsURI = "http://www.eclipse.org/emf/2002/Ecore"

    /// The namespace URI of the XML type metamodel.
    public static let xmlTypeNsURI = "http://www.eclipse.org/emf/2003/XMLType"

    /// The annotation source that marks extended metadata.
    public static let extendedMetaDataSource = "http:///org/eclipse/emf/ecore/util/ExtendedMetaData"

    /// The instance class name of feature map entries.
    public static let featureMapEntryClass = "org.eclipse.emf.ecore.util.FeatureMap$Entry"

    /// The separator between items of a list passed to the transformation as text.
    public static let listSeparator = "\n"

    /// The separator between a package name and its prefix in a list of prefixes.
    public static let assignmentSeparator = String(assignmentSeparatorCharacter)

    /// The separator between a package name and its prefix, as a character.
    public static let assignmentSeparatorCharacter: Character = "="

    /// The alias of the Ecore source model in the transformation.
    public static let sourceAlias = "IN"

    /// The alias of the generator model target in the transformation.
    public static let targetAlias = "OUT"

    /// The file name of the bundled transformation, without extension.
    public static let transformationName = "Ecore2GenModel"

    /// The file extension of transformations.
    public static let transformationExtension = "atl"

    /// The directory of the bundled transformations.
    public static let transformationDirectory = "Transformations"

    /// The names of the parameters of the bundled transformation.
    public enum Parameter {
        /// The importer identifier.
        public static let importerID = "importerID"
        /// The class that generated root objects extend.
        public static let rootExtendsClass = "rootExtendsClass"
        /// Whether operation reflection is generated.
        public static let operationReflection = "operationReflection"
        /// Whether imports are organised.
        public static let importOrganizing = "importOrganizing"
        /// Whether copyright fields are generated.
        public static let copyrightFields = "copyrightFields"
        /// The big model threshold.
        public static let bigModelThreshold = "bigModelThreshold"
        /// The base package of the root packages.
        public static let basePackage = "basePackage"
        /// The prefix of the root packages.
        public static let prefix = "prefix"
        /// The prefixes of individual packages, as `name=prefix` entries.
        public static let packagePrefixes = "packagePrefixes"
        /// The name of the model project.
        public static let modelProject = "modelProject"
        /// The plug-in identifier of the model project.
        public static let modelPluginID = "modelPluginID"
        /// The source directory of the model project.
        public static let modelDirectory = "modelDirectory"
        /// The name of the generator model.
        public static let modelName = "modelName"
        /// The copyright text.
        public static let copyright = "copyright"
        /// The locations of the source models.
        public static let foreignModels = "foreignModels"
        /// The separator between list items.
        public static let listSeparator = "listSeparator"
        /// The separator between names and values in entries.
        public static let assignmentSeparator = "assignmentSeparator"
        /// The annotation source of extended metadata.
        public static let extendedMetaDataSource = "extendedMetaDataSource"
        /// The instance class name of feature map entries.
        public static let featureMapEntryClass = "featureMapEntryClass"
        /// The namespace URI of the XML type metamodel.
        public static let xmlTypeNsURI = "xmlTypeNsURI"
        /// The namespace URI of the Ecore metamodel.
        public static let ecoreNsURI = "ecoreNsURI"

        /// Every parameter name, which the bundled transformation declares.
        public static let all: Set<String> = [
            importerID, rootExtendsClass, operationReflection, importOrganizing, copyrightFields,
            bigModelThreshold, basePackage, prefix, packagePrefixes, modelProject, modelPluginID,
            modelDirectory, modelName, copyright, foreignModels, listSeparator, assignmentSeparator,
            extendedMetaDataSource, featureMapEntryClass, xmlTypeNsURI, ecoreNsURI,
        ]
    }

    /// The names of the generator model settings that the import writes or preserves by name.
    public enum Setting {
        /// The compliance level of the generator model.
        public static let complianceLevel = "complianceLevel"
        /// The copyright text of the generator model.
        public static let copyrightText = "copyrightText"
        /// The model plug-in identifier of the generator model.
        public static let modelPluginID = "modelPluginID"
        /// The model directory of the generator model.
        public static let modelDirectory = "modelDirectory"
        /// The base package of a generator package.
        public static let basePackage = "basePackage"
        /// The prefix of a generator package.
        public static let prefix = "prefix"
        /// The settings that a reconcile takes from the new import instead of the old model.
        public static let derivedFromSources: Set<String> = [
            GenModelConstants.FeatureName.foreignModel, importerID,
        ]
        /// The importer identifier setting.
        public static let importerID = "importerID"
    }
}
