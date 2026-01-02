# SVG Diagram Specifications for Swift Modelling Tutorials

This document specifies the SVG diagrams to be created for the Swift Modelling comprehensive tutorial system. Each diagram enhances tutorial content with visual representations of MDE concepts.

---

## 1. Ecore Metamodel Class Diagram

**File**: `ecore-metamodel-overview.svg`
**Tutorial**: Ecore-01
**Purpose**: Illustrate core Ecore metamodel structure

**Content**:
- **Classes**: EPackage, EClass, EAttribute, EReference, EDataType, EEnum
- **Relationships**:
  - EPackage contains EClassifiers (EClass, EDataType, EEnum)
  - EClass contains EStructuralFeatures (EAttribute, EReference)
  - EReference has eType → EClass
  - EClass has eSuperTypes → EClass (inheritance)
- **Styling**:
  - Classes: Blue rounded rectangles
  - Attributes: Green text
  - References: Red arrows with labels
  - Inheritance: Hollow triangle arrows

**Dimensions**: 800x600px

---

## 2. Company Metamodel Instance Diagram

**File**: `company-metamodel-instance.svg`
**Tutorial**: Ecore-02, AQL-01
**Purpose**: Show relationship between metamodel and instances

**Content**:
- **Top Half**: Company metamodel (EPackage with Company, Employee classes)
- **Bottom Half**: TechCorp instance (specific employees)
- **Connection**: "instanceOf" dashed arrows from instances to classes
- **Data**:
  - Company: name="TechCorp"
  - Employees: Alice (30, Engineering), Bob (45, Management), etc.

**Dimensions**: 1000x700px

---

## 3. AQL Query Evaluation Pipeline

**File**: `aql-query-pipeline.svg`
**Tutorial**: AQL-01, AQL-02
**Purpose**: Visualize AQL query execution flow

**Content**:
- **Flow**: Model → Query → Filter → Transform → Result
- **Example**: `library.books->select(b | b.rating >= 4.5)->collect(b | b.title)`
- **Stages**:
  1. **Input**: Library model with books collection
  2. **Select**: Filter books by rating (highlight qualifying books)
  3. **Collect**: Extract titles
  4. **Output**: List of strings
- **Styling**: Flowchart with data visualization at each stage

**Dimensions**: 1200x400px

---

## 4. ATL Transformation Architecture

**File**: `atl-transformation-architecture.svg`
**Tutorial**: Workflow-01, ATL-01
**Purpose**: Explain ATL transformation process

**Content**:
- **Input**: Source metamodel (Shop) + Source model (TechStore)
- **Process**: ATL transformation rules
  - Rule boxes: Shop2SalesReport, Category2CategoryMetric, etc.
  - Helper functions
- **Output**: Target metamodel (Reporting) + Target model (SalesReport)
- **Flow**: Vertical pipeline with metamodels on sides, models in center

**Dimensions**: 1000x800px

---

## 5. MTL Template Execution Flow

**File**: `mtl-template-flow.svg`
**Tutorial**: Workflow-01, MTL-01
**Purpose**: Show MTL code generation process

**Content**:
- **Input**: Sales Report model
- **Templates**: Swift API template, JSON Schema template, Docs template
- **Execution**: Template engine processing
- **Output**: Multiple generated files
- **Annotations**: Show template syntax `[for]`, `[/for]`, variables

**Dimensions**: 1000x600px

---

## 6. MDE Workflow End-to-End

**File**: `mde-workflow-complete.svg`
**Tutorial**: Workflow-01
**Purpose**: Comprehensive MDE pipeline visualization

**Content**:
- **Stage 1**: Metamodel Design (Ecore files)
- **Stage 2**: Instance Creation (XMI files)
- **Stage 3**: Validation (AQL constraints)
- **Stage 4**: Transformation (ATL)
- **Stage 5**: Code Generation (MTL)
- **Stage 6**: Compilation & Testing (Swift)
- **Connections**: Arrows showing data flow
- **Artefacts**: Icons for each file type

**Dimensions**: 1400x600px

---

## 7. Collection Operations Visual Guide

**File**: `aql-collection-operations.svg`
**Tutorial**: AQL-03
**Purpose**: Illustrate AQL collection operations with data

**Content**:
- **Grid Layout**: 4x4 grid of operation examples
- **Operations Shown**:
  - select: Filter with visual highlighting
  - collect: Projection with transformation
  - flatten: Nested to flat conversion
  - sortedBy: Before/after ordering
  - first/last: Subset selection
  - union/intersection: Venn diagrams
- **Data**: Book collections with visual properties (color by rating, size by pages)

**Dimensions**: 1200x1000px

---

## 8. Recursive Navigation Tree

