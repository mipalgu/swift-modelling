//
// GenModelDefaults.swift
// ModellingGenerators
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
/// The named sets of default generator model settings that an import can start from.
///
/// A preset decides the values of the settings that the Eclipse tools write differently
/// depending on how a generator model is created: whether generated models include
/// operation reflection, which class generated root objects extend, and whether generated
/// code organises its imports. The values of each preset are defined by the bundled
/// transformation, so that a replacement transformation can define its own.
///
/// Individual settings of ``GenModelImportOptions`` take precedence over the preset.
public enum GenModelDefaults: String, Sendable, Equatable, CaseIterable {
    /// The settings of the headless generator.
    ///
    /// The three settings keep the defaults of the generator metamodel, so they are not written
    /// to the generator model. This is what the command line generator of the Eclipse tools
    /// produces, and the default of this library.
    case headless

    /// The settings of the interactive generator model wizard.
    ///
    /// Operation reflection and import organising are switched on, and root objects extend
    /// the minimal root class with a container.
    case wizard
}
