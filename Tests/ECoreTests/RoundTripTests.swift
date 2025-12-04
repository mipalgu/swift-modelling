//
// RoundTripTests.swift
// ECoreTests
//
//  Created by Rene Hexel on 4/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Testing
import Foundation
@testable import ECore

/// Comprehensive round-trip testing for XMI and JSON serialization
///
/// This test suite validates full round-trip compatibility:
/// - XMI → memory → XMI
/// - XMI → memory → JSON → memory → XMI
/// - JSON → memory → XMI → memory → JSON
/// - In-memory model verification at each step
@Suite("Round-Trip Tests")
struct RoundTripTests {

    // MARK: - Helper Methods

    /// Get the URL for the test resources directory
    private func getResourcesURL() throws -> URL {
        guard let bundleResourcesURL = Bundle.module.resourceURL else {
            throw TestError.resourcesNotFound
        }

        let fm = FileManager.default
        let testResourcesURL = bundleResourcesURL.appendingPathComponent("Resources")
        var isDirectory = ObjCBool(false)

        if fm.fileExists(atPath: testResourcesURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return testResourcesURL
        } else {
            return bundleResourcesURL
        }
    }

    /// Test-specific errors
    private enum TestError: Error {
        case resourcesNotFound
        case fileNotFound(String)
    }

    // MARK: - XMI Round-Trip Tests

    /// Test XMI → memory → XMI round-trip with zoo.xmi
    @Test("XMI round-trip: zoo.xmi")
    func testXMIRoundTripZoo() async throws {
        let resourcesURL = try getResourcesURL()
        let inputURL = resourcesURL.appendingPathComponent("xmi").appendingPathComponent("zoo.xmi")

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw TestError.fileNotFound("zoo.xmi")
        }

        // Parse XMI
        let parser = XMIParser()
        let resource1 = try await parser.parse(inputURL)

        // Verify in-memory model
        let roots1 = await resource1.getRootObjects()
        #expect(roots1.count == 1)

        let animal1 = roots1[0] as? DynamicEObject
        #expect(animal1 != nil)

        let name1 = await resource1.eGet(objectId: animal1!.id, feature: "name") as? String
        #expect(name1 == "Fluffy")

        let species1 = await resource1.eGet(objectId: animal1!.id, feature: "species") as? String
        #expect(species1 == "cat")

        // Serialise to XMI
        let serializer = XMISerializer()
        let outputXMI = try await serializer.serialize(resource1)

        // Write to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".xmi")
        try outputXMI.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Parse the serialised XMI
        let resource2 = try await parser.parse(tempURL)

        // Verify round-trip integrity
        let roots2 = await resource2.getRootObjects()
        #expect(roots2.count == 1)

        let animal2 = roots2[0] as? DynamicEObject
        #expect(animal2 != nil)

        let name2 = await resource2.eGet(objectId: animal2!.id, feature: "name") as? String
        #expect(name2 == "Fluffy", "Name should be preserved after round-trip")

