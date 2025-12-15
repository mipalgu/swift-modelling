//
// SwiftATL.swift
// swift-atl
//
//  Created by Rene Hexel on 6/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//

import ArgumentParser

/// The main entry point for the swift-atl command-line tool.
///
/// Swift ATL provides a command-line interface for Atlas Transformation Language
/// operations, including transformation compilation, model transformation execution,
/// parsing, validation, testing, and analysis of ATL modules.
///
/// ## Available Commands
///
/// - **parse**: Parse and validate ATL transformation files
/// - **validate**: Validate ATL transformation syntax and semantics
/// - **test**: Test ATL transformation files with sample data
/// - **analyze**: Analyze ATL transformation files for complexity and metrics
/// - **compile**: Compile ATL transformation files to executable modules
/// - **transform**: Execute model transformations using compiled ATL modules
/// - **generate**: Generate code from models using ATL-based code generators
///
/// ## Example Usage
///
/// ```bash
/// # Parse an ATL transformation
/// swift-atl parse Families2Persons.atl --verbose
///
/// # Validate multiple ATL files
/// swift-atl validate *.atl --output validation-report.txt
///
/// # Test ATL transformations
/// swift-atl test --directory Tests/ATLTests/Resources
///
/// # Analyze transformation complexity
/// swift-atl analyze Families2Persons.atl --metrics complexity,rules,helpers
///
/// # Compile an ATL transformation
/// swift-atl compile Families2Persons.atl --output families2persons.atlc
///
/// # Execute a transformation
/// swift-atl transform families2persons.atlc \
///   --source families.xmi --target persons.xmi
/// ```
@main
struct SwiftATLCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-atl",
        abstract: "Atlas Transformation Language command-line tool",
        discussion: """
            Swift ATL provides comprehensive support for model transformation using the
            Atlas Transformation Language (ATL). It enables parsing, validation, testing,
            analysis, compilation of ATL transformations, execution of model-to-model
            transformations, and generation of code from models.

            The tool supports standard ATL syntax for compatibility with existing Eclipse ATL
            transformations while providing enhanced performance through Swift's concurrent
            execution model and type safety.
            """,
        version: "1.0.0",
        subcommands: [
            ParseCommand.self,
            ValidateCommand.self,
            TestCommand.self,
            AnalyzeCommand.self,
            CompileCommand.self,
            TransformCommand.self,
            GenerateCommand.self,
        ],
        defaultSubcommand: nil
    )
}
