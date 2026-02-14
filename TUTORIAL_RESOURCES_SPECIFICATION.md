# Tutorial Resources Specification

**Document Version:** 1.0
**Date:** 2026-01-01
**Status:** Complete specification for systematic resource creation

## Purpose

This document provides detailed specifications for all missing tutorial resource files in the swift-modelling project. Each resource file is specified with its purpose, content requirements, format, and dependencies to enable systematic creation.

---

## File Organization

All tutorial resources are located in:
```
swift-modelling/Sources/SwiftModelling/SwiftModelling.docc/Resources/
```

### Directory Structure

```
Resources/
├── AQL-01/          # AQL Basics tutorial
├── AQL-02/          # AQL Filtering and Selection
├── AQL-03/          # AQL Collection Operations
├── AQL-04/          # AQL in MTL Templates
├── AQL-05/          # AQL Complex Queries
├── Workflow-01/     # Complete MDE Workflow
├── Workflow-02/     # Model Refactoring Pipeline
├── Workflow-03/     # Cross-Format Integration
├── Images/          # SVG diagrams
└── [existing resources...]
```

---

## Naming Conventions

### General Pattern
```
{tutorial-id}-step-{number}-{description}.{extension}
```

**Examples:**
- `aql-01-step-01-metamodel.ecore`
- `workflow-01-step-05-instance.xmi`
- `workflow-02-step-09-transformation.atl`

### File Types by Extension
- `.ecore` - Ecore metamodel files (XMI format)
- `.xmi` - Model instance files
- `.atl` - ATL transformation files
- `.mtl` - MTL template files
- `.aql` - AQL query files (when standalone)
- `.sh` - Shell scripts demonstrating CLI usage
- `.swift` - Swift test/example files
- `.json` - JSON data/schema files
- `.md` - Markdown documentation files
- `.svg` - Scalable Vector Graphics diagrams

---

## AQL Tutorial Resources

### AQL-01: Basics (12 files)

**Tutorial Focus:** Basic AQL syntax, property access, literals, navigation, operations

#### Step 01: Metamodel Definition
**File:** `aql-01-step-01-metamodel.ecore`
**Format:** Ecore XMI
**Purpose:** Define Company/Employee metamodel for AQL examples

**Content Requirements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="company" nsURI="http://www.example.org/company" nsPrefix="company">

  <eClassifiers xsi:type="ecore:EClass" name="Company">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="employees" upperBound="-1"
        eType="#//Employee" containment="true"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Employee">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="age" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="department" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>

</ecore:EPackage>
```

**Classes:**
- `Company` with attributes: `name: String`, references: `employees: Employee[*]`
- `Employee` with attributes: `name: String`, `age: Integer`, `department: String`

---

#### Step 02: Model Instance
**File:** `aql-01-step-02-instance.xmi`
**Format:** XMI
**Purpose:** Sample company data for AQL querying

**Content Requirements:**
- 1 Company instance with name "TechCorp"
- 5-6 Employee instances with varied data:
  - Mix of departments: "Engineering", "Sales", "Marketing", "HR"
  - Ages ranging from 25-55
  - Realistic names

**Sample Structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<company:Company xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:company="http://www.example.org/company" name="TechCorp">
  <employees name="Alice Johnson" age="32" department="Engineering"/>
  <employees name="Bob Smith" age="45" department="Sales"/>
  <employees name="Carol Williams" age="28" department="Engineering"/>
  <employees name="David Brown" age="38" department="Marketing"/>
  <employees name="Eve Davis" age="29" department="HR"/>
</company:Company>
```

---

#### Steps 03-12: Shell Scripts (10 files)

Each script demonstrates specific AQL concepts via CLI commands.

**File:** `aql-01-step-03-property-access.sh`
**Purpose:** Demonstrate basic property access with dot notation
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 3: Basic Property Access

# Access a simple property
echo "Employee name access:"
# In actual implementation, this would use swift-aql or embedded in swift-atl/swift-mtl
# For now, show the conceptual AQL expression
echo "AQL Expression: employee.name"
echo "Returns: The name of the employee"

# Access multiple properties
echo ""
echo "Company properties:"
echo "AQL Expression: company.name"
echo "Returns: 'TechCorp'"
```

---

**File:** `aql-01-step-04-literals.sh`
**Purpose:** Show literal value syntax
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 4: Literal Values

echo "String literals:"
echo "  'Hello World' - String literal"
echo "  'TechCorp' - Another string"

echo ""
echo "Numeric literals:"
echo "  42 - Integer literal"
echo "  3.14 - Real number literal"

echo ""
echo "Boolean literals:"
echo "  true - Boolean true"
echo "  false - Boolean false"
```

---

**File:** `aql-01-step-05-single-navigation.sh`
**Purpose:** Navigate through single-valued references
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 5: Single-valued Navigation

