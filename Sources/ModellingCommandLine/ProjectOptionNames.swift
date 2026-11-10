//
// ProjectOptionNames.swift
// ModellingCommandLine
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The long names of the options that make the validation of models stricter, which are also
/// the keys of the configuration file.
///
/// The validate command of `swift-ecore` offers the options; ``ModellingConfiguration`` reads
/// the keys.
public enum ValidationOptionName {
    /// The flag that makes warnings fail the validation as errors do.
    public static let strict = "strict"

    /// The flag that makes every required single-valued feature need a value that the model sets.
    public static let requireExplicitValues = "require-explicit-values"
}

/// The long names of the options that override how graph transformation rules match, which are
/// also the keys of the configuration file.
///
/// The commands of `swift-henshin` that match rules offer the options, each with a flag that
/// turns it off; ``ModellingConfiguration`` reads the keys as booleans.
public enum MatchingOptionName {
    /// The flag that makes every rule check the dangling condition.
    public static let checkDangling = "check-dangling"

    /// The flag that makes every rule match injectively.
    public static let injective = "injective"
}
