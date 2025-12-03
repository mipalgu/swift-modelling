//
// EPackageTests.swift
// ECore
//
//  Created by Rene Hexel on 3/12/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Testing
@testable import ECore
import Foundation

// MARK: - Test Constants

private let companyPackageName = "company"
private let companyNsURI = "http://example.org/company"
private let companyNsPrefix = "comp"

private let employeeClassName = "Employee"
private let departmentClassName = "Department"
private let stringTypeName = "EString"
private let birdEnumName = "BirdType"

private let hrSubpackageName = "hr"
private let financeSubpackageName = "finance"

// MARK: - EPackage Creation Tests

@Test func testEPackageCreation() {
    let package = EPackage(name: companyPackageName)

    #expect(package.name == companyPackageName)
    #expect(package.nsURI == "")
    #expect(package.nsPrefix == "")
    #expect(package.eClassifiers.isEmpty)
    #expect(package.eSubpackages.isEmpty)
    #expect(package.eAnnotations.isEmpty)
}

@Test func testEPackageWithNamespace() {
    let package = EPackage(
        name: companyPackageName,
        nsURI: companyNsURI,
        nsPrefix: companyNsPrefix
    )

    #expect(package.nsURI == companyNsURI)
    #expect(package.nsPrefix == companyNsPrefix)
}

@Test func testEPackageWithClassifiers() {
    let employeeClass = EClass(name: employeeClassName)
    let departmentClass = EClass(name: departmentClassName)

    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass, departmentClass]
    )

    #expect(package.eClassifiers.count == 2)
}

@Test func testEPackageWithMixedClassifiers() {
    let employeeClass = EClass(name: employeeClassName)
    let stringType = EDataType(name: stringTypeName)
    let birdEnum = EEnum(name: birdEnumName)

    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass, stringType, birdEnum]
    )

    #expect(package.eClassifiers.count == 3)
}

@Test func testEPackageWithSubpackages() {
    let hrPackage = EPackage(name: hrSubpackageName)
    let financePackage = EPackage(name: financeSubpackageName)

    let package = EPackage(
        name: companyPackageName,
        eSubpackages: [hrPackage, financePackage]
    )

    #expect(package.eSubpackages.count == 2)
}

@Test func testEPackageWithAnnotations() {
    let annotation = EAnnotation(
        source: "http://www.eclipse.org/emf/2002/GenModel",
        details: ["documentation": "Company package for HR and payroll"]
    )

    let package = EPackage(
        name: companyPackageName,
        eAnnotations: [annotation]
    )

    #expect(package.eAnnotations.count == 1)
    let found = package.getEAnnotation(source: "http://www.eclipse.org/emf/2002/GenModel")
    #expect(found?.details["documentation"] == "Company package for HR and payroll")
}

// MARK: - Classifier Lookup Tests

@Test func testGetClassifier() {
    let employeeClass = EClass(name: employeeClassName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass]
    )

    let found = package.getClassifier(employeeClassName)
    #expect(found != nil)
    #expect((found as? EClass)?.name == employeeClassName)
}

@Test func testGetClassifierNotFound() {
    let package = EPackage(name: companyPackageName)

    let found = package.getClassifier("NonExistent")
    #expect(found == nil)
}

@Test func testGetEClass() {
    let employeeClass = EClass(name: employeeClassName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass]
    )

    let found = package.getEClass(employeeClassName)
    #expect(found != nil)
    #expect(found?.name == employeeClassName)
}

@Test func testGetEClassNotFound() {
    let stringType = EDataType(name: stringTypeName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [stringType]
    )

    // DataType exists but we're looking for a class
    let found = package.getEClass(stringTypeName)
    #expect(found == nil)
}

@Test func testGetEDataType() {
    let stringType = EDataType(name: stringTypeName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [stringType]
    )

    let found = package.getEDataType(stringTypeName)
    #expect(found != nil)
    #expect(found?.name == stringTypeName)
}

@Test func testGetEDataTypeNotFound() {
    let employeeClass = EClass(name: employeeClassName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass]
    )

    // Class exists but we're looking for a data type
    let found = package.getEDataType(employeeClassName)
    #expect(found == nil)
}

@Test func testGetEEnum() {
    let birdEnum = EEnum(name: birdEnumName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [birdEnum]
    )

    let found = package.getEEnum(birdEnumName)
    #expect(found != nil)
    #expect(found?.name == birdEnumName)
}

@Test func testGetEEnumNotFound() {
    let employeeClass = EClass(name: employeeClassName)
    let package = EPackage(
        name: companyPackageName,
        eClassifiers: [employeeClass]
    )

    // Class exists but we're looking for an enum
    let found = package.getEEnum(employeeClassName)
    #expect(found == nil)
}

// MARK: - Subpackage Lookup Tests

@Test func testGetSubpackage() {
    let hrPackage = EPackage(name: hrSubpackageName)
    let package = EPackage(
        name: companyPackageName,
        eSubpackages: [hrPackage]
    )

    let found = package.getSubpackage(hrSubpackageName)
    #expect(found != nil)
    #expect(found?.name == hrSubpackageName)
}