echo "Navigating through references:"
echo "AQL: employee.company.name"
echo "Description: Navigate from employee to company, then access name"
echo ""
echo "Result: The company name for the employee's company"
```

---

**File:** `aql-01-step-06-multi-navigation.sh`
**Purpose:** Navigate through collections
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 6: Multi-valued Navigation

echo "Navigating collections:"
echo "AQL: company.employees"
echo "Returns: Collection of all employees"
echo ""
echo "Chained navigation:"
echo "AQL: company.employees.name"
echo "Returns: Collection of all employee names"
```

---

**File:** `aql-01-step-07-combined-navigation.sh`
**Purpose:** Chain multiple navigation steps
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 7: Combined Navigation

echo "Complex navigation chains:"
echo "AQL: company.employees.department"
echo "Returns: All departments (may include duplicates)"
echo ""
echo "Deep navigation:"
echo "Access properties through multiple levels of references"
```

---

**File:** `aql-01-step-08-safe-navigation.sh`
**Purpose:** Handle optional references safely
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 8: Safe Navigation

echo "Safe navigation for optional references:"
echo "Check before accessing:"
echo "AQL: if employee.manager <> null then employee.manager.name else 'No manager' endif"
echo ""
echo "This prevents null reference errors"
```

---

**File:** `aql-01-step-09-arithmetic.sh`
**Purpose:** Arithmetic operations
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 9: Arithmetic Operations

echo "Arithmetic operations:"
echo "Addition: employee.age + 1 (next birthday)"
echo "Subtraction: employee.age - 5 (age 5 years ago)"
echo "Multiplication: employee.age * 2"
echo "Division: employee.age / 2"
echo "Modulo: employee.age mod 10 (last digit of age)"
```

---

**File:** `aql-01-step-10-strings.sh`
**Purpose:** String operations
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 10: String Operations

echo "String operations:"
echo "Concatenation: employee.name + ' (' + employee.department + ')'"
echo "Size: employee.name.size() - length of name"
echo "Case conversion: employee.name.toUpperCase()"
echo "Result example: 'ALICE JOHNSON'"
```

---

**File:** `aql-01-step-11-comparisons.sh`
**Purpose:** Comparison operators
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 11: Comparison Operations

echo "Comparison operators:"
echo "Equality: employee.department = 'Engineering'"
echo "Inequality: employee.age <> 30"
echo "Greater than: employee.age > 25"
echo "Less than or equal: employee.age <= 40"
echo ""
echo "All return boolean values (true/false)"
```

---

**File:** `aql-01-step-12-combined-expressions.sh`
**Purpose:** Complex combined expressions
**Content:**
```bash
#!/bin/bash
# AQL-01 Step 12: Combined Expressions

echo "Complex AQL expressions:"
echo ""
echo "Example 1: Age check with message"
echo "AQL: if employee.age >= 30 then 'Senior' else 'Junior' endif"
echo ""
echo "Example 2: Department with count"
echo "AQL: employee.department + ' (' + company.employees->select(e | e.department = employee.department)->size().toString() + ' employees)'"
echo ""
echo "These combine navigation, operations, filtering, and functions"
```

---

### AQL-02: Filtering and Selection (16 files)

**Tutorial Focus:** select, reject, exists, forAll operations

#### Step 01: University Metamodel
**File:** `aql-02-step-01-university-metamodel.ecore`
**Format:** Ecore XMI
**Purpose:** Define Student/Course/Professor structure

**Content Requirements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="university" nsURI="http://www.example.org/university" nsPrefix="uni">

  <eClassifiers xsi:type="ecore:EClass" name="University">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="students" upperBound="-1" eType="#//Student" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="courses" upperBound="-1" eType="#//Course" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="professors" upperBound="-1" eType="#//Professor" containment="true"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Student">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="studentId" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="grade" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Course">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="title" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="credits" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="department" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Professor">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="specialisation" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="tenure" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBoolean"/>
  </eClassifiers>

</ecore:EPackage>
```

**Classes:**
- `University`: name, students[*], courses[*], professors[*]
- `Student`: name, studentId, grade (0-100)
- `Course`: title, credits, department
- `Professor`: name, specialisation, tenure

---

#### Step 02: University Instance
**File:** `aql-02-step-02-university-instance.xmi`
**Format:** XMI
**Purpose:** Rich dataset for filtering examples

**Content Requirements:**
- 1 University "State University"
- 10-12 Students with varied grades (60-95 range)
- 6-8 Courses with different credit hours (3-4 credits)
- 4-5 Professors with different specialisations

**Sample:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<university:University xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:university="http://www.example.org/university" name="State University">
  <students name="John Doe" studentId="S001" grade="85"/>
  <students name="Jane Smith" studentId="S002" grade="92"/>
  <students name="Bob Johnson" studentId="S003" grade="78"/>
  <students name="Alice Williams" studentId="S004" grade="88"/>
  <!-- Add 6-8 more students -->

  <courses title="Data Structures" credits="4" department="Computer Science"/>
  <courses title="Calculus I" credits="4" department="Mathematics"/>
  <courses title="Introduction to Physics" credits="3" department="Physics"/>
  <!-- Add 3-5 more courses -->

  <professors name="Dr. Alan Turing" specialisation="Computer Science" tenure="true"/>
  <professors name="Dr. Ada Lovelace" specialisation="Mathematics" tenure="true"/>
  <!-- Add 2-3 more professors -->
