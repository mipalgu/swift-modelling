import Testing
import Foundation

/// Test suite for Ecore Tutorial 06: Querying Models with AQL
/// Validates each step of the AQL query tutorial
@Suite("Tutorial: Querying Models with AQL")
struct Ecore06Tests {

    let tutorialResourcesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")

    // MARK: - Section 1: Introduction to AQL

    @Test("Step 1: Validate starting model with employees")
    func testStep01StartingModel() async throws {
        // Verify we start with the company model from Tutorial 04
        let startingPath = tutorialResourcesPath.appendingPathComponent("step-22-concrete-instances.xmi")

        #expect(FileManager.default.fileExists(atPath: startingPath.path))

        let content = try String(contentsOf: startingPath, encoding: .utf8)

        // Verify Company and employees exist
        #expect(content.contains("company:Company"))
        #expect(content.contains("xsi:type=\"company:Employee\""))
        #expect(content.contains("xsi:type=\"company:Manager\""))

        // Count employees (should be 3)
        let employeeCount = content.components(separatedBy: "<employees").count - 1
        #expect(employeeCount == 3)
    }

    @Test("Step 2: Validate all employees query")
    func testStep02AllEmployeesQuery() async throws {
        // Load the all employees query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-31-all-employees.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query structure
        #expect(content.contains("self.employees"))
    }

    @Test("Step 3: Execute query command exists")
    func testStep03ExecuteQueryCommand() async throws {
        // Load the execute query command script
        let executePath = tutorialResourcesPath.appendingPathComponent("step-32-execute-query.sh")

        #expect(FileManager.default.fileExists(atPath: executePath.path))

        let content = try String(contentsOf: executePath, encoding: .utf8)

        // Verify command structure
        #expect(content.contains("swift-aql"))
        #expect(content.contains("query"))
        #expect(content.contains("company-model.xmi"))
        #expect(content.contains("--query"))
        #expect(content.contains("--context"))
        #expect(content.contains("company1"))
    }

    // MARK: - Section 2: Filtering and Selection

    @Test("Step 4: Validate full-time employees query")
    func testStep04FullTimeEmployeesQuery() async throws {
        // Load the full-time employees query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-33-fulltime-employees.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query uses select operation
        #expect(content.contains("select"))
        #expect(content.contains("e.status"))
        #expect(content.contains("EmploymentStatus::FULL_TIME"))
    }

    @Test("Step 5: Validate employee names query")
    func testStep05EmployeeNamesQuery() async throws {
        // Load the employee names query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-34-employee-names.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query uses collect operation
        #expect(content.contains("collect"))
        #expect(content.contains("e.name"))
    }

    @Test("Step 6: Validate count by status query")
    func testStep06CountByStatusQuery() async throws {
        // Load the count by status query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-35-count-by-status.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query uses let bindings and size
        #expect(content.contains("let fullTime"))
        #expect(content.contains("let partTime"))
        #expect(content.contains("let contractors"))
        #expect(content.contains("->size()"))
        #expect(content.contains("Tuple"))
    }

    // MARK: - Section 3: Navigation and Complex Queries

    @Test("Step 7: Validate engineering managers query")
    func testStep07EngineeringManagersQuery() async throws {
        // Load the engineering managers query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-36-engineering-managers.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query uses type checking and attribute filtering
        #expect(content.contains("oclIsKindOf(Manager)"))
        #expect(content.contains("e.department"))
        #expect(content.contains("Engineering"))
    }

    @Test("Step 8: Validate employee companies navigation query")
    func testStep08EmployeeCompaniesQuery() async throws {
        // Load the employee companies query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-37-employee-companies.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query navigates opposite reference
        #expect(content.contains("self.employer"))
    }

    @Test("Step 9: Validate company stats query")
    func testStep09CompanyStatsQuery() async throws {
        // Load the company stats query
        let queryPath = tutorialResourcesPath.appendingPathComponent("step-38-company-stats.aql")

        #expect(FileManager.default.fileExists(atPath: queryPath.path))

        let content = try String(contentsOf: queryPath, encoding: .utf8)

        // Verify query computes statistics
        #expect(content.contains("let total"))
        #expect(content.contains("let fullTime"))
        #expect(content.contains("let percentage"))
        #expect(content.contains("if total > 0"))
        #expect(content.contains("Tuple"))
    }

    @Test("Step 10: Validate with queries command exists")
    func testStep10ValidateWithQueriesCommand() async throws {
        // Load the validate with queries command script
        let validatePath = tutorialResourcesPath.appendingPathComponent("step-39-validate-with-queries.sh")

        #expect(FileManager.default.fileExists(atPath: validatePath.path))

        let content = try String(contentsOf: validatePath, encoding: .utf8)

        // Verify script structure
        #expect(content.contains("#!/bin/bash"))
        #expect(content.contains("swift-aql query"))
        #expect(content.contains("managers_count"))
        #expect(content.contains("fulltime_managers"))
        #expect(content.contains("All managers are full-time"))
    }