**File**: `recursive-navigation-tree.svg`
**Tutorial**: AQL-05
**Purpose**: Show eAllContents() traversal

**Content**:
- **Tree Structure**: Library at root
  - Categories branch (with subcategories if applicable)
  - Books branch (with authors, comments)
  - Authors branch
- **Annotations**: Show containment relationships
- **Highlighting**: Path from root to specific element
- **Query Result**: Elements returned by eAllContents()

**Dimensions**: 800x900px

---

## 9. Transitive Closure Graph

**File**: `transitive-closure-graph.svg`
**Tutorial**: AQL-05
**Purpose**: Visualize closure() operation on graph

**Content**:
- **Initial**: Author with direct co-authors (books in common)
- **After closure()**: All reachable authors through co-authorship network
- **Graph Visualization**:
  - Nodes: Authors (colored by distance from start)
  - Edges: Co-authorship relationships (books as edge labels)
- **Legend**: Distance levels (0-hop, 1-hop, 2-hop, etc.)

**Dimensions**: 1000x800px

---

## 10. Metamodel Evolution Comparison

**File**: `metamodel-evolution-blog-v1-v2.svg`
**Tutorial**: Workflow-03
**Purpose**: Side-by-side comparison of Blog v1 vs v2

**Content**:
- **Left Side**: Blog v1 metamodel (4 classes)
- **Right Side**: Blog v2 metamodel (6 classes)
- **Annotations**:
  - Green highlights: New attributes/classes
  - Blue highlights: Modified elements
  - Arrows: Migration mappings
- **Change Summary**: Count of additions, modifications

**Dimensions**: 1200x700px

---

## 11. Project Validation Dashboard

**File**: `project-validation-dashboard.svg`
**Tutorial**: Workflow-02
**Purpose**: Visual representation of validation results

**Content**:
- **Summary Panel**: Error/warning counts with icons
- **Constraint List**: 7 constraints with pass/fail indicators
- **Task Timeline**: Gantt-style chart showing task dependencies
- **Violation Highlights**: Red markers on problematic tasks
- **Metrics**: Progress bar, budget utilization, team workload

**Dimensions**: 1200x800px

---

## 12. Type Hierarchy and Polymorphism

**File**: `type-hierarchy-polymorphism.svg`
**Tutorial**: AQL-04
**Purpose**: Explain oclIsKindOf vs oclIsTypeOf

**Content**:
- **Class Hierarchy**: Base class (Book) with subclasses (EBook, Audiobook, PrintBook)
- **Query Results**:
  - oclIsTypeOf(Book): Only exact Book instances
  - oclIsKindOf(Book): All Book and subclass instances
- **Visual Distinction**: Different colors for type matching

**Dimensions**: 800x600px

---

## 13. Tuple Construction Examples

**File**: `tuple-construction-examples.svg`
**Tutorial**: AQL-04
**Purpose**: Show tuple creation from model elements

**Content**:
- **Input**: Book objects with properties
- **Transformation**: AQL collect with Tuple{}
- **Output**: Structured tuple records
- **Examples**:
  - Simple tuple
  - Nested tuple
  - Tuple with computed fields
- **Visual**: Object → Tuple transformation with property mapping

**Dimensions**: 1000x600px

---

## 14. Query Optimisation Before/After

**File**: `query-optimisation-comparison.svg`
**Tutorial**: AQL-05
**Purpose**: Compare inefficient vs optimised queries

**Content**:
- **Top Half**: Inefficient query with multiple traversals
  - Visualisation of repeated work
  - Performance metrics
- **Bottom Half**: Optimised query with let binding
  - Single traversal highlighted
  - Performance improvement
- **Metrics**: Execution time, traversal count, memory usage

**Dimensions**: 1200x800px

---

## 15. Ecore to Swift Code Mapping

**File**: `ecore-to-swift-mapping.svg`
**Tutorial**: Ecore-03
**Purpose**: Show how Ecore elements map to Swift code

**Content**:
- **Left**: Ecore metamodel elements
  - EClass → Swift class/struct
  - EAttribute → Swift property
  - EReference → Swift property (with type)
  - EEnum → Swift enum
- **Right**: Generated Swift code
- **Arrows**: Mapping connections

**Dimensions**: 1000x700px

---

## 16. XMI Serialization Structure

**File**: `xmi-serialization-structure.svg`
**Tutorial**: Ecore-06
**Purpose**: Show XMI file structure and references

**Content**:
- **Tree View**: XMI element hierarchy
- **Annotations**: xmlns declarations, xmi:id attributes
- **References**: href and local ID references with arrows
- **Example**: Library XMI with book references to authors

**Dimensions**: 800x1000px