</university:University>
```

---

#### Steps 03-16: Shell Scripts (14 files)

**Pattern:** Each demonstrates specific filtering/selection operations

**Files needed:**
- `aql-02-step-03-simple-select.sh` - Basic select operation
- `aql-02-step-04-simple-reject.sh` - Basic reject operation
- `aql-02-step-05-select-with-comparison.sh` - Select with >/>=/< comparisons
- `aql-02-step-06-select-with-equality.sh` - Select with = comparison
- `aql-02-step-07-reject-with-comparison.sh` - Reject pattern
- `aql-02-step-08-combined-select-reject.sh` - Chain select and reject
- `aql-02-step-09-exists-operation.sh` - exists quantifier
- `aql-02-step-10-forall-operation.sh` - forAll quantifier
- `aql-02-step-11-exists-with-complex-condition.sh` - Complex exists
- `aql-02-step-12-forall-validation.sh` - forAll for validation
- `aql-02-step-13-chained-filters.sh` - Multiple filter chain
- `aql-02-step-14-nested-filtering.sh` - Nested filter patterns
- `aql-02-step-15-filter-with-navigation.sh` - Filter + navigate
- `aql-02-step-16-advanced-filter-patterns.sh` - Complex patterns

**Example Script (step 05):**
```bash
#!/bin/bash
# AQL-02 Step 5: Select with Comparisons

echo "Select operations with comparison operators:"
echo ""
echo "High-performing students:"
echo "AQL: university.students->select(s | s.grade >= 85)"
echo "Returns: All students with grade 85 or higher"
echo ""
echo "4-credit courses:"
echo "AQL: university.courses->select(c | c.credits > 3)"
echo "Returns: All courses with more than 3 credits"
```

---

### AQL-03: Collection Operations (20 files)

**Tutorial Focus:** collect, flatten, sum, max, min, size

#### Step 01: Library Metamodel
**File:** `aql-03-step-01-library-metamodel.ecore`
**Format:** Ecore XMI
**Purpose:** Complex structure for collection operations

**Content Requirements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="library" nsURI="http://www.example.org/library" nsPrefix="lib">

  <eClassifiers xsi:type="ecore:EClass" name="Library">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="books" upperBound="-1" eType="#//Book" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="authors" upperBound="-1" eType="#//Author" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="categories" upperBound="-1" eType="#//Category" containment="true"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Book">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="title" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="isbn" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="pages" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="available" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EBoolean"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="rating" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDouble"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="author" eType="#//Author"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Author">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="nationality" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="books" upperBound="-1" eType="#//Book" eOpposite="#//Book/author"/>
  </eClassifiers>

  <eClassifiers xsi:type="ecore:EClass" name="Category">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name" eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="books" upperBound="-1" eType="#//Book"/>
  </eClassifiers>

</ecore:EPackage>
```

**Classes:**
- `Library`: name, books[*], authors[*], categories[*]
- `Book`: title, isbn, pages, available, rating, author
- `Author`: name, nationality, books[*] (bidirectional)
- `Category`: name, books[*]

---

#### Steps 02-20: Instance and Scripts (19 files)

**File:** `aql-03-step-02-library-instance-small.xmi` - Small dataset (5 books)
**File:** `aql-03-step-03-library-instance-medium.xmi` - Medium dataset (15 books)
**File:** `aql-03-step-04-library-instance.xmi` - Full dataset (25+ books)

**Scripts (steps 05-20):**
- Steps 05-08: collect operations (basic, with navigation, nested, transformation)
- Steps 09-12: flatten operations (basic, chained, nested collections)
- Steps 13-16: aggregation (sum, max, min, average patterns)
- Steps 17-20: advanced patterns (complex queries, multi-step, optimization)

**Example (step 05):**
```bash
#!/bin/bash
# AQL-03 Step 5: Collect Operations

echo "Collect operation - extract properties from collections:"
echo ""
echo "All book titles:"
echo "AQL: library.books->collect(b | b.title)"
echo "Returns: Collection of all book titles as strings"
echo ""
echo "All page counts:"
echo "AQL: library.books->collect(b | b.pages)"
echo "Returns: Collection of integers representing page counts"
```

---

### AQL-04: AQL in MTL (20 files)

**Tutorial Focus:** Using AQL within MTL templates

#### Step 01: WebApp Metamodel
**File:** `aql-04-step-01-webapp-metamodel.ecore`
**Format:** Ecore XMI
**Purpose:** Web application structure for code generation examples

**Content Requirements:**
- `WebApp`: name, controllers[*], models[*]
- `Controller`: name, methods[*], routes[*]
- `Method`: name, returnType, parameters[*], visibility
- `Parameter`: name, type, required
- `Model`: name, attributes[*], abstract
- `Attribute`: name, type, required

