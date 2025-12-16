# Creating Your First ATL Transformation with Swift-ATL

This tutorial will guide you through creating your first model-to-model transformation using Swift-ATL. We'll work through the classic **Families to Persons** example, transforming a model of families into a model of individual persons.

## Table of Contents

1. [Overview](#overview)
2. [Understanding the Transformation](#understanding-the-transformation)
3. [The Metamodels](#the-metamodels)
4. [Writing the ATL Transformation](#writing-the-atl-transformation)
5. [Creating Sample Models](#creating-sample-models)
6. [Running the Transformation](#running-the-transformation)
7. [Analysing the Results](#analysing-the-results)
8. [Advanced Topics](#advanced-topics)

## Overview

### What We're Building

In this tutorial, we'll create a transformation that converts:
- **Source**: A list of families, each with parents and children
- **Target**: A flat list of persons with their full names and genders

### Prerequisites

Ensure you have Swift-ATL installed and working. You can verify this by running:

```bash
swift-atl --version
```

## Understanding the Transformation

### The Problem Domain

Consider a genealogical system that organises people into family units:
- Each **Family** has a surname and contains family members
- Each **Member** has a first name and a role (father, mother, son, or daughter)

We want to transform this hierarchical structure into a flat list where:
- Each person is an independent entity
- Full names combine first and last names
- Gender is derived from family role

### Transformation Rules

Our transformation will:
1. Iterate through each family member
2. Determine their gender based on their role
3. Create a Person entity with their full name
4. Classify them as Male or Female

## The Metamodels

Metamodels define the structure of our data. Think of them as schemas or blueprints.

### Families Metamodel

The Families metamodel defines two main concepts:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage name="Families" nsURI="http://www.example.org/families">
  <eClassifiers xsi:type="ecore:EClass" name="Family">
    <!-- A family has a surname -->
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="lastName" 
        lowerBound="1" eType="ecore:EDataType EString"/>
    
    <!-- References to family members -->
    <eStructuralFeatures xsi:type="ecore:EReference" name="father" 
        lowerBound="1" eType="#//Member" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="mother" 
        lowerBound="1" eType="#//Member" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="sons" 
        upperBound="-1" eType="#//Member" containment="true"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="daughters" 
        upperBound="-1" eType="#//Member" containment="true"/>
  </eClassifiers>
  
  <eClassifiers xsi:type="ecore:EClass" name="Member">
    <!-- Each member has a first name -->
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="firstName" 
        lowerBound="1" eType="ecore:EDataType EString"/>
  </eClassifiers>
</ecore:EPackage>
```

### Persons Metamodel

The Persons metamodel is simpler, with an abstract Person class and two concrete subclasses:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage name="Persons" nsURI="http://www.example.org/persons">
  <!-- Abstract base class -->
  <eClassifiers xsi:type="ecore:EClass" name="Person" abstract="true">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="fullName" 
        lowerBound="1" eType="ecore:EDataType EString"/>
  </eClassifiers>
  
  <!-- Concrete subclasses -->
  <eClassifiers xsi:type="ecore:EClass" name="Male" eSuperTypes="#//Person"/>
  <eClassifiers xsi:type="ecore:EClass" name="Female" eSuperTypes="#//Person"/>
</ecore:EPackage>
```

## Writing the ATL Transformation

Now let's create the transformation that connects these two metamodels.

### File: Families2Persons.atl

```atl
-- Metamodel declarations
-- @path Families=/Families2Persons/Families.ecore
-- @path Persons=/Families2Persons/Persons.ecore

module Families2Persons;
create OUT: Persons from IN: Families;

-- Helper: Determine if a member is female
helper context Families!Member def: isFemale(): Boolean =
    if not self.familyMother.oclIsUndefined() then
        true
    else
        if not self.familyDaughter.oclIsUndefined() then
            true
        else
            false
        endif
    endif;

-- Helper: Get the family surname for a member
helper context Families!Member def: familyName: String =
    if not self.familyFather.oclIsUndefined() then
        self.familyFather.lastName
    else
        if not self.familyMother.oclIsUndefined() then
            self.familyMother.lastName
        else
            if not self.familySon.oclIsUndefined() then
                self.familySon.lastName
            else
                self.familyDaughter.lastName
            endif
        endif
    endif;

-- Rule: Transform male members to Male persons
rule Member2Male {
    from
        s: Families!Member (not s.isFemale())
    to
        t: Persons!Male (
            fullName <- s.firstName + ' ' + s.familyName
        )
}

-- Rule: Transform female members to Female persons
rule Member2Female {
    from
        s: Families!Member (s.isFemale())
    to
        t: Persons!Female (
            fullName <- s.firstName + ' ' + s.familyName
        )
}
```

### Understanding the Code

#### Module Declaration
```atl
module Families2Persons;
create OUT: Persons from IN: Families;
```
This declares our transformation module and specifies that we're creating a Persons model (OUT) from a Families model (IN).

#### Helpers
Helpers are reusable functions:
- `isFemale()`: Returns true if the member is female (mother or daughter)
- `familyName`: Returns the surname by checking which family reference exists

#### Transformation Rules
- `Member2Male`: Matches male members and creates Male persons
- `Member2Female`: Matches female members and creates Female persons

Each rule specifies:
- **from**: The source pattern to match (with an optional filter)
- **to**: The target elements to create and how to initialise them

## Creating Sample Models

Let's create a sample Families model to test our transformation.

### File: sample-Families.xmi

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" 
         xmlns="http://www.example.org/families">
  <Family lastName="March">
    <father firstName="Jim"/>
    <mother firstName="Cindy"/>
    <sons firstName="Brandon"/>
    <daughters firstName="Brenda"/>
  </Family>
  
  <Family lastName="Sailor">
    <father firstName="Peter"/>
    <mother firstName="Jackie"/>
    <sons firstName="David"/>
    <sons firstName="Dylan"/>
    <daughters firstName="Kelly"/>
  </Family>
  
  <Family lastName="Smith">
    <father firstName="John"/>
    <mother firstName="Sarah"/>
    <daughters firstName="Emma"/>
    <daughters firstName="Olivia"/>
  </Family>
</xmi:XMI>
```

## Running the Transformation

### Step 1: Parse the Transformation

First, let's verify our ATL file is syntactically correct:

```bash
swift-atl parse Families2Persons.atl --verbose
```

Expected output:
```
Module: Families2Persons
Source metamodels: IN
Target metamodels: OUT
Matched rules: 2
Helpers: 2
```

### Step 2: Validate the Transformation

Check for semantic correctness:

```bash
swift-atl validate Families2Persons.atl
```

Expected output:
```
Families2Persons.atl: VALID (0 errors, 0 warnings)
```

### Step 3: Execute the Transformation

Run the transformation on your sample data using the ATL source file directly:

```bash
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi
```

The transformation automatically maps the files to the metamodel aliases declared in the ATL file (IN and OUT). You can also be explicit about the mapping if needed:

```bash
swift-atl transform Families2Persons.atl \
    --source IN=sample-Families.xmi \
    --target OUT=output-Persons.xmi
```

## Analysing the Results

After running the transformation, examine the output file:

### File: output-Persons.xmi

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" 
         xmlns="http://www.example.org/persons">
  <!-- Males -->
  <Male fullName="Jim March"/>
  <Male fullName="Brandon March"/>
  <Male fullName="Peter Sailor"/>
  <Male fullName="David Sailor"/>
  <Male fullName="Dylan Sailor"/>
  <Male fullName="John Smith"/>
  
  <!-- Females -->
  <Female fullName="Cindy March"/>
  <Female fullName="Brenda March"/>
  <Female fullName="Jackie Sailor"/>
  <Female fullName="Kelly Sailor"/>
  <Female fullName="Sarah Smith"/>
  <Female fullName="Emma Smith"/>
  <Female fullName="Olivia Smith"/>
</xmi:XMI>
```

### Verification

Notice how:
- Each family member became an individual person
- Full names combine first and last names
- Gender classification is correct based on family roles
- The hierarchical family structure is flattened

### Analysing Transformation Metrics

Get insights into your transformation's complexity:

```bash
swift-atl analyze Families2Persons.atl --metrics all
```

This provides metrics on:
- Lines of code
- Number of rules and helpers
- Complexity measures
- Pattern usage

## Advanced Topics

### Debugging Transformations

Enable verbose output during execution:

```bash
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi \
    --verbose
```

This will display detailed information about:
- Transformation module loading
- Alias mapping (positional or explicit)
- Model loading and object counts
- Transformation execution
- Target model saving
- Execution statistics

### Handling Edge Cases

Consider extending the transformation to handle:
- Families with missing parents
- Members with multiple roles
- Complex name formats

### Performance Optimisation

For large models:
1. Use lazy rules for conditional transformations
2. Optimise helper functions to avoid redundant computations
3. Consider rule ordering for better performance

### Testing Your Transformation

Create a test suite:

```bash
swift-atl test Families2Persons.atl \
    --directory test-cases/ \
    --output test-report.txt
```

## Next Steps

Now that you've completed your first transformation:

1. **Experiment**: Modify the transformation rules
2. **Extend**: Add attributes like age or address
3. **Explore**: Try more complex metamodels
4. **Optimise**: Refactor helpers for elegance
5. **Share**: Document your transformations

## Troubleshooting

### Common Issues

**Parse Errors**: Check ATL syntax, especially:
- Proper helper context declarations
- Matching parentheses and semicolons
- Correct metamodel references

**Validation Warnings**: Often indicate:
- Unused helpers
- Overlapping rule patterns
- Missing type information

**Runtime Errors**: Usually caused by:
- Incorrect model paths
- Metamodel mismatches
- Invalid model instances

## Conclusion

Congratulations! You've successfully created your first ATL transformation with Swift-ATL. This Families to Persons example demonstrates fundamental concepts:

- **Metamodelling**: Defining data structures
- **Helpers**: Creating reusable logic
- **Rules**: Specifying transformation patterns
- **Execution**: Running transformations on real data

These concepts scale to complex industrial transformations. Keep practising, and you'll master model-driven engineering with Swift-ATL!

## Reference

Example files for this tutorial are available in the Swift-ATL distribution under `Tests/swift-atl-tests/Resources/`.

Happy transforming!