@Test func testGetSubpackageNotFound() {
    let package = EPackage(name: companyPackageName)

    let found = package.getSubpackage("nonexistent")
    #expect(found == nil)
}

// MARK: - Equality and Hashing Tests

@Test func testEPackageEquality() {
    let id = EUUID()
    let package1 = EPackage(id: id, name: companyPackageName)
    let package2 = EPackage(id: id, name: companyPackageName)

    #expect(package1 == package2)
    #expect(package1.hashValue == package2.hashValue)
}

@Test func testEPackageInequality() {
    let package1 = EPackage(name: companyPackageName)
    let package2 = EPackage(name: "other")

    #expect(package1 != package2)
}

@Test func testEPackageEqualityIgnoresContent() {
    let id = EUUID()
    let employeeClass = EClass(name: employeeClassName)

    let package1 = EPackage(id: id, name: companyPackageName)
    let package2 = EPackage(
        id: id,
        name: "different",
        eClassifiers: [employeeClass]
    )

    // Same ID means equal, even with different content
    #expect(package1 == package2)
}

// MARK: - Protocol Tests

@Test func testEPackageIsENamedElement() {
    let package = EPackage(name: companyPackageName)
    let namedElement: any ENamedElement = package

    #expect(namedElement is EPackage)
    #expect(namedElement.name == companyPackageName)
}

@Test func testEPackageIsEcoreValue() {
    let package = EPackage(name: companyPackageName)
    let value: any EcoreValue = package

    #expect(value is EPackage)
}

@Test func testEPackageHasMetaclass() {
    let package = EPackage(name: companyPackageName)

    #expect(package.eClass.name == "EPackage")
}

// MARK: - Integration Tests

@Test func testCompanyMetamodelPackage() {
    // Create a realistic company metamodel package
    let stringType = EDataType(name: "EString")
    let intType = EDataType(name: "EInt")

    let nameAttr = EAttribute(name: "name", eType: stringType)
    let ageAttr = EAttribute(name: "age", eType: intType)

    let employeeClass = EClass(
        name: employeeClassName,
        eStructuralFeatures: [nameAttr, ageAttr]
    )

    let departmentClass = EClass(name: departmentClassName)

    let package = EPackage(
        name: companyPackageName,
        nsURI: companyNsURI,
        nsPrefix: companyNsPrefix,
        eClassifiers: [stringType, intType, employeeClass, departmentClass]
    )

    // Verify package structure
    #expect(package.eClassifiers.count == 4)
    #expect(package.getEClass(employeeClassName) != nil)
    #expect(package.getEClass(departmentClassName) != nil)
    #expect(package.getEDataType("EString") != nil)
    #expect(package.getEDataType("EInt") != nil)

    // Verify class structure
    let foundEmployee = package.getEClass(employeeClassName)
    #expect(foundEmployee?.allAttributes.count == 2)
}

@Test func testNestedPackages() {
    // Create nested package structure
    let hrClass = EClass(name: "HRRecord")
    let hrPackage = EPackage(
        name: hrSubpackageName,
        eClassifiers: [hrClass]
    )

    let financeClass = EClass(name: "Ledger")
    let financePackage = EPackage(
        name: financeSubpackageName,
        eClassifiers: [financeClass]
    )

    let rootPackage = EPackage(
        name: companyPackageName,
        nsURI: companyNsURI,
        eSubpackages: [hrPackage, financePackage]
    )

    // Verify structure
    #expect(rootPackage.eSubpackages.count == 2)

    let foundHR = rootPackage.getSubpackage(hrSubpackageName)
    #expect(foundHR != nil)
    #expect(foundHR?.getEClass("HRRecord") != nil)

    let foundFinance = rootPackage.getSubpackage(financeSubpackageName)
    #expect(foundFinance != nil)
    #expect(foundFinance?.getEClass("Ledger") != nil)
}

// MARK: - EFactory Tests

@Test func testEFactoryCreation() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    #expect(factory.name == "CompanyFactory")
    #expect(factory.ePackage.name == companyPackageName)
}

@Test func testEFactoryWithCustomName() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(name: "CustomFactory", ePackage: package)

    #expect(factory.name == "CustomFactory")
}

@Test func testEFactoryCreate() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    let employeeClass = EClass(name: employeeClassName)
    let instance = factory.create(employeeClass)

    #expect(instance.eClass.name == employeeClassName)
    #expect(instance.id != EUUID())  // Has a valid ID
}

@Test func testEFactoryCreateFromString() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    let intType = EDataType(name: "EInt")
    let value = factory.createFromString(intType, "42")

    #expect(value as? Int == 42)
}

@Test func testEFactoryCreateFromStringTypes() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    // Test various type conversions
    let stringValue = factory.createFromString(
        EDataType(name: "EString"),
        "hello"
    )
    #expect(stringValue as? String == "hello")

    let boolValue = factory.createFromString(
        EDataType(name: "EBoolean"),
        "true"
    )
    #expect(boolValue as? Bool == true)

    let floatValue = factory.createFromString(
        EDataType(name: "EFloat"),
        "3.14"
    )
    #expect(floatValue as? Float == 3.14)

    let doubleValue = factory.createFromString(
        EDataType(name: "EDouble"),
        "2.718"
    )
    #expect(doubleValue as? Double == 2.718)
}