    // MARK: - Comprehensive Validation

    @Test("Tutorial completeness: All steps present")
    func testTutorialCompleteness() async throws {
        // Verify all tutorial files exist
        let steps = [
            "step-22-concrete-instances.xmi",  // Starting point
            "step-31-all-employees.aql",
            "step-32-execute-query.sh",
            "step-33-fulltime-employees.aql",
            "step-34-employee-names.aql",
            "step-35-count-by-status.aql",
            "step-36-engineering-managers.aql",
            "step-37-employee-companies.aql",
            "step-38-company-stats.aql",
            "step-39-validate-with-queries.sh"
        ]

        for step in steps {
            let path = tutorialResourcesPath.appendingPathComponent(step)
            #expect(FileManager.default.fileExists(atPath: path.path), "Missing file: \(step)")
        }
    }

    @Test("Query progression: Simple → Filtering → Complex")
    func testQueryProgression() async throws {
        // Step 1: Simple navigation
        let step1 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-31-all-employees.aql"), encoding: .utf8)
        #expect(step1.contains("self.employees"))
        #expect(!step1.contains("select"))
        #expect(!step1.contains("collect"))

        // Step 2: Filtering with select
        let step2 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-33-fulltime-employees.aql"), encoding: .utf8)
        #expect(step2.contains("select"))

        // Step 3: Transformation with collect
        let step3 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-34-employee-names.aql"), encoding: .utf8)
        #expect(step3.contains("collect"))

        // Step 4: Complex query with let bindings
        let step4 = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-35-count-by-status.aql"), encoding: .utf8)
        #expect(step4.contains("let"))
        #expect(step4.contains("Tuple"))
    }

    @Test("Collection operations validation")
    func testCollectionOperations() async throws {
        // Load queries that use different collection operations
        let selectQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-33-fulltime-employees.aql"), encoding: .utf8)
        let collectQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-34-employee-names.aql"), encoding: .utf8)
        let sizeQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-35-count-by-status.aql"), encoding: .utf8)

        // Verify select uses arrow syntax and lambda
        #expect(selectQuery.contains("->select("))
        #expect(selectQuery.contains(" | "))

        // Verify collect uses arrow syntax and lambda
        #expect(collectQuery.contains("->collect("))
        #expect(collectQuery.contains(" | "))

        // Verify size is called on collections
        #expect(sizeQuery.contains("->size()"))
    }

    @Test("AQL syntax patterns validation")
    func testAQLSyntaxPatterns() async throws {
        let queries = [
            "step-33-fulltime-employees.aql",
            "step-34-employee-names.aql",
            "step-35-count-by-status.aql",
            "step-36-engineering-managers.aql",
            "step-38-company-stats.aql"
        ]

        for queryFile in queries {
            let path = tutorialResourcesPath.appendingPathComponent(queryFile)
            let content = try String(contentsOf: path, encoding: .utf8)

            // All complex queries should use self or lambda variables
            let usesSelf = content.contains("self.")
            let usesLambda = content.contains(" | ")
            let usesLet = content.contains("let ")

            // At least one pattern should be present
            #expect(usesSelf || usesLambda || usesLet, "Query \(queryFile) doesn't follow AQL patterns")
        }
    }

    @Test("Query context and navigation validation")
    func testQueryContextAndNavigation() async throws {
        // Verify queries use appropriate context
        let companyQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-31-all-employees.aql"), encoding: .utf8)
        let employeeQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-37-employee-companies.aql"), encoding: .utf8)

        // Company-context query navigates to employees
        #expect(companyQuery.contains("self.employees"))

        // Employee-context query navigates to employer (opposite reference)
        #expect(employeeQuery.contains("self.employer"))
    }

    @Test("Advanced query features validation")
    func testAdvancedQueryFeatures() async throws {
        // Load queries with advanced features
        let typeCheckQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-36-engineering-managers.aql"), encoding: .utf8)
        let statsQuery = try String(contentsOf: tutorialResourcesPath.appendingPathComponent("step-38-company-stats.aql"), encoding: .utf8)

        // Verify type checking
        #expect(typeCheckQuery.contains("oclIsKindOf(Manager)"))

        // Verify conditional logic
        #expect(statsQuery.contains("if"))
        #expect(statsQuery.contains("then"))
        #expect(statsQuery.contains("else"))
        #expect(statsQuery.contains("endif"))

        // Verify arithmetic operations
        #expect(statsQuery.contains("* 100"))
        #expect(statsQuery.contains("/ total"))
    }
}