        let species2 = await resource2.eGet(objectId: animal2!.id, feature: "species") as? String
        #expect(species2 == "cat", "Species should be preserved after round-trip")
    }

    /// Test XMI → memory → XMI round-trip with team.xmi (containment and cross-references)
    @Test("XMI round-trip: team.xmi with cross-references")
    func testXMIRoundTripTeam() async throws {
        let resourcesURL = try getResourcesURL()
        let inputURL = resourcesURL.appendingPathComponent("xmi").appendingPathComponent("team.xmi")

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw TestError.fileNotFound("team.xmi")
        }

        // Parse XMI
        let parser = XMIParser()
        let resource1 = try await parser.parse(inputURL)

        // Verify in-memory model
        let roots1 = await resource1.getRootObjects()
        #expect(roots1.count == 1)

        let team1 = roots1[0] as? DynamicEObject
        #expect(team1 != nil)

        let teamName1 = await resource1.eGet(objectId: team1!.id, feature: "name") as? String
        #expect(teamName1 == "Engineering")

        let members1 = await resource1.eGet(objectId: team1!.id, feature: "members") as? [EUUID]
        #expect(members1?.count == 3)

        let leaderId1 = await resource1.eGet(objectId: team1!.id, feature: "leader") as? EUUID
        #expect(leaderId1 != nil, "Leader reference should be resolved")
        #expect(leaderId1 == members1?.first, "Leader should reference first member")

        // Serialise to XMI
        let serializer = XMISerializer()
        let outputXMI = try await serializer.serialize(resource1)

        // Write to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".xmi")
        try outputXMI.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Parse the serialised XMI
        let resource2 = try await parser.parse(tempURL)

        // Verify round-trip integrity
        let roots2 = await resource2.getRootObjects()
        #expect(roots2.count == 1)

        let team2 = roots2[0] as? DynamicEObject
        #expect(team2 != nil)

        let teamName2 = await resource2.eGet(objectId: team2!.id, feature: "name") as? String
        #expect(teamName2 == "Engineering", "Team name should be preserved")

        let members2 = await resource2.eGet(objectId: team2!.id, feature: "members") as? [EUUID]
        #expect(members2?.count == 3, "All members should be preserved")

        // Verify member names
        if let firstMemberId = members2?.first {
            let memberName = await resource2.eGet(objectId: firstMemberId, feature: "name") as? String
            #expect(memberName == "Alice", "First member should be Alice")
        }

        let leaderId2 = await resource2.eGet(objectId: team2!.id, feature: "leader") as? EUUID
        #expect(leaderId2 != nil, "Leader reference should be preserved")
        #expect(leaderId2 == members2?.first, "Leader should still reference first member")
    }

    /// Test XMI → memory → XMI round-trip with arbitrary-attributes.xmi (type inference)
    @Test("XMI round-trip: arbitrary-attributes.xmi with type inference")
    func testXMIRoundTripArbitraryAttributes() async throws {
        let resourcesURL = try getResourcesURL()
        let inputURL = resourcesURL.appendingPathComponent("xmi").appendingPathComponent("arbitrary-attributes.xmi")

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw TestError.fileNotFound("arbitrary-attributes.xmi")
        }

        // Parse XMI
        let parser = XMIParser()
        let resource1 = try await parser.parse(inputURL)

        // Verify in-memory model
        let roots1 = await resource1.getRootObjects()
        #expect(roots1.count == 1)

        let record1 = roots1[0] as? DynamicEObject
        #expect(record1 != nil)

        // Verify all attribute types
        let id1 = await resource1.eGet(objectId: record1!.id, feature: "id") as? String
        #expect(id1 == "R001")

        let count1 = await resource1.eGet(objectId: record1!.id, feature: "count") as? Int
        #expect(count1 == 42)

        let ratio1 = await resource1.eGet(objectId: record1!.id, feature: "ratio") as? Double
        #expect(ratio1 == 3.14)

        let active1 = await resource1.eGet(objectId: record1!.id, feature: "active") as? Bool
        #expect(active1 == true)

        let inactive1 = await resource1.eGet(objectId: record1!.id, feature: "inactive") as? Bool
        #expect(inactive1 == false)

        // Serialise to XMI
        let serializer = XMISerializer()
        let outputXMI = try await serializer.serialize(resource1)

        // Write to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".xmi")
        try outputXMI.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Parse the serialised XMI
        let resource2 = try await parser.parse(tempURL)

        // Verify round-trip integrity - types should be preserved
        let roots2 = await resource2.getRootObjects()
        #expect(roots2.count == 1)

        let record2 = roots2[0] as? DynamicEObject
        #expect(record2 != nil)

        let id2 = await resource2.eGet(objectId: record2!.id, feature: "id") as? String
        #expect(id2 == "R001", "String attribute should be preserved")

        let count2 = await resource2.eGet(objectId: record2!.id, feature: "count") as? Int
        #expect(count2 == 42, "Int attribute should be preserved")

        let ratio2 = await resource2.eGet(objectId: record2!.id, feature: "ratio") as? Double
        #expect(ratio2 == 3.14, "Double attribute should be preserved")

        let active2 = await resource2.eGet(objectId: record2!.id, feature: "active") as? Bool
        #expect(active2 == true, "Bool attribute (true) should be preserved")

        let inactive2 = await resource2.eGet(objectId: record2!.id, feature: "inactive") as? Bool
        #expect(inactive2 == false, "Bool attribute (false) should be preserved")
    }

    // MARK: - TODO: Cross-Format Round-Trip Tests
    // These tests require proper integration between XMI and JSON serialization
    // Will be implemented once JSON serialization is refactored to work with Resource
}
