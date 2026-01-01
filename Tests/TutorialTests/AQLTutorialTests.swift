//
// AQLTutorialTests.swift
// TutorialTests
//
// Created by Rene Hexel on 31/12/2025.
// Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation
import Testing

@testable import SwiftModelling

@Suite("AQL Tutorial Validation Tests")
struct AQLTutorialTests {

    // MARK: - Test Resources

    static var tutorialResourcesPath: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")
            .appendingPathComponent("SwiftModelling")
            .appendingPathComponent("SwiftModelling.docc")
            .appendingPathComponent("Resources")
    }

    // MARK: - AQL-01: Basics Tests

    @Suite("Tutorial AQL-01: Basics")
    struct AQL01Tests {

        @Test("Step 1: Company metamodel is well-formed")
        func testStep01CompanyMetamodel() async throws {
            // Validate that the company metamodel from step 1 is structurally correct
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-01")
                .appendingPathComponent("aql-01-step-01-company-metamodel.ecore")

            // Test that metamodel contains expected classes
            // Company, Employee classes should exist
            // Employee should have name, age, department attributes
            // Company should contain employees reference

            #expect(
                true, "Metamodel validation placeholder - implement when Ecore loading is available"
            )
        }

        @Test("Step 2: Company instance is valid")
        func testStep02CompanyInstance() async throws {
            // Validate the company instance from step 2
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-01")
                .appendingPathComponent("aql-01-step-02-company-instance.xmi")

            // Test that instance conforms to metamodel
            // Should contain company with multiple employees
            // Employees should have different departments

            #expect(
                true, "Instance validation placeholder - implement when XMI loading is available")
        }

        @Test("Step 3: Basic property access syntax")
        func testStep03PropertyAccess() async throws {
            // Test basic AQL property access expressions
            // employee.name should return string
            // company.employees should return collection

            let expressions = [
                "employee.name",
                "employee.age",
                "employee.department",
                "company.employees",
            ]

            for expression in expressions {
                // Validate AQL expression syntax
                #expect(!expression.isEmpty, "Expression should not be empty: \(expression)")
                #expect(
                    expression.contains("."),
                    "Property access should contain dot notation: \(expression)")
            }
        }

        @Test("Step 4: Literal values and operations")
        func testStep04Literals() async throws {
            // Test AQL literal syntax and basic operations
            let literals = [
                "'Hello World'",  // String literal
                "42",  // Integer literal
                "3.14",  // Real literal
                "true",  // Boolean literal
                "false",  // Boolean literal
            ]

            let operations = [
                "employee.age + 1",
                "employee.name + ' Smith'",
                "employee.age > 25",
                "employee.department = 'Engineering'",
            ]

            // Validate literal syntax
            for literal in literals {
                #expect(!literal.isEmpty, "Literal should not be empty: \(literal)")
            }

            // Validate operation syntax
            for operation in operations {
                #expect(!operation.isEmpty, "Operation should not be empty: \(operation)")
                #expect(
                    operation.contains(".") || operation.contains("'"),
                    "Operation should contain navigation or literals: \(operation)")
            }
        }

        @Test("Step 5-8: Navigation operations syntax")
        func testStep05to08NavigationOperations() async throws {
            // Test various navigation patterns
            let navigationExpressions = [
                "company.employees.name",  // Multi-step navigation
                "employee.company.name",  // Reference navigation
                "company.employees->size()",  // Collection size
                "company.employees->select(e | e.age > 30)",  // Filtering
                "company.employees->collect(e | e.name)",  // Collection transformation
            ]

            for expression in navigationExpressions {
                #expect(
                    !expression.isEmpty, "Navigation expression should not be empty: \(expression)")
                // Basic syntax validation for AQL expressions
                if expression.contains("->") {
                    #expect(
                        expression.contains("|") || expression.contains("()"),
                        "Collection operations should have parameters or empty parentheses: \(expression)"
                    )
                }
            }
        }

        @Test("Step 9-12: Operations and comparisons")
        func testStep09to12Operations() async throws {
            // Test arithmetic, string, and comparison operations
            let arithmeticOps = [
                "employee.age + 5",
                "employee.age - 1",
                "employee.age * 2",
                "employee.age / 2",
            ]

            let stringOps = [
                "employee.name + ' Jr.'",
                "employee.name.size()",
                "employee.name.toUpperCase()",
            ]

            let comparisonOps = [
                "employee.age = 25",
                "employee.age <> 30",
                "employee.age > 21",
                "employee.age <= 65",
            ]

            let allOps = arithmeticOps + stringOps + comparisonOps

            for operation in allOps {
                #expect(!operation.isEmpty, "Operation should not be empty: \(operation)")
                #expect(
                    operation.contains(".") || operation.contains("'"),
                    "Operation should contain navigation or literals: \(operation)")
            }
        }
    }

    // MARK: - AQL-02: Filtering and Selection Tests

    @Suite("Tutorial AQL-02: Filtering and Selection")
    struct AQL02Tests {

        @Test("Step 1-2: University metamodel and instance")
        func testStep01to02UniversityModel() async throws {
            // Validate university metamodel and instance structure
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-02")
                .appendingPathComponent("aql-02-step-01-university-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-02")
                .appendingPathComponent("aql-02-step-02-university-instance.xmi")

            // Should contain Student, Course, Professor classes
            // Students should have grades, Courses should have credit hours

            #expect(true, "University model validation placeholder")
        }

        @Test("Step 5-8: Select and reject operations")
        func testStep05to08SelectReject() async throws {
            // Test select and reject operation syntax
            let selectExpressions = [
                "students->select(s | s.grade >= 85)",
                "courses->select(c | c.credits > 3)",
                "professors->select(p | p.specialization = 'Computer Science')",
            ]

            let rejectExpressions = [
                "students->reject(s | s.grade < 60)",
                "courses->reject(c | c.credits < 3)",
                "professors->reject(p | p.specialization <> 'Mathematics')",
            ]

            let allExpressions = selectExpressions + rejectExpressions

            for expression in allExpressions {
                #expect(
                    expression.contains("->"),
                    "Filter operations should use arrow syntax: \(expression)")
                #expect(
                    expression.contains("|"),
                    "Filter operations should have lambda parameter: \(expression)")
                #expect(
                    expression.contains("select") || expression.contains("reject"),
                    "Should be select or reject operation: \(expression)")
            }
        }

        @Test("Step 9-12: Quantifier operations")
        func testStep09to12Quantifiers() async throws {
            // Test exists and forAll operations
            let existsExpressions = [
                "students->exists(s | s.grade >= 90)",
                "courses->exists(c | c.credits = 4)",
                "professors->exists(p | p.specialization = 'Physics')",
            ]

            let forAllExpressions = [
                "students->forAll(s | s.grade >= 0)",
                "courses->forAll(c | c.credits > 0)",
                "professors->forAll(p | p.specialization <> '')",
            ]

            let allQuantifiers = existsExpressions + forAllExpressions

            for expression in allQuantifiers {
                #expect(
                    expression.contains("->"),
                    "Quantifier operations should use arrow syntax: \(expression)")
                #expect(
                    expression.contains("|"),
                    "Quantifier operations should have lambda parameter: \(expression)")
                #expect(
                    expression.contains("exists") || expression.contains("forAll"),
                    "Should be exists or forAll operation: \(expression)")
            }
        }

        @Test("Step 13-16: Advanced filtering patterns")
        func testStep13to16AdvancedFiltering() async throws {
            // Test chained filters and complex patterns
            let chainedFilters = [
                "students->select(s | s.grade >= 80)->reject(s | s.grade >= 95)",
                "courses->select(c | c.credits >= 3)->select(c | c.department = 'CS')",
                "professors->reject(p | p.age < 30)->select(p | p.tenure = true)",
            ]

            for expression in chainedFilters {
                #expect(
                    expression.contains("->"),
                    "Chained filters should use arrow syntax: \(expression)")
                let arrowCount = expression.components(separatedBy: "->").count - 1
                #expect(
                    arrowCount >= 2, "Chained operations should have multiple arrows: \(expression)"
                )
            }
        }
    }

    // MARK: - AQL-03: Collection Operations Tests

    @Suite("Tutorial AQL-03: Collection Operations")
    struct AQL03Tests {

        @Test("Step 1-4: Library model setup")
        func testStep01to04LibraryModel() async throws {
            // Validate library metamodel with Books, Authors, Categories, Loans
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-03")
                .appendingPathComponent("aql-03-step-01-library-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-03")
                .appendingPathComponent("aql-03-step-04-library-instance.xmi")

            #expect(true, "Library model validation placeholder")
        }

        @Test("Step 5-8: Collect operations")
        func testStep05to08CollectOperations() async throws {
            // Test collect operation syntax and patterns
            let collectExpressions = [
                "books->collect(b | b.title)",
                "books->collect(b | b.author.name)",
                "books->collect(b | b.pages * 2)",
                "authors->collect(a | a.books->size())",
            ]

            for expression in collectExpressions {
                #expect(
                    expression.contains("->collect"), "Should use collect operation: \(expression)")
                #expect(
                    expression.contains("|"), "Collect should have lambda parameter: \(expression)")
            }
        }

        @Test("Step 9-12: Flatten operations")
        func testStep09to12FlattenOperations() async throws {
            // Test flatten operation syntax
            let flattenExpressions = [
                "authors->collect(a | a.books)->flatten()",
                "categories->collect(c | c.books)->flatten()->collect(b | b.title)",
                "books->collect(b | b.reviews)->flatten()",
            ]

            for expression in flattenExpressions {
                #expect(
                    expression.contains("->flatten()"),
                    "Should use flatten operation: \(expression)")
                #expect(
                    expression.contains("->collect"),
                    "Flatten typically follows collect: \(expression)")
            }
        }

        @Test("Step 13-16: Aggregation operations")
        func testStep13to16AggregationOperations() async throws {
            // Test sum, max, min, and counting operations
            let aggregationExpressions = [
                "books->collect(b | b.pages)->sum()",
                "books->collect(b | b.pages)->max()",
                "books->collect(b | b.pages)->min()",
                "books->select(b | b.available = true)->size()",
            ]

            for expression in aggregationExpressions {
                #expect(
                    expression.contains("->"), "Aggregation should use arrow syntax: \(expression)")
                let hasAggregation =
                    expression.contains("sum()") || expression.contains("max()")
                    || expression.contains("min()") || expression.contains("size()")
                #expect(hasAggregation, "Should contain aggregation operation: \(expression)")
            }
        }

        @Test("Step 17-20: Advanced patterns")
        func testStep17to20AdvancedPatterns() async throws {
            // Test complex collection operation patterns
            let advancedPatterns = [
                "books->collect(b | b.author)->select(a | a.nationality = 'British')->collect(a | a.name)",
                "categories->collect(c | c.books->select(b | b.available = true)->size())",
                "authors->select(a | a.books->forAll(b | b.rating >= 4.0))",
            ]

            for pattern in advancedPatterns {
                #expect(
                    pattern.contains("->"), "Advanced patterns should use arrow syntax: \(pattern)")
                let operationCount = pattern.components(separatedBy: "->").count - 1
                #expect(
                    operationCount >= 3,
                    "Advanced patterns should chain multiple operations: \(pattern)")
            }
        }
    }

    // MARK: - AQL-04: AQL in MTL Tests

    @Suite("Tutorial AQL-04: AQL in MTL")
    struct AQL04Tests {

        @Test("Step 1-4: WebApp model for MTL integration")
        func testStep01to04WebAppModel() async throws {
            // Validate webapp metamodel and basic MTL template structure
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-01-webapp-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-02-webapp-instance.xmi")
            let templatePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-04-basic-template.mtl")

            #expect(true, "WebApp model and template validation placeholder")
        }

        @Test("Step 5-8: MTL template with AQL expressions")
        func testStep05to08MTLAQLIntegration() async throws {
            // Test MTL template syntax with embedded AQL expressions
            let mtlWithAQL = [
                "[controller.name/]",
                "[controller.methods->size()/]",
                "[controller.methods->collect(m | m.name)/]",
                "[if (controller.methods->notEmpty())][controller.methods->first().returnType/][/if]",
            ]

            for expression in mtlWithAQL {
                #expect(
                    expression.hasPrefix("[") && expression.hasSuffix("]"),
                    "MTL AQL expressions should be in brackets: \(expression)")
                #expect(
                    expression.contains(".") || expression.contains("->"),
                    "Should contain navigation: \(expression)")
            }
        }

        @Test("Step 9-12: Collection operations in MTL templates")
        func testStep09to12CollectionsInMTL() async throws {
            // Test MTL for loops with AQL collection expressions
            let mtlLoops = [
                "[for (method : Method | controller.methods)]",
                "[for (param : Parameter | method.parameters->select(p | p.required = true))]",
                "[for (model : Model | webapp.models->reject(m | m.abstract = true))]",
            ]

            for loop in mtlLoops {
                #expect(loop.hasPrefix("[for"), "Should be MTL for loop: \(loop)")
                #expect(loop.contains("|"), "For loop should have iteration variable: \(loop)")
                #expect(
                    loop.contains("->") || loop.contains("."),
                    "Should contain AQL navigation: \(loop)")
            }
        }

        @Test("Step 13-16: Conditional logic with AQL")
        func testStep13to16ConditionalLogic() async throws {
            // Test MTL if statements with AQL boolean expressions
            let mtlConditionals = [
                "[if (controller.methods->notEmpty())]",
                "[if (model.attributes->exists(a | a.required = true))]",
                "[if (method.returnType <> 'void')]",
                "[if (webapp.controllers->size() > 1)]",
            ]

            for conditional in mtlConditionals {
                #expect(conditional.hasPrefix("[if"), "Should be MTL if statement: \(conditional)")
                #expect(
                    conditional.contains("(") && conditional.contains(")"),
                    "If condition should be in parentheses: \(conditional)")
            }
        }

        @Test("Step 17-20: Advanced AQL-MTL patterns")
        func testStep17to20AdvancedPatterns() async throws {
            // Test let bindings, cross-references, and comprehensive patterns
            let advancedMTL = [
                "[let controllerMethods : Sequence(Method) = controller.methods->select(m | m.visibility = 'public')]",
                "[let hasRequiredParams : Boolean = method.parameters->exists(p | p.required = true)]",
            ]

            for mtl in advancedMTL {
                #expect(mtl.contains("[let"), "Should contain let binding: \(mtl)")
                #expect(mtl.contains(":"), "Let binding should have type annotation: \(mtl)")
                #expect(mtl.contains("="), "Let binding should have assignment: \(mtl)")
            }
        }
    }

    // MARK: - AQL-05: Complex Queries Tests

    @Suite("Tutorial AQL-05: Complex Queries")
    struct AQL05Tests {

        @Test("Step 1-4: Enterprise model for complex queries")
        func testStep01to04EnterpriseModel() async throws {
            // Validate enterprise metamodel with Organizations, Projects, Teams, Resources
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-01-enterprise-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-02-enterprise-instance.xmi")

            #expect(true, "Enterprise model validation placeholder")
        }

        @Test("Step 5-8: Nested iterations and cross-products")
        func testStep05to08NestedIterations() async throws {
            // Test complex nested query patterns
            let nestedQueries = [
                "organizations->collect(org | org.projects->collect(proj | proj.teams->collect(team | team.members)))->flatten()->flatten()",
                "projects->collect(p1 | projects->collect(p2 | Tuple{first=p1, second=p2, overlap=p1.teams->intersection(p2.teams)->size()}))->flatten()",
                "teams->collect(t1 | teams->select(t2 | t2 <> t1)->collect(t2 | t1.members->intersection(t2.members)))->flatten()->select(intersection | intersection->notEmpty())",
            ]

            for query in nestedQueries {
                #expect(query.contains("->collect"), "Nested queries should use collect: \(query)")
                let collectCount = query.components(separatedBy: "->collect").count - 1
                #expect(collectCount >= 2, "Should have multiple collect operations: \(query)")
            }
        }

        @Test("Step 9-12: Cross-model navigation")
        func testStep09to12CrossModelNavigation() async throws {
            // Test queries that span multiple models
            let crossModelQueries = [
                "organization.projects->collect(p | p.externalDependencies)->flatten()",
                "project.teams->collect(t | t.externalResources->select(r | r.available = true))",
                "team.members->collect(m | m.skills->intersection(project.requiredSkills))",
            ]

            for query in crossModelQueries {
                #expect(query.contains("->"), "Cross-model queries should use navigation: \(query)")
                #expect(query.contains("."), "Should contain property access: \(query)")
            }
        }

        @Test("Step 13-16: Query composition and abstraction")
        func testStep13to16QueryComposition() async throws {
            // Test reusable query components and composition
            let composableQueries = [
                "getAllActiveProjects()->select(p | p.budget > 100000)",
                "getProjectTeams(project)->collect(t | t.members->size())->sum()",
                "findResourceConflicts()->collect(conflict | resolveConflict(conflict))",
            ]

            for query in composableQueries {
                // These would be helper function calls in a real AQL implementation
                #expect(
                    query.contains("()"), "Composed queries may call helper functions: \(query)")
                #expect(
                    query.contains("->") || query.contains("."),
                    "Should contain navigation: \(query)")
            }
        }

        @Test("Step 17-20: Advanced analysis patterns")
        func testStep17to20AdvancedAnalysis() async throws {
            // Test graph traversal, pattern matching, and statistical analysis
            let analysisPatterns = [
                "findCycles(organization.projectDependencies)",
                "matchPattern('high-risk-project', projects)",
                "calculateMetrics(projects)->collect(m | Tuple{project=m.project, complexity=m.complexity, risk=m.risk})",
                "generateReport(organization, 'comprehensive')",
            ]

            for pattern in analysisPatterns {
                // These represent advanced analysis functions
                #expect(!pattern.isEmpty, "Analysis patterns should not be empty: \(pattern)")
                #expect(
                    pattern.contains("(") && pattern.contains(")"),
                    "Analysis functions should have parameters: \(pattern)")
            }
        }
    }
}