---

#### Step 02: WebApp Instance
**File:** `aql-04-step-02-webapp-instance.xmi`
**Format:** XMI
**Purpose:** Realistic web app structure

**Content:** REST API with 3-4 controllers, 8-10 methods, 5-6 models

---

#### Steps 03-20: Templates and Scripts (18 files)

**Pattern:** MTL templates demonstrating AQL integration

**Files:**
- `aql-04-step-03-basic-mtl-template.mtl` - Simple property access in MTL
- `aql-04-step-04-basic-template.mtl` - Basic AQL in MTL brackets
- Steps 05-08: MTL with AQL navigation (property, reference, collection)
- Steps 09-12: MTL loops with AQL (for, select, collect)
- Steps 13-16: MTL conditionals with AQL (if, exists, forAll)
- Steps 17-20: Advanced patterns (let bindings, complex queries, helpers)

**Example (step 05):**
```mtl
[comment encoding = UTF-8 /]
[module generateControllers('http://www.example.org/webapp')]

[template public generateController(controller : Controller)]
// Generated Swift Controller: [controller.name/]

class [controller.name/] {
    // Methods: [controller.methods->size()/]

    [for (method : Method | controller.methods)]
    func [method.name/]() -> [method.returnType/] {
        // TODO: Implement [method.name/]
    }
    [/for]
}
[/template]
```

---

### AQL-05: Complex Queries (20 files)

**Tutorial Focus:** Advanced AQL patterns, nested iterations, cross-model navigation

#### Step 01: Enterprise Metamodel
**File:** `aql-05-step-01-enterprise-metamodel.ecore`
**Format:** Ecore XMI
**Purpose:** Complex organizational structure

**Content Requirements:**
- `Organization`: name, projects[*], departments[*]
- `Project`: name, teams[*], budget, status, dependencies[*], requiredSkills[*]
- `Team`: name, members[*], resources[*]
- `Employee`: name, skills[*], role
- `Department`: name, employees[*]
- `Resource`: name, available, cost
- `Skill`: name, level

---

#### Step 02: Enterprise Instance
**File:** `aql-05-step-02-enterprise-instance.xmi`
**Format:** XMI
**Purpose:** Rich organizational data

**Content:** Large organization with 10+ projects, 5+ departments, 30+ employees

---

#### Steps 03-20: Advanced Query Scripts (18 files)

**Pattern:** Progressively complex AQL queries

- Steps 03-08: Nested iterations and cross-products
- Steps 09-12: Cross-model navigation and joins
- Steps 13-16: Query composition and helper functions
- Steps 17-20: Graph traversal, pattern matching, analytics

---

## Workflow Tutorial Resources

### Workflow-01: Complete MDE Workflow (20 files)

**Tutorial Focus:** End-to-end MDE from metamodel to deployed code

#### Metamodel Design (Steps 01-04)

**File:** `workflow-01-step-01-metamodel.ecore`
**Purpose:** E-commerce domain metamodel
**Classes:**
- `Shop`: name, products[*], categories[*], customers[*], orders[*]
- `Product`: name, sku, price, description, category, stock
- `Category`: name, description, products[*]
- `Customer`: name, email, orders[*]
- `Order`: orderNumber, date, items[*], customer, totalAmount
- `OrderItem`: product, quantity, unitPrice

---

**File:** `workflow-01-step-02-validate-metamodel.sh`
**Purpose:** CLI validation command
**Content:**
```bash
#!/bin/bash
# Validate E-commerce metamodel

swift-ecore validate workflow-01-step-01-metamodel.ecore

# Expected output: Metamodel is well-formed
```

---

**File:** `workflow-01-step-03-metamodel-docs.sh`
**Purpose:** Generate documentation
**Content:**
```bash
#!/bin/bash
# Generate metamodel documentation

swift-ecore document workflow-01-step-01-metamodel.ecore \
  --output ecommerce-docs.md \
  --format markdown

echo "Documentation generated: ecommerce-docs.md"
```

---

**File:** `workflow-01-step-04-metamodel-export.sh`
**Purpose:** Export to JSON
**Content:**
```bash
#!/bin/bash
# Export metamodel to JSON format

swift-ecore convert workflow-01-step-01-metamodel.ecore \
  --to json \
  --output ecommerce-metamodel.json

echo "Exported to JSON format"
```

---

#### Instance Creation (Steps 05-08)

**File:** `workflow-01-step-05-instance.xmi`
**Purpose:** Rich e-commerce data
**Content:**
- 1 Shop "TechStore"
- 20+ Products across multiple categories
- 5+ Categories
- 10+ Customers
- 15+ Orders with multiple items

---

**File:** `workflow-01-step-06-validate-instance.sh`
```bash
#!/bin/bash
# Validate instance against metamodel

swift-ecore validate workflow-01-step-05-instance.xmi \
  --metamodel workflow-01-step-01-metamodel.ecore

echo "Instance validation complete"
```

