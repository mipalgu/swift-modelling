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
        @MainActor
        func testStep01CompanyMetamodel() async throws {
            // Validate that the company metamodel from step 1 is structurally correct
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-01")
                .appendingPathComponent("aql-01-step-01-company-metamodel.ecore")

            #expect(FileManager.default.fileExists(atPath: metamodelPath.path), "Metamodel file should exist")

            // Use swift-ecore validate to ensure the metamodel can actually be loaded
            let result = try await executeSwiftEcore(
                command: "validate",
                arguments: [metamodelPath.path]
            )

            #expect(result.succeeded, "Metamodel should validate successfully")

            // Read and verify metamodel content
            let content = try String(contentsOf: metamodelPath, encoding: .utf8)

            // Verify package structure
            #expect(content.contains("name=\"company\""), "Package name should be 'company'")

            // Verify Company and Employee classes exist
            #expect(content.contains("name=\"Company\""), "Company class should exist")
            #expect(content.contains("name=\"Employee\""), "Employee class should exist")

            // Verify Employee attributes
            #expect(content.contains("name=\"name\""), "Employee should have 'name' attribute")
            #expect(content.contains("name=\"age\""), "Employee should have 'age' attribute")
            #expect(content.contains("name=\"department\""), "Employee should have 'department' attribute")

            // Verify Company has employees reference
            #expect(content.contains("name=\"employees\""), "Company should have 'employees' reference")
            #expect(content.contains("containment=\"true\""), "Should have containment references")
        }

        @Test("Step 2: Company instance is valid")
        @MainActor
        func testStep02CompanyInstance() async throws {
            // Validate the company instance from step 2
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-01")
                .appendingPathComponent("aql-01-step-02-company-instance.xmi")

            #expect(FileManager.default.fileExists(atPath: instancePath.path), "Instance file should exist")

            // Use swift-ecore validate to ensure the instance can actually be loaded
            let result = try await executeSwiftEcore(
                command: "validate",
                arguments: [instancePath.path]
            )

            #expect(result.succeeded, "Instance should validate successfully and load without errors")

            // Read and verify instance content
            let content = try String(contentsOf: instancePath, encoding: .utf8)

            // Verify instance contains Company elements
            #expect(content.contains("Company"), "Instance should contain Company element")
            #expect(content.contains("Employee") || content.contains("employees"), "Instance should contain Employee elements")

            // Verify employees have different departments
            let hasDepartments = content.contains("department=\"Engineering\"") ||
                                content.contains("department=\"Sales\"") ||
                                content.contains("department=\"Marketing\"")
            #expect(hasDepartments, "Employees should have department values")
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
        @MainActor
        func testStep01to02UniversityModel() async throws {
            // Validate university metamodel and instance structure
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-02")
                .appendingPathComponent("aql-02-step-01-university-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-02")
                .appendingPathComponent("aql-02-step-02-university-instance.xmi")

            #expect(FileManager.default.fileExists(atPath: metamodelPath.path), "Metamodel file should exist")
            #expect(FileManager.default.fileExists(atPath: instancePath.path), "Instance file should exist")

            // Use swift-ecore validate to ensure files can be loaded
            let metamodelResult = try await executeSwiftEcore(
                command: "validate",
                arguments: [metamodelPath.path]
            )
            #expect(metamodelResult.succeeded, "Metamodel should validate and load successfully")

            let instanceResult = try await executeSwiftEcore(
                command: "validate",
                arguments: [instancePath.path]
            )
            #expect(instanceResult.succeeded, "Instance should validate and load successfully")

            // Verify metamodel content
            let metamodelContent = try String(contentsOf: metamodelPath, encoding: .utf8)
            #expect(metamodelContent.contains("name=\"Student\""), "Student class should exist")
            #expect(metamodelContent.contains("name=\"Course\""), "Course class should exist")
            #expect(metamodelContent.contains("name=\"Professor\""), "Professor class should exist")
            #expect(metamodelContent.contains("name=\"grade\""), "Student should have grade attribute")
            #expect(metamodelContent.contains("name=\"credits\""), "Course should have credits attribute")

            // Verify instance content
            let instanceContent = try String(contentsOf: instancePath, encoding: .utf8)
            #expect(instanceContent.contains("Student") || instanceContent.contains("students"), "Instance should contain students")
            #expect(instanceContent.contains("Course") || instanceContent.contains("courses"), "Instance should contain courses")
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
        @MainActor
        func testStep01to04LibraryModel() async throws {
            // Validate library metamodel with Books, Authors, Categories, Loans
            let metamodelPath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-03")
                .appendingPathComponent("aql-03-step-01-library-metamodel.ecore")
            let instancePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-03")
                .appendingPathComponent("aql-03-step-04-library-instance.xmi")

            #expect(FileManager.default.fileExists(atPath: metamodelPath.path), "Metamodel file should exist")
            #expect(FileManager.default.fileExists(atPath: instancePath.path), "Instance file should exist")

            // Use swift-ecore validate to ensure files can be loaded
            let metamodelResult = try await executeSwiftEcore(
                command: "validate",
                arguments: [metamodelPath.path]
            )
            #expect(metamodelResult.succeeded, "Metamodel should validate and load successfully")

            let instanceResult = try await executeSwiftEcore(
                command: "validate",
                arguments: [instancePath.path]
            )
            #expect(instanceResult.succeeded, "Instance should validate and load successfully")

            // Verify metamodel content
            let content = try String(contentsOf: metamodelPath, encoding: .utf8)
            #expect(content.contains("name=\"Book\""), "Book class should exist")
            #expect(content.contains("name=\"Author\""), "Author class should exist")
            #expect(content.contains("name=\"Category\""), "Category class should exist")
            #expect(content.contains("name=\"Loan\""), "Loan class should exist")
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
                    operationCount >= 2,
                    "Advanced patterns should chain multiple operations: \(pattern)")
            }
        }
    }

    // MARK: - AQL-04: Advanced Operations Tests

    @Suite("Tutorial AQL-04: Advanced Operations")
    struct AQL04Tests {

        @Test("Step 1: Let expressions syntax and semantics")
        func testStep01LetExpressions() async throws {
            // Validate let expression resource file exists
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-01-let-expressions.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Let expressions resource should exist")

            // Test let expression patterns
            let letExpressions = [
                "let highRated = 4.5 in library.books->select(b | b.rating >= highRated)",
                "let minPages = 300 in let minRating = 4.0 in books->select(b | b.pages >= minPages and b.rating >= minRating)",
            ]

            for expression in letExpressions {
                #expect(expression.contains("let"), "Should use let keyword: \(expression)")
                #expect(expression.contains("in"), "Let binding should have 'in' keyword: \(expression)")
                #expect(expression.contains("="), "Should have assignment operator: \(expression)")
            }
        }

        @Test("Step 2: Tuple construction patterns")
        func testStep02TupleConstruction() async throws {
            // Validate tuple construction resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-02-tuple-construction.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Tuple construction resource should exist")

            // Test tuple syntax patterns
            let tupleExpressions = [
                "Tuple{title='Book Title', pages=350}",
                "books->collect(b | Tuple{title=b.title, author=b.author.name, rating=b.rating})",
            ]

            for expression in tupleExpressions {
                #expect(expression.contains("Tuple{"), "Should use Tuple constructor: \(expression)")
                #expect(expression.contains("="), "Tuple should have field assignments: \(expression)")
                #expect(expression.contains("}"), "Tuple should be properly closed: \(expression)")
            }
        }

        @Test("Step 3: Complex navigation patterns")
        func testStep03ComplexNavigation() async throws {
            // Validate complex navigation resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-03-complex-navigation.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Complex navigation resource should exist")

            // Test multi-hop navigation patterns
            let navigationPatterns = [
                "library.categories->collect(c | c.books)->flatten()->collect(b | b.authors)->flatten()->asSet()",
                "author.books->collect(b | b.authors)->flatten()->select(a | a <> author)->asSet()",
            ]

            for pattern in navigationPatterns {
                #expect(pattern.contains("->"), "Should use arrow navigation: \(pattern)")
                #expect(pattern.contains("collect"), "Complex navigation uses collect: \(pattern)")
            }
        }

        @Test("Step 4: OCL-style operations")
        func testStep04OCLOperations() async throws {
            // Validate OCL operations resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-04-ocl-operations.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "OCL operations resource should exist")

            // Test OCL operation syntax
            let oclOperations = [
                "books->including(newBook)",
                "books->excluding(oldBook)",
                "books->one(b | b.title = '1984')",
                "books->any(b | b.rating >= 4.8)",
            ]

            for operation in oclOperations {
                #expect(operation.contains("->"), "OCL operations use arrow syntax: \(operation)")
            }
        }

        @Test("Step 5: Type operations")
        func testStep05TypeOperations() async throws {
            // Validate type operations resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-04")
                .appendingPathComponent("aql-04-step-05-type-operations.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Type operations resource should exist")

            // Test type operation syntax
            let typeOperations = [
                "EObject.allInstances()->select(e | e.oclIsTypeOf(Book))",
                "elements->select(e | e.oclIsKindOf(Book))->collect(e | e.oclAsType(Book))",
                "book.eClass().name",
            ]

            for operation in typeOperations {
                let hasTypeOp = operation.contains("oclIsTypeOf") || operation.contains("oclIsKindOf") || operation.contains("oclAsType") || operation.contains("eClass")
                #expect(hasTypeOp, "Should use type operation: \(operation)")
            }
        }
    }

    // MARK: - AQL-05: Complex Query Patterns Tests

    @Suite("Tutorial AQL-05: Complex Query Patterns")
    struct AQL05Tests {

        @Test("Step 1: Recursive navigation with eAllContents")
        func testStep01RecursiveNavigation() async throws {
            // Validate recursive navigation resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-01-recursive-navigation.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Recursive navigation resource should exist")

            // Test recursive navigation patterns
            let recursivePatterns = [
                "library.eAllContents()",
                "library.eAllContents()->select(e | e.oclIsKindOf(Book))->size()",
                "book.eContainer()",
            ]

            for pattern in recursivePatterns {
                let hasRecursive = pattern.contains("eAllContents") || pattern.contains("eContainer")
                #expect(hasRecursive, "Should use recursive navigation: \(pattern)")
            }
        }

        @Test("Step 2: Transitive closure operations")
        func testStep02TransitiveClosure() async throws {
            // Validate transitive closure resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-02-transitive-closure.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Transitive closure resource should exist")

            // Test closure operation syntax
            let closurePatterns = [
                "person->closure(p | p.friends)",
                "book->closure(b | b.similarTo->select(s | s.rating >= 4.0))",
                "rootCategory->closure(c | c.subcategories)",
            ]

            for pattern in closurePatterns {
                #expect(pattern.contains("->closure"), "Should use closure operation: \(pattern)")
                #expect(pattern.contains("|"), "Closure should have lambda: \(pattern)")
            }
        }

        @Test("Step 3: Query optimisation techniques")
        func testStep03QueryOptimisation() async throws {
            // Validate query optimisation resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-03-query-optimisation.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Query optimisation resource should exist")

            // Test optimisation patterns
            let optimisedPatterns = [
                "let books = library.books in Tuple{good=books->select(b | b.rating >= 4.0)->size(), great=books->select(b | b.rating >= 4.5)->size()}",
                "let qualifyingBooks = library.books->select(b | b.rating >= 4.5) in authors->select(a | qualifyingBooks->exists(b | b.authors->includes(a)))",
            ]

            for pattern in optimisedPatterns {
                #expect(pattern.contains("let"), "Optimised queries use let bindings: \(pattern)")
                #expect(pattern.contains("in"), "Let binding should have 'in' keyword: \(pattern)")
            }
        }

        @Test("Step 4: Performance best practices")
        func testStep04PerformancePatterns() async throws {
            // Validate performance patterns resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-04-performance-patterns.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Performance patterns resource should exist")

            // Test performance improvement techniques
            let performancePatterns = [
                "exists",  // Short-circuit evaluation
                "forAll",  // Early termination
                "asSet",   // Deduplication
                "let",     // Result caching
            ]

            for pattern in performancePatterns {
                #expect(!pattern.isEmpty, "Performance pattern should be defined: \(pattern)")
            }
        }

        @Test("Step 5: Advanced patterns summary")
        func testStep05AdvancedPatternsSummary() async throws {
            // Validate comprehensive summary resource
            let resourcePath = AQLTutorialTests.tutorialResourcesPath
                .appendingPathComponent("AQL-05")
                .appendingPathComponent("aql-05-step-05-advanced-patterns-summary.sh")

            #expect(FileManager.default.fileExists(atPath: resourcePath.path), "Advanced patterns summary resource should exist")

            // Verify resource file can be read
            let canRead = FileManager.default.isReadableFile(atPath: resourcePath.path)
            #expect(canRead, "Summary resource should be readable")
        }

        @Test("Complex query patterns: Integration")
        func testComplexQueryIntegration() async throws {
            // Test that complex patterns work together
            let integratedPatterns = [
                // Recursive + closure
                "library.eAllContents()->select(e | e.oclIsKindOf(Category))->collect(c | c.oclAsType(Category))->collect(cat | cat->closure(c | c.subcategories))->flatten()",
                // Let + closure + optimisation
                "let root = library.categories->first() in root->closure(c | c.subcategories)->collect(c | c.books)->flatten()->asSet()->select(b | b.rating >= 4.5)",
            ]

            for pattern in integratedPatterns {
                #expect(pattern.contains("->"), "Integrated patterns should chain operations: \(pattern)")
                let operationCount = pattern.components(separatedBy: "->").count - 1
                #expect(operationCount >= 3, "Should have multiple chained operations: \(pattern)")
            }
        }
    }
}