@Test func testEFactoryCreateFromStringInvalid() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    let intType = EDataType(name: "EInt")
    let value = factory.createFromString(intType, "not a number")

    #expect(value == nil)  // Conversion should fail
}

@Test func testEFactoryConvertToString() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    let intType = EDataType(name: "EInt")
    let literal = factory.convertToString(intType, 42 as EInt)

    #expect(literal == "42")
}

@Test func testEFactoryConvertToStringTypes() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    // Test various type conversions
    let stringLiteral = factory.convertToString(
        EDataType(name: "EString"),
        "hello" as EString
    )
    #expect(stringLiteral == "hello")

    let boolLiteral = factory.convertToString(
        EDataType(name: "EBoolean"),
        true as EBoolean
    )
    #expect(boolLiteral == "true")

    let intLiteral = factory.convertToString(
        EDataType(name: "EInt"),
        42 as EInt
    )
    #expect(intLiteral == "42")
}

@Test func testEFactoryRoundTrip() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    let intType = EDataType(name: "EInt")
    let originalValue = 42 as EInt

    // Convert to string and back
    let literal = factory.convertToString(intType, originalValue)
    let reconstructedValue = factory.createFromString(intType, literal)

    #expect(reconstructedValue as? Int == originalValue)
}

@Test func testEFactoryEquality() {
    let package = EPackage(name: companyPackageName)
    let id = EUUID()

    let factory1 = EFactory(id: id, ePackage: package)
    let factory2 = EFactory(id: id, ePackage: package)

    #expect(factory1 == factory2)
    #expect(factory1.hashValue == factory2.hashValue)
}

@Test func testEFactoryInequality() {
    let package1 = EPackage(name: companyPackageName)
    let package2 = EPackage(name: "other")

    let factory1 = EFactory(ePackage: package1)
    let factory2 = EFactory(ePackage: package2)

    #expect(factory1 != factory2)
}

@Test func testEFactoryIsENamedElement() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)
    let namedElement: any ENamedElement = factory

    #expect(namedElement is EFactory)
    #expect(namedElement.name == "CompanyFactory")
}

@Test func testEFactoryIsEcoreValue() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)
    let value: any EcoreValue = factory

    #expect(value is EFactory)
}

@Test func testEFactoryHasMetaclass() {
    let package = EPackage(name: companyPackageName)
    let factory = EFactory(ePackage: package)

    #expect(factory.eClass.name == "EFactory")
}

// MARK: - DynamicEObject Tests

@Test func testDynamicEObjectCreation() {
    let employeeClass = EClass(name: employeeClassName)
    let obj = DynamicEObject(eClass: employeeClass)

    #expect(obj.eClass.name == employeeClassName)
    #expect(obj.id != EUUID())
}

@Test func testDynamicEObjectSetAndGet() {
    let stringType = EDataType(name: "EString")
    let nameAttr = EAttribute(name: "name", eType: stringType)
    let employeeClass = EClass(
        name: employeeClassName,
        eStructuralFeatures: [nameAttr]
    )

    var obj = DynamicEObject(eClass: employeeClass)
    obj.eSet(nameAttr, "Alice" as EString)

    let value = obj.eGet(nameAttr)
    #expect(value as? String == "Alice")
}

@Test func testDynamicEObjectIsSet() {
    let stringType = EDataType(name: "EString")
    let nameAttr = EAttribute(name: "name", eType: stringType)
    let employeeClass = EClass(name: employeeClassName)

    var obj = DynamicEObject(eClass: employeeClass)

    #expect(obj.eIsSet(nameAttr) == false)

    obj.eSet(nameAttr, "Alice" as EString)
    #expect(obj.eIsSet(nameAttr) == true)
}

@Test func testDynamicEObjectUnset() {
    let stringType = EDataType(name: "EString")
    let nameAttr = EAttribute(name: "name", eType: stringType)
    let employeeClass = EClass(name: employeeClassName)

    var obj = DynamicEObject(eClass: employeeClass)
    obj.eSet(nameAttr, "Alice" as EString)

    obj.eUnset(nameAttr)
    #expect(obj.eIsSet(nameAttr) == false)
    #expect(obj.eGet(nameAttr) == nil)
}

@Test func testDynamicEObjectEquality() {
    let employeeClass = EClass(name: employeeClassName)
    let id = EUUID()

    let obj1 = DynamicEObject(id: id, eClass: employeeClass)
    let obj2 = DynamicEObject(id: id, eClass: employeeClass)

    #expect(obj1 == obj2)
    #expect(obj1.hashValue == obj2.hashValue)
}

@Test func testDynamicEObjectInequality() {
    let employeeClass = EClass(name: employeeClassName)

    let obj1 = DynamicEObject(eClass: employeeClass)
    let obj2 = DynamicEObject(eClass: employeeClass)

    #expect(obj1 != obj2)
}