---

**File:** `workflow-01-step-07-query-instance.sh`
```bash
#!/bin/bash
# Query instance with AQL

echo "Total revenue query:"
echo "AQL: shop.orders->collect(o | o.totalAmount)->sum()"
echo ""
echo "Top customers query:"
echo "AQL: shop.customers->sortedBy(c | c.orders->size())->reverse()->first(5)"
```

---

**File:** `workflow-01-step-08-create-test-instances.sh`
```bash
#!/bin/bash
# Create multiple test instances for different scenarios

echo "Creating test instances..."

# Small shop (testing)
cp workflow-01-step-05-instance.xmi test-small-shop.xmi

# Medium shop (integration)
# Large shop (performance)

echo "Test instances created"
```

---

#### Model Transformation (Steps 09-12)

**File:** `workflow-01-step-09-reporting-metamodel.ecore`
**Purpose:** Analytics-focused metamodel
**Classes:**
- `Report`: name, period, metrics[*]
- `SalesMetric`: product, totalSales, quantity, revenue
- `CustomerMetric`: customer, orderCount, totalSpent, averageOrderValue
- `CategoryMetric`: category, productCount, totalRevenue

---

**File:** `workflow-01-step-10-transformation.atl`
**Purpose:** E-commerce to Reporting transformation
**Content:**
```atl
module ECommerce2Reporting;
create OUT : Reporting from IN : ECommerce;

helper context ECommerce!Shop def: totalRevenue : Real =
    self.orders->collect(o | o.totalAmount)->sum();

rule Shop2Report {
    from s : ECommerce!Shop
    to r : Reporting!Report (
        name <- s.name + ' Sales Report',
        metrics <- s.products->collect(p | thisModule.Product2Metric(p))
    )
}

lazy rule Product2Metric {
    from p : ECommerce!Product
    to m : Reporting!SalesMetric (
        product <- p.name,
        totalSales <- p.orderItems->collect(oi | oi.quantity)->sum(),
        revenue <- p.orderItems->collect(oi | oi.quantity * oi.unitPrice)->sum()
    )
}

-- Additional rules for CustomerMetric and CategoryMetric
```

---

**File:** `workflow-01-step-11-run-transformation.sh`
```bash
#!/bin/bash
# Execute ATL transformation

swift-atl transform workflow-01-step-10-transformation.atl \
  --source workflow-01-step-05-instance.xmi \
  --source-metamodel workflow-01-step-01-metamodel.ecore \
  --target-metamodel workflow-01-step-09-reporting-metamodel.ecore \
  --output reporting-data.xmi

echo "Transformation complete: reporting-data.xmi"
```

---

**File:** `workflow-01-step-12-validate-transformation.sh`
```bash
#!/bin/bash
# Validate transformation output

swift-ecore validate reporting-data.xmi \
  --metamodel workflow-01-step-09-reporting-metamodel.ecore

echo "Querying transformation results..."
# AQL queries to verify data integrity
```

---

#### Code Generation (Steps 13-16)

**File:** `workflow-01-step-13-swift-templates.mtl`
**Purpose:** Generate Swift data classes
**Content:**
```mtl
[module generateSwiftClasses('http://www.example.org/reporting')]

[template public generateReport(report : Report)]
[file ('ReportingModels.swift', false, 'UTF-8')]
// Generated Swift Models for [report.name/]
// Generated: [getCurrentDate()/]

import Foundation

struct SalesReport {
    let name: String
    let metrics: [SalesMetric]

    // Total revenue calculation
    var totalRevenue: Double {
        metrics.reduce(0.0) { $0 + $1.revenue }
    }
}

struct SalesMetric {
    let product: String
    let totalSales: Int
    let revenue: Double
}

// Additional model structures...
[/file]
[/template]
```

---

**File:** `workflow-01-step-14-json-templates.mtl`
**Purpose:** Generate JSON API schema
**Content:**
```mtl
[module generateJSONAPI('http://www.example.org/reporting')]

[template public generateAPISchema(report : Report)]
[file ('api-schema.json', false, 'UTF-8')]
{
  "openapi": "3.0.0",
  "info": {
    "title": "[report.name/] API",
    "version": "1.0.0"
  },
  "paths": {
    "/sales-metrics": {
      "get": {
        "summary": "Get sales metrics",
        "responses": {
          "200": {
            "description": "Sales metrics data",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/SalesMetric"
                }
              }
            }
          }
        }
      }
    }
  }
}
[/file]
[/template]
```

---

**File:** `workflow-01-step-15-docs-templates.mtl`
**Purpose:** Generate markdown documentation
**Content:**
```mtl
[module generateDocumentation('http://www.example.org/reporting')]

[template public generateDocs(report : Report)]
[file ('documentation.md', false, 'UTF-8')]
# [report.name/]

## Overview

This report provides sales analytics and metrics.

## Metrics

[for (metric : SalesMetric | report.metrics)]
### [metric.product/]

- Total Sales: [metric.totalSales/]
- Revenue: $[metric.revenue/]

[/for]

## API Reference

See `api-schema.json` for REST API specification.
[/file]
[/template]
```