---

## 17. Cross-Resource References

**File**: `cross-resource-references.svg`
**Tutorial**: Ecore-07
**Purpose**: Illustrate multi-file model references

**Content**:
- **Files**: Multiple XMI documents
- **Resources**: Library.xmi, Authors.xmi, Categories.xmi
- **References**: href="Authors.xmi#//Author[@name='Orwell']"
- **Loading**: ResourceSet with multiple resources
- **Proxy Resolution**: How proxies resolve across files

**Dimensions**: 1000x700px

---

## 18. Complete MDE Stack Overview

**File**: `mde-stack-overview.svg`
**Tutorial**: Introduction, Summary
**Purpose**: High-level overview of entire MDE technology stack

**Content**:
- **Layers** (bottom to top):
  1. **Foundation**: Ecore metamodel
  2. **Modeling**: Instances, XMI persistence
  3. **Querying**: AQL for navigation and analysis
  4. **Transformation**: ATL for model-to-model
  5. **Generation**: MTL for model-to-text
  6. **Runtime**: Swift applications
- **Connections**: How layers interact
- **Examples**: Representative artefacts at each layer

**Dimensions**: 1000x1200px

---

## Implementation Notes

### SVG Generation Approach

1. **Manual Creation**: Use vector graphics tools (Sketch, Figma, Adobe Illustrator)
2. **Programmatic**: Generate from DOT/GraphViz or PlantUML
3. **Hybrid**: Base template with data-driven overlays

### Style Guidelines

- **Color Palette**:
  - Primary: #007AFF (Swift blue)
  - Secondary: #34C759 (success green), #FF3B30 (error red)
  - Neutral: #8E8E93 (gray)
  - Background: #FFFFFF (white), #F2F2F7 (light gray)

- **Typography**:
  - Font: SF Pro (Apple system font) or Helvetica
  - Sizes: 12px (labels), 14px (normal text), 18px (headers)

- **Spacing**:
  - Margin: 20px
  - Padding: 10px between elements
  - Arrow gaps: 5px from shapes

### Accessibility

- Include alt text metadata in SVG
- Ensure 4.5:1 minimum contrast ratio
- Use patterns in addition to colors for differentiation
- Provide text equivalents in tutorial prose

### File Organisation

```
Resources/
├── Diagrams/
│   ├── SVG_DIAGRAM_SPECIFICATIONS.md (this file)
│   ├── ecore-metamodel-overview.svg
│   ├── company-metamodel-instance.svg
│   ├── aql-query-pipeline.svg
│   ├── atl-transformation-architecture.svg
│   ├── mtl-template-flow.svg
│   ├── mde-workflow-complete.svg
│   ├── aql-collection-operations.svg
│   ├── recursive-navigation-tree.svg
│   ├── transitive-closure-graph.svg
│   ├── metamodel-evolution-blog-v1-v2.svg
│   ├── project-validation-dashboard.svg
│   ├── type-hierarchy-polymorphism.svg
│   ├── tuple-construction-examples.svg
│   ├── query-optimisation-comparison.svg
│   ├── ecore-to-swift-mapping.svg
│   ├── xmi-serialisation-structure.svg
│   ├── cross-resource-references.svg
│   └── mde-stack-overview.svg
```

### Tutorial Integration

Each SVG diagram should be referenced in tutorial markdown with:

```markdown
![Description](Diagrams/diagram-filename.svg)

**Figure X**: Caption explaining the diagram's relevance to the tutorial step.
```

---

## Priority Order for Creation

Given resource constraints, create diagrams in this order:

1. **mde-stack-overview.svg** - Essential for introduction
2. **ecore-metamodel-overview.svg** - Foundation for all tutorials
3. **company-metamodel-instance.svg** - Used across multiple tutorials
4. **mde-workflow-complete.svg** - Critical for understanding full pipeline
5. **aql-query-pipeline.svg** - Core AQL concept
6. **atl-transformation-architecture.svg** - Key ATL concept
7. **aql-collection-operations.svg** - Most complex AQL tutorial
8. **query-optimisation-comparison.svg** - Important for performance
9. **metamodel-evolution-blog-v1-v2.svg** - Demonstrates evolution
10. **mtl-template-flow.svg** - Code generation visualisation

Remaining diagrams can be created as needed or time permits.

---

## Maintenance

- **Version Control**: SVG files in git with LFS for large diagrams
- **Updates**: When metamodels change, update corresponding diagrams
- **Alternatives**: Provide text descriptions for accessibility
- **Formats**: Export to PNG (2x resolution) for email/documentation

---

**Total Diagrams Specified**: 18
**Status**: Specification complete, implementation pending
**Last Updated**: 2024-01-15
