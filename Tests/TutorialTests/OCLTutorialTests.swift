import Testing
import Foundation

/// Test suite for OCL Tutorial: Constraints and Validation
/// Validates OCL constraint definitions and model validation
@Suite("Tutorial: OCL Constraints and Validation")
struct OCLTutorialTests {

    static let tutorialCodePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")
        .appendingPathComponent("SwiftModelling")
        .appendingPathComponent("SwiftModelling.docc")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Code")
        .appendingPathComponent("OCL-Tutorial-01")

    // MARK: - Section 1: CLI Validation

    @Test("CLI: Validate bank metamodel via swift-ecore")
    @MainActor
    func testCLIValidateBankMetamodel() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")

        #expect(FileManager.default.fileExists(atPath: metamodelPath.path), "Bank metamodel should exist")

        // Use swift-ecore validate to ensure the metamodel can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [metamodelPath.path]
        )

        #expect(result.succeeded, "Bank metamodel should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate valid bank instance via swift-ecore")
    @MainActor
    func testCLIValidateValidInstance() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path), "Valid bank instance should exist")

        // Use swift-ecore validate to ensure the model can be loaded
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [instancePath.path]
        )

        #expect(result.succeeded, "Valid bank instance should validate successfully: \(result.stderr)")
    }

    @Test("CLI: Validate invalid bank instance via swift-ecore")
    @MainActor
    func testCLIValidateInvalidInstance() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path), "Invalid bank instance should exist")

        // Use swift-ecore validate - this should still load (syntactically valid XMI)
        // OCL constraints would be validated by a separate OCL validator
        let result = try await executeSwiftEcore(
            command: "validate",
            arguments: [instancePath.path]
        )

        // The file is syntactically valid XMI, so it should load
        #expect(result.succeeded, "Invalid instance should be syntactically valid XMI: \(result.stderr)")
    }

    // MARK: - Section 2: Validate Metamodel Structure

    @Test("Step 1.1: Validate bank metamodel exists")
    func testStep01ValidateMetamodelExists() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")

        #expect(FileManager.default.fileExists(atPath: metamodelPath.path))

        let content = try String(contentsOf: metamodelPath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("ecore:EPackage"))
        #expect(content.contains("name=\"Bank\""))
        #expect(content.contains("nsURI=\"http://www.example.org/bank\""))
    }

    @Test("Step 1.2: Validate metamodel classes")
    func testStep02ValidateMetamodelClasses() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Verify all classes exist
        #expect(content.contains("name=\"Bank\""))
        #expect(content.contains("name=\"Customer\""))
        #expect(content.contains("name=\"Account\""))
        #expect(content.contains("name=\"Transaction\""))

        // Verify enums
        #expect(content.contains("name=\"AccountType\""))
        #expect(content.contains("name=\"TransactionType\""))
    }

    // MARK: - Section 2: Validate OCL Invariant Constraints

    @Test("Step 2.1: Validate Bank invariant constraints")
    func testStep03ValidateBankInvariants() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Bank constraints
        #expect(content.contains("uniqueAccountNumbers"))
        #expect(content.contains("uniqueCustomerIds"))

        // OCL expressions
        #expect(content.contains("self.accounts->isUnique(accountNumber)"))
        #expect(content.contains("self.customers->isUnique(customerId)"))
    }

    @Test("Step 2.2: Validate Customer invariant constraints")
    func testStep04ValidateCustomerInvariants() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Customer constraints
        #expect(content.contains("validEmail"))
        #expect(content.contains("adultCustomer"))

        // OCL expressions
        #expect(content.contains("self.email.indexOf('@') > 0"))
        #expect(content.contains("self.age >= 18"))
    }

    @Test("Step 2.3: Validate Account invariant constraints")
    func testStep05ValidateAccountInvariants() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Account constraints
        #expect(content.contains("positiveBalance"))
        #expect(content.contains("validAccountNumber"))
        #expect(content.contains("sufficientMinimumBalance"))

        // OCL expressions
        #expect(content.contains("self.balance >= 0"))
        #expect(content.contains("self.accountNumber.size() = 10"))
        #expect(content.contains("AccountType::SAVINGS implies self.balance >= self.minimumBalance"))
    }

    @Test("Step 2.4: Validate Transaction invariant constraints")
    func testStep06ValidateTransactionInvariants() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Transaction constraints
        #expect(content.contains("positiveAmount"))
        #expect(content.contains("validDescription"))

        // OCL expressions
        #expect(content.contains("self.amount > 0"))
        #expect(content.contains("self.description.size() > 0"))
    }

    // MARK: - Section 3: Validate OCL Derivation Rules

    @Test("Step 3.1: Validate Customer derived attributes")
    func testStep07ValidateCustomerDerivedAttributes() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // totalBalance derivation
        #expect(content.contains("name=\"totalBalance\""))
        #expect(content.contains("derived=\"true\""))
        #expect(content.contains("self.accounts->collect(balance)->sum()"))

        // activeAccountCount derivation
        #expect(content.contains("name=\"activeAccountCount\""))
        #expect(content.contains("self.accounts->select(isActive)->size()"))
    }

    @Test("Step 3.2: Validate Account derived attributes")
    func testStep08ValidateAccountDerivedAttributes() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // totalDeposits derivation
        #expect(content.contains("name=\"totalDeposits\""))
        #expect(content.contains("TransactionType::DEPOSIT"))

        // totalWithdrawals derivation
        #expect(content.contains("name=\"totalWithdrawals\""))
        #expect(content.contains("TransactionType::WITHDRAWAL"))
    }

    // MARK: - Section 4: Validate OCL Pre/Post Conditions

    @Test("Step 4.1: Validate withdraw operation conditions")
    func testStep09ValidateWithdrawConditions() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Operation exists
        #expect(content.contains("name=\"withdraw\""))

        // Pre/post conditions
        #expect(content.contains("key=\"pre\""))
        #expect(content.contains("amount > 0"))
        #expect(content.contains("self.balance >= amount"))
        #expect(content.contains("key=\"post\""))
        #expect(content.contains("balance@pre"))
    }

    @Test("Step 4.2: Validate deposit operation conditions")
    func testStep10ValidateDepositConditions() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Operation exists
        #expect(content.contains("name=\"deposit\""))

        // Pre/post conditions
        #expect(content.contains("amount > 0"))
        #expect(content.contains("balance@pre + amount"))
    }

    // MARK: - Section 5: Validate Valid Instance Model

    @Test("Step 5.1: Validate valid instance exists")
    func testStep11ValidateValidInstanceExists() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path))

        let content = try String(contentsOf: instancePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("bank:Bank"))
        #expect(content.contains("First National Bank"))
    }

    @Test("Step 5.2: Validate unique identifiers in valid instance")
    func testStep12ValidateUniqueIdentifiers() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // All customer IDs should be unique
        let customerIds = ["CUST001", "CUST002", "CUST003"]
        for id in customerIds {
            let count = content.components(separatedBy: "customerId=\"\(id)\"").count - 1
            #expect(count == 1, "Customer ID \(id) should appear exactly once")
        }

        // All account numbers should be unique
        let accountNumbers = ["1234567890", "0987654321", "1122334455", "5566778899"]
        for num in accountNumbers {
            let count = content.components(separatedBy: "accountNumber=\"\(num)\"").count - 1
            #expect(count == 1, "Account number \(num) should appear exactly once")
        }
    }

    @Test("Step 5.3: Validate valid customer data")
    func testStep13ValidateValidCustomerData() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // All emails contain @
        #expect(content.contains("email=\"john.smith@email.com\""))
        #expect(content.contains("email=\"jane.doe@company.org\""))
        #expect(content.contains("email=\"bob.wilson@university.edu\""))

        // All ages >= 18
        #expect(content.contains("age=\"35\""))
        #expect(content.contains("age=\"28\""))
        #expect(content.contains("age=\"18\""))  // Minimum valid age
    }

    @Test("Step 5.4: Validate valid account data")
    func testStep14ValidateValidAccountData() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // All account numbers are 10 digits
        #expect(content.contains("accountNumber=\"1234567890\""))
        #expect(content.contains("accountNumber=\"0987654321\""))

        // All balances are positive
        #expect(content.contains("balance=\"5000.00\""))
        #expect(content.contains("balance=\"12500.00\""))
        #expect(content.contains("balance=\"50000.00\""))
        #expect(content.contains("balance=\"500.00\""))

        // Savings accounts have balance >= minimumBalance
        // Account with balance 5000.00 has minimumBalance 100.00 - OK
        // Account with balance 500.00 has minimumBalance 100.00 - OK
    }

    @Test("Step 5.5: Validate valid transaction data")
    func testStep15ValidateValidTransactionData() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("valid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // All transaction amounts are positive
        #expect(content.contains("amount=\"1000.00\""))
        #expect(content.contains("amount=\"4000.00\""))
        #expect(content.contains("amount=\"15000.00\""))
        #expect(content.contains("amount=\"2500.00\""))

        // All descriptions are non-empty
        #expect(content.contains("description=\"Initial deposit\""))
        #expect(content.contains("description=\"Salary credit\""))
        #expect(content.contains("description=\"Business payment\""))
    }

    // MARK: - Section 6: Validate Invalid Instance Model

    @Test("Step 6.1: Validate invalid instance exists")
    func testStep16ValidateInvalidInstanceExists() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")

        #expect(FileManager.default.fileExists(atPath: instancePath.path))

        let content = try String(contentsOf: instancePath, encoding: .utf8)
        #expect(content.contains("<?xml"))
        #expect(content.contains("bank:Bank"))
        #expect(content.contains("Problem Bank"))
    }

    @Test("Step 6.2: Document duplicate identifier violations")
    func testStep17DocumentDuplicateViolations() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Duplicate customer ID
        let cust001Count = content.components(separatedBy: "customerId=\"CUST001\"").count - 1
        #expect(cust001Count > 1, "Should have duplicate CUST001 for testing")

        // VIOLATION: Comments document the violations
        #expect(content.contains("VIOLATION"))
        #expect(content.contains("Duplicate customer ID"))
    }

    @Test("Step 6.3: Document invalid email violation")
    func testStep18DocumentInvalidEmailViolation() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Invalid email (no @)
        #expect(content.contains("email=\"invalid-email\""))
        #expect(content.contains("Invalid email"))
    }

    @Test("Step 6.4: Document underage customer violation")
    func testStep19DocumentUnderageViolation() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Age < 18
        #expect(content.contains("age=\"16\""))
        #expect(content.contains("Underage customer"))
    }

    @Test("Step 6.5: Document balance violations")
    func testStep20DocumentBalanceViolations() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Negative balance
        #expect(content.contains("balance=\"-500.00\""))
        #expect(content.contains("Negative balance"))

        // VIOLATION: Savings below minimum
        #expect(content.contains("balance=\"50.00\" minimumBalance=\"100.00\""))
        #expect(content.contains("below minimum balance"))
    }

    @Test("Step 6.6: Document account number violation")
    func testStep21DocumentAccountNumberViolation() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Account number not 10 digits
        #expect(content.contains("accountNumber=\"12345\""))
        #expect(content.contains("5 digits instead of 10"))
    }

    @Test("Step 6.7: Document transaction violations")
    func testStep22DocumentTransactionViolations() async throws {
        let instancePath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("invalid-instance.xmi")
        let content = try String(contentsOf: instancePath, encoding: .utf8)

        // VIOLATION: Negative transaction amount
        #expect(content.contains("amount=\"-100.00\""))
        #expect(content.contains("Negative transaction amount"))

        // VIOLATION: Empty description
        #expect(content.contains("description=\"\""))
        #expect(content.contains("Empty description"))
    }

    // MARK: - Section 7: OCL Annotation Structure Validation

    @Test("Step 7.1: Validate OCL annotation sources")
    func testStep23ValidateOCLAnnotationSources() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Ecore OCL annotation source
        #expect(content.contains("http://www.eclipse.org/emf/2002/Ecore/OCL"))

        // Ecore constraints annotation
        #expect(content.contains("http://www.eclipse.org/emf/2002/Ecore"))
        #expect(content.contains("key=\"constraints\""))
    }

    @Test("Step 7.2: Validate derivation rule structure")
    func testStep24ValidateDerivationRuleStructure() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Derived attributes should have proper flags
        #expect(content.contains("changeable=\"false\""))
        #expect(content.contains("volatile=\"true\""))
        #expect(content.contains("transient=\"true\""))
        #expect(content.contains("derived=\"true\""))

        // Derivation key
        #expect(content.contains("key=\"derivation\""))
    }

    @Test("Step 7.3: Count total OCL constraints")
    func testStep25CountOCLConstraints() async throws {
        let metamodelPath = OCLTutorialTests.tutorialCodePath.appendingPathComponent("bank-account.ecore")
        let content = try String(contentsOf: metamodelPath, encoding: .utf8)

        // Count constraint annotations
        let invariantCount = content.components(separatedBy: "key=\"constraints\"").count - 1
        #expect(invariantCount >= 4, "Should have at least 4 classes with constraints")

        // Count derivation rules
        let derivationCount = content.components(separatedBy: "key=\"derivation\"").count - 1
        #expect(derivationCount >= 4, "Should have at least 4 derived attributes")

        // Count pre/post conditions
        let preCount = content.components(separatedBy: "key=\"pre\"").count - 1
        let postCount = content.components(separatedBy: "key=\"post\"").count - 1
        #expect(preCount >= 3, "Should have at least 3 preconditions")
        #expect(postCount >= 2, "Should have at least 2 postconditions")
    }
}