---

**File:** `workflow-01-step-16-generate-code.sh`
```bash
#!/bin/bash
# Execute all code generation templates

mkdir -p Generated

echo "Generating Swift classes..."
swift-mtl generate workflow-01-step-13-swift-templates.mtl \
  --model reporting-data.xmi \
  --output Generated/

echo "Generating JSON API schema..."
swift-mtl generate workflow-01-step-14-json-templates.mtl \
  --model reporting-data.xmi \
  --output Generated/

echo "Generating documentation..."
swift-mtl generate workflow-01-step-15-docs-templates.mtl \
  --model reporting-data.xmi \
  --output Generated/

echo "Code generation complete!"
ls -la Generated/
```

---

#### Integration and Validation (Steps 17-20)

**File:** `workflow-01-step-17-compile-swift.sh`
```bash
#!/bin/bash
# Compile generated Swift code

cd Generated

swiftc ReportingModels.swift -o test-models

echo "Compilation successful"
./test-models
```

---

**File:** `workflow-01-step-18-test-apis.swift`
**Purpose:** Swift test file for generated APIs
**Content:**
```swift
import Testing

@Suite("Generated Sales Report API Tests")
struct ReportingAPITests {
	@Test("SalesReportAPI generated metric correctly")
    func testSalesMetricCreation() {
        let metric = SalesMetric(
            product: "Test Product",
            totalSales: 100,
            revenue: 1999.99
        )

        #expect(metric.product == "Test Product")
        #expect(metric.totalSales == 100)
        #expect(metric.revenue.isApproximatelyEqual(to: 1999.99))
    }

	@Test("SalesReportAPI generated total revenue computed property correctly")
    func testReportTotalRevenue() {
        let metrics = [
            SalesMetric(product: "A", totalSales: 50, revenue: 500.0),
            SalesMetric(product: "B", totalSales: 30, revenue: 300.0)
        ]

        let report = SalesReport(name: "Test", metrics: metrics)

        #expect(report.totalRevenue.isApproximatelyEqual(to: 800.0))
    }
}
```

---

**File:** `workflow-01-step-19-validate-docs.sh`
```bash
#!/bin/bash
# Validate generated documentation

cd Generated

# Check documentation exists
test -f documentation.md && echo "✓ Documentation exists"

# Check completeness
grep -q "## Overview" documentation.md && echo "✓ Has Overview section"
grep -q "## Metrics" documentation.md && echo "✓ Has Metrics section"
grep -q "## API Reference" documentation.md && echo "✓ Has API Reference"

echo "Documentation validation complete"
```

---

**File:** `workflow-01-step-20-end-to-end-validation.sh`
```bash
#!/bin/bash
# Comprehensive end-to-end workflow validation

echo "=== Complete MDE Workflow Validation ==="
echo ""

echo "Step 1: Metamodel validation"
swift-ecore validate workflow-01-step-01-metamodel.ecore || exit 1

echo "Step 2: Instance validation"
swift-ecore validate workflow-01-step-05-instance.xmi \
  --metamodel workflow-01-step-01-metamodel.ecore || exit 2

echo "Step 3: Transformation execution"
swift-atl transform workflow-01-step-10-transformation.atl \
  --source workflow-01-step-05-instance.xmi \
  --output reporting-output.xmi || exit 3

echo "Step 4: Code generation"
swift-mtl generate workflow-01-step-13-swift-templates.mtl \
  --model reporting-output.xmi \
  --output ValidationOutput/ || exit 4

echo "Step 5: Code compilation"
cd ValidationOutput && swiftc ReportingModels.swift || exit 5

echo ""
echo "✓ All workflow steps validated successfully!"
echo "✓ Metamodel → Instance → Transformation → Generation → Compilation"
```

---

### Workflow-02: Model Refactoring Pipeline (20 files)

**Tutorial Focus:** Legacy model migration and improvement

#### Legacy Analysis (Steps 01-04)

**File:** `workflow-02-step-01-legacy-customer.ecore`
**Purpose:** Poorly designed legacy metamodel
**Issues to include:**
- Inconsistent naming (some camelCase, some snake_case)
- Poor attribute types (strings for numbers)
- Missing relationships
- No inheritance hierarchy
- Redundant classes

**Example:**
```xml
<!-- Intentionally poor design for refactoring example -->
<ecore:EClass name="customer_data">
  <eStructuralFeatures name="cust_name" eType="EString"/>
  <eStructuralFeatures name="cust_age" eType="EString"/> <!-- Should be Int -->
  <eStructuralFeatures name="address_street" eType="EString"/>
  <eStructuralFeatures name="address_city" eType="EString"/>
  <!-- Flat structure without Address class -->
</ecore:EClass>
```

---

**File:** `workflow-02-step-02-legacy-data.xmi`
**Purpose:** Legacy instance data with quality issues
**Content:** Data that exposes metamodel design flaws

---

**File:** `workflow-02-step-04-analysis-queries.aql`
**Purpose:** AQL queries identifying issues
**Content:**
```aql
-- Find customers with invalid age data
customers->select(c | c.cust_age.toInteger() < 0 or c.cust_age.toInteger() > 120)

-- Find duplicate customer records
customers->select(c1 | customers->exists(c2 | c2 <> c1 and c2.cust_name = c1.cust_name))

-- Find missing required fields
customers->select(c | c.cust_name = null or c.cust_name = '')
```

---

#### Improved Design (Steps 05-08)

**File:** `workflow-02-step-05-improved-customer.ecore`
**Purpose:** Well-designed metamodel
**Improvements:**
- Consistent naming conventions
- Proper types
- Extracted Address class
- Inheritance (Person → Customer, Employee)
- Clear relationships

---

**File:** `workflow-02-step-08-legacy-to-improved-mapping.md`
**Purpose:** Migration mapping documentation
**Content:**
```markdown
# Legacy to Improved Model Mapping

## Class Mappings

| Legacy Class | Improved Class | Notes |
|--------------|----------------|-------|
| customer_data | Customer | Inherits from Person |

## Attribute Mappings

| Legacy Attribute | Improved Attribute | Transformation |
|------------------|-------------------|----------------|
| cust_name | name (Person) | Direct copy |
| cust_age | age (Person) | String to Integer conversion |
| address_street, address_city | address (Address) | Extract to new class |

## Data Quality Improvements

- Age validation: Reject invalid ages, set to null if unparseable
- Name normalization: Trim whitespace, title case
- Duplicate detection: Merge duplicate records
```

---

#### Migration Transformations (Steps 09-12)

**File:** `workflow-02-step-09-migrate-legacy-to-improved.atl`
**Purpose:** Main migration transformation
**Content:** ATL rules handling structure migration and data cleanup

---

**File:** `workflow-02-step-10-data-quality-improvements.atl`
**Purpose:** Data cleansing transformation
**Content:** ATL helpers for validation, normalization, deduplication

---

**File:** `workflow-02-step-11-validation-transforms.atl`
**Purpose:** Post-migration validation
**Content:** ATL rules generating validation reports

---

#### Batch Migration (Steps 13-16)

**File:** `workflow-02-step-13-migrate-all-instances.sh`
**Purpose:** Batch migration script
**Content:**
```bash
#!/bin/bash
# Migrate multiple instance files

LEGACY_DIR="legacy-data"
OUTPUT_DIR="migrated-data"
mkdir -p "$OUTPUT_DIR"

for file in "$LEGACY_DIR"/*.xmi; do
    filename=$(basename "$file")
    echo "Migrating $filename..."

    swift-atl transform workflow-02-step-09-migrate-legacy-to-improved.atl \
        --source "$file" \
        --output "$OUTPUT_DIR/$filename"
done

echo "Migration complete: $(ls -1 $OUTPUT_DIR | wc -l) files migrated"
```

---

#### Quality Assurance (Steps 17-20)

**Files:** QA scripts, rollback procedures, deployment automation

---

### Workflow-03: Cross-Format Integration (20 files)

**Tutorial Focus:** XMI ↔ JSON ↔ Swift integration

#### Integration Setup (Steps 01-04)

**File:** `workflow-03-step-01-project-management.ecore`
**Purpose:** Shared metamodel for all formats
**Classes:** Project, Task, Milestone, Resource, Assignment

---

#### Format Bridges (Steps 05-20)

**Files:** XMI/JSON transformations, Swift code generation, bidirectional sync, API integration

---

## SVG Diagram Specifications

All diagrams should be created in SVG format with dark mode variants.

### Required Diagrams (18 files)

1. **aql-basics.svg** / **aql-basics~dark.svg**
   - **Content:** Overview of AQL query language concepts
   - **Elements:** Model structure, property access arrows, query expression examples
   - **Colors:** Blue (#007AFF) for navigation, green (#34C759) for results

2. **aql-navigation.svg** / **aql-navigation~dark.svg**
   - **Content:** Visual representation of navigation operations
   - **Elements:** Object graph, navigation paths, collection operations

3. **aql-filtering.svg** / **aql-filtering~dark.svg**
   - **Content:** Filter operations (select, reject, exists, forAll)
   - **Elements:** Input collection, filter conditions, output collection

4. **aql-collection-operations.svg** / **aql-collection-operations~dark.svg**
   - **Content:** collect, flatten, aggregation operations
   - **Elements:** Collection transformations, data flow

5. **aql-complex-queries.svg** / **aql-complex-queries~dark.svg**
   - **Content:** Nested queries, cross-model navigation
   - **Elements:** Complex query trees, multiple data sources

6. **aql-mtl-integration.svg** / **aql-mtl-integration~dark.svg**
   - **Content:** How AQL fits into MTL templates
   - **Elements:** MTL template structure, AQL expression blocks

7. **complete-mde-workflow.svg** / **complete-mde-workflow~dark.svg**
   - **Content:** Full MDE pipeline visualization
   - **Elements:** Metamodel → Instance → Transform → Generate → Integrate
   - **Style:** Horizontal flow diagram with distinct stages

8. **ecommerce-metamodel.svg** / **ecommerce-metamodel~dark.svg**
   - **Content:** E-commerce domain model
   - **Elements:** Classes (Shop, Product, Customer, Order), relationships

9. **model-refactoring-pipeline.svg** / **model-refactoring-pipeline~dark.svg**
   - **Content:** Legacy → Improved migration flow
   - **Elements:** Before/after comparison, transformation steps

10. **cross-format-integration.svg** / **cross-format-integration~dark.svg**
    - **Content:** Multi-format ecosystem
    - **Elements:** XMI, JSON, Swift with bidirectional arrows

11-18. **Additional utility diagrams** for specific tutorial steps

### SVG Creation Guidelines

- **Dimensions:** 800×600px standard, 1200×800px for complex diagrams
- **Light mode:** White background (#FFFFFF), dark text (#1C1C1E)
- **Dark mode:** Dark background (#1C1C1E), light text (#FFFFFF)
- **Accent colors:**
  - Primary: SF Blue (#007AFF)
  - Success: SF Green (#34C759)
  - Warning: SF Orange (#FF9500)
  - Error: SF Red (#FF3B30)
- **Typography:** SF Pro Text, 14-18pt body, 20-24pt headings
- **Icons:** SF Symbols style when representing Swift/Apple concepts

---

## File Creation Priority

### Phase 1: AQL-01 Complete (12 files)
All AQL-01 resources to enable full tutorial validation

### Phase 2: Workflow-01 Critical Path (8 files)
Essential workflow files: metamodels, instances, main scripts

### Phase 3: AQL-02 and AQL-03 (36 files)
Filtering and collection operation examples

### Phase 4: Workflow Integration (20 files)
Complete workflow-01, start workflow-02 and workflow-03

### Phase 5: Advanced AQL (40 files)
AQL-04, AQL-05 comprehensive examples

### Phase 6: Complete Workflows (32 files)
Finish workflow-02 and workflow-03

### Phase 7: SVG Diagrams (18 files)
All visual documentation

---

## Validation Checklist

For each created resource file:

- [ ] File name matches tutorial reference exactly
- [ ] File is in correct directory (AQL-XX/ or Workflow-XX/)
- [ ] Content matches specification requirements
- [ ] For .ecore files: Valid XMI, loads without errors
- [ ] For .xmi files: Conforms to specified metamodel
- [ ] For .atl files: Valid ATL syntax, compiles
- [ ] For .mtl files: Valid MTL syntax, can be executed
- [ ] For .sh files: Executable, demonstrates concept clearly
- [ ] Tutorial test file updated to validate resource
- [ ] Resource referenced in corresponding tutorial file

---

## Appendix A: Quick Reference

### Common Ecore Patterns

**Empty Package:**
```xml
<ecore:EPackage name="example" nsURI="http://example.org/example" nsPrefix="ex"/>
```

**Class with Attributes:**
```xml
<eClassifiers xsi:type="ecore:EClass" name="Person">
  <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
  <eStructuralFeatures xsi:type="ecore:EAttribute" name="age"
      eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EInt"/>
</eClassifiers>
```

**Containment Reference:**
```xml
<eStructuralFeatures xsi:type="ecore:EReference" name="children"
    upperBound="-1" eType="#//Person" containment="true"/>
```

**Bidirectional Reference:**
```xml
<!-- In Parent class -->
<eStructuralFeatures xsi:type="ecore:EReference" name="children"
    upperBound="-1" eType="#//Child" containment="true" eOpposite="#//Child/parent"/>

<!-- In Child class -->
<eStructuralFeatures xsi:type="ecore:EReference" name="parent"
    eType="#//Parent" eOpposite="#//Parent/children"/>
```

### Common XMI Instance Patterns

**Basic Instance:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<example:MyClass xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:example="http://example.org/example"
    name="Instance Name"/>
```

**Contained Elements:**
```xml
<example:Parent name="Parent1">
  <children name="Child1" age="10"/>
  <children name="Child2" age="12"/>
</example:Parent>
```

### Shell Script Template

```bash
#!/bin/bash
# Tutorial: {Tutorial Name}
# Step {N}: {Step Description}

echo "Demonstrating: {Concept}"
echo ""

# Show the command or AQL expression
echo "Command/Expression:"
echo "  {command or expression}"
echo ""

# Explain what it does
echo "Purpose:"
echo "  {explanation}"
echo ""

# Show expected output or result
echo "Result:"
echo "  {expected result}"
```

---

## Document Maintenance

**Update this specification when:**
- Tutorial structure changes
- New tutorials are added
- Resource requirements are refined
- Validation tests reveal missing/incorrect specifications

**Last Updated:** 2026-01-01
**Next Review:** When Phase 1 resources are validated
