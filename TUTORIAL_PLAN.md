# Swift MDE Comprehensive Tutorial System Plan

## Overview

Create a multi-level tutorial system for Swift MDE tools (Ecore, ATL, MTL, AQL) using DocC format with executable test validation. Tutorials will mirror industry-standard patterns (Eclipse Wiki tutorials, Vogella guides, Acceleo documentation) while leveraging Swift's interactive documentation system.

**Target**: 40+ tutorials across 4 technologies with 100% test validation coverage

## User Requirements

- **Format**: DocC tutorial syntax (interactive, runnable as tests)
- **Scope**: Ecore/EMF, ATL, MTL, AQL - all technologies
- **Coverage**: Multi-level progression (Beginner → Intermediate → Advanced)
- **Integration**: Both standalone + integrated workflow tutorials
- **Location**: CLI tutorials in swift-modelling, API tutorials in library packages

## Tutorial Hierarchy & Content Detail

### Ecore/EMF Metamodeling (8 tutorials)

**Beginner (3)**
1.  **Creating Your First Metamodel** (20 min)
    *   **Goal**: Create a basic `Person` class.
    *   **Resources**: 
        *   `step-01-empty-package.ecore`: Basic EPackage definition.
        *   `step-02-person-class.ecore`: Adds `Person` EClass.
        *   `step-03-person-attributes.ecore`: Adds `name` EAttribute.
    *   **Content**: Define EPackage, EClass (Person), EAttribute (name: String).
2.  **Working with Model Instances** (25 min)
    *   **Goal**: Create instances of `Person` and validate them.
    *   **Resources**: 
        *   `step-08-person-instance.xmi`: Instance data.
    *   **Content**: XMI structure, `xsi:type`, attribute values, validation commands.
3.  **Metamodel Relationships** (30 min)
    *   **Goal**: Model Companies and Employees.
    *   **Resources**: 
        *   `step-04-company-class.ecore`: Adds `Company` class.
        *   `step-12-company-with-employees-ref.ecore`: Adds containment reference.
    *   **Content**: EReference (containment=true), cardinality (0..*), bidirectional references (`eOpposite`).

**Intermediate (3)**
4.  **Advanced Metamodel Features** (35 min)
    *   **Goal**: Add Enums and Abstract classes.
    *   **Resources**: 
        *   `step-17-employment-status-enum.ecore`: Defines `EmploymentStatus` EEnum.
        *   `step-21-abstract-person.ecore`: Makes `Person` abstract.
    *   **Content**: EEnum literals, abstract EClass, inheritance (`eSuperTypes`).
5.  **JSON and XMI Formats** (30 min)
    *   **Goal**: Convert models between formats.
    *   **Resources**: 
        *   `step-24-convert-to-json.sh`: Conversion script.
        *   `step-25-company-model.json`: Resulting JSON.
    *   **Content**: CLI `convert` command, JSON schema mapping, round-trip fidelity.
6.  **Querying Models with AQL** (40 min)
    *   **Goal**: Basic model analysis.
    *   **Resources**: 
        *   `step-31-all-employees.aql`: Select all instances.
        *   `step-35-count-by-status.aql`: Filter and count.
    *   **Content**: `select`, `collect`, `size()` operations, navigation (`.`).

**Advanced (2)**
7.  **Cross-Resource References** (45 min)
    *   **Goal**: Split models across files.
    *   **Resources**: 
        *   `ReferenceTest.xmi`: Root model.
        *   `Referenced.xmi`: Model being pointed to.
    *   **Content**: Proxies, `href` syntax (`href="file.xmi#//ID"`), resource sets, lazy loading.
8.  **Building Domain-Specific Languages** (60 min)
    *   **Goal**: Complete DSL design.
    *   **Resources**: Custom DSL metamodel (e.g., `StateMachine.ecore`).
    *   **Content**: EOperations, EDataTypes, validation constraints, complete semantic model.

### ATL Transformations (8 tutorials)

**Beginner (3)**
1.  **Your First ATL Transformation** (30 min)
    *   **Goal**: Families to Persons (Classic).
    *   **Resources**: 
        *   `Families.ecore`: Source metamodel.
        *   `Persons.ecore`: Target metamodel.
        *   `Families2Persons.atl`: Transformation module.
    *   **Content**: Matched rules (`rule Member2Male`), `from`/`to` blocks, simple bindings (`fullName <- s.firstName`).
2.  **ATL Helpers and Guards** (25 min)
    *   **Goal**: Filter logic and reusable expressions.
    *   **Resources**: `Families2Persons_Helpers.atl`.
    *   **Content**: 
        *   Helpers: `helper context Families!Member def: isFemale(): Boolean = ...`
        *   Guards: `rule Member2Female { from s : Families!Member (s.isFemale()) ... }`
3.  **Working with Collections** (30 min)
    *   **Goal**: Iterate and transform lists.
    *   **Resources**: `Families2Persons_Collections.atl`.
    *   **Content**: `->collect()`, `->select()`, `->reject()`, `->exists()`, `->forAll()`.

**Intermediate (3)**
4.  **Advanced Rule Patterns (Lazy Rules)** (40 min)
    *   **Goal**: On-demand transformation using Lazy Rules.
    *   **Resources**: 
        *   `UML2Relational.atl`: Transformation file.
    *   **Content**: 
        *   `lazy rule`: Explicitly called rules.
        *   `unique lazy rule`: Caching results for same input (e.g., `TypeToSQLType`).
        *   Invocation: `thisModule.RuleName(s)`.
5.  **OCL Expressions Deep Dive** (45 min)
    *   **Goal**: Complex logic.
    *   **Resources**: `AdvancedLogic.atl`.
    *   **Content**: 
        *   `let`: Local variables (`let x = ... in ...`).
        *   `if-then-else`: Conditional logic.
        *   `Tuple`: Anonymous structures (`Tuple { name = 'x', val = 1 }`).
6.  **Debugging Transformations** (35 min)
    *   **Goal**: Troubleshoot issues.
    *   **Resources**: `DebugExample.atl` (with intentional errors).
    *   **Content**: `--verbose` flag, interpreting error messages, `debug()` operation, tracing.

**Advanced (2)**
7.  **Complex Model Transformations** (60 min)
    *   **Goal**: Multiple input/output models.
    *   **Resources**: `MultiInput.atl`.
    *   **Content**: `create OUT1: MM1, OUT2: MM2 from IN1: MM3, IN2: MM4`. Handling cross-model references.
8.  **Performance Optimization** (50 min)
    *   **Goal**: Efficient transformations.
    *   **Resources**: Large model benchmarks.
    *   **Content**: Rule ordering, avoiding expensive queries, memory management, optimizing `allInstances`.

### MTL Code Generation (8 tutorials)

**Beginner (3)**
1.  **Hello World Template** (15 min)
    *   **Goal**: Basic template structure.
    *   **Resources**: 
        *   `mtl-step-01-module.mtl`: Module declaration.
        *   `mtl-step-02-template.mtl`: Main template.
    *   **Content**: `[module]`, `[template public main]`, static text output.
2.  **Expressions and Variables** (20 min)
    *   **Goal**: Dynamic content.
    *   **Resources**: 
        *   `mtl-step-09-arithmetic.mtl`: Math ops.
        *   `mtl-step-10-string-concat.mtl`: String ops.
    *   **Content**: `[variable/]`, string operations (`+`, `concat`), standard OCL library.
3.  **Control Flow** (25 min)
    *   **Goal**: Logic in templates.
    *   **Resources**: 
        *   `mtl-step-17-simple-if.mtl`: Conditionals.
        *   `mtl-step-35-iterate-collection.mtl`: Loops.
    *   **Content**: `[if (condition)]...[else]...[/if]`, `[for (i : Type | collection)]...[/for]`, `[let]`.

**Intermediate (3)**
4.  **File Blocks** (30 min)
    *   **Goal**: Generating files.
    *   **Resources**: 
        *   `mtl-step-22-basic-file.mtl`: Single file.
        *   `mtl-step-25-file-modes.mtl`: Modes.
    *   **Content**: `[file (name, overwrite, encoding)]`, file appending vs overwriting.
5.  **Queries and Macros** (35 min)
    *   **Goal**: Reusable logic.
    *   **Resources**: 
        *   `mtl-step-28-simple-macro.mtl`: Macro definition.
        *   `mtl-step-12-simple-query.mtl`: Query definition.
    *   **Content**: 
        *   `[query public name(args) : Type = expression /]`.
        *   `[macro public name(args)]...[/macro]` (Template fragments).
6.  **Code Generation from Models** (40 min)
    *   **Goal**: Ecore to Swift.
    *   **Resources**: 
        *   `mtl-step-39-class-helper.mtl`: Helper for class names.
        *   `ClassGenerator.mtl`: Main generator.
    *   **Content**: Generating Swift struct/class, mapping properties, handling imports.

**Advanced (2)**
7.  **Protected Areas** (30 min)
    *   **Goal**: Preserving user code.
    *   **Resources**: `mtl-step-36-basic-protected.mtl`.
    *   **Content**: `[protected ('id')]...[/protected]`, custom start/end markers, handling manual edits.
8.  **Complete Code Generator** (60 min)
    *   **Goal**: Full project generation.
    *   **Resources**: `mtl-step-40-generate-project.sh`.
    *   **Content**: Multiple files (Package.swift, Sources), folder structure, complex logic, integration with build systems.

### AQL Query Language (5 tutorials)

**Beginner (2)**
1.  **AQL Basics** (20 min)
    *   **Resources**: `step-31-all-employees.aql`.
    *   **Content**: Navigation (`.` operator), literals (String, Integer), boolean logic.
2.  **Filtering and Selection** (25 min)
    *   **Resources**: `step-33-fulltime-employees.aql`.
    *   **Content**: `select(e | e.status = #FullTime)`, `reject(e | ...)` operations.

**Intermediate (2)**
3.  **Collection Operations** (30 min)
    *   **Resources**: `step-35-count-by-status.aql`.
    *   **Content**: `collect`, `flatten`, `size`, `includes`, `excludes`.
4.  **AQL in MTL Templates** (35 min)
    *   **Resources**: `mtl-step-34-navigate-refs.mtl`.
    *   **Content**: Using AQL expressions inside MTL `[Expression /]` blocks, calling queries.

**Advanced (1)**
5.  **Complex Queries** (40 min)
    *   **Resources**: `step-38-company-stats.aql`.
    *   **Content**: Nested iterations, cross-model joins, aggregation (sum, min, max).

### Integrated Workflows (3 tutorials)

1.  **Complete MDE Workflow: From Metamodel to Code** (90 min)
   - Step 1: Define `Company.ecore` (Metamodel).
   - Step 2: Create `MyCompany.xmi` (Model).
   - Step 3: ATL Transform `Company2Department.atl` (Transformation).
   - Step 4: MTL Generate `SwiftCode.mtl` (Code Generation).
   - Step 5: Verify output code.
2.  **Model Refactoring Pipeline** (75 min)
   - Step 1: Legacy Model (XMI).
   - Step 2: ATL Migration (Legacy2Modern).
   - Step 3: Validation (Constraint check).
3.  **Cross-Format Integration** (60 min)
   - Step 1: Java EMF (XMI) input.
   - Step 2: Swift ATL (JSON) intermediate.
   - Step 3: Web API usage (JSON output).

## File Structure

### swift-modelling (CLI Tutorials)

```
swift-modelling/
├── Documentation/
│   └── SwiftModelling.docc/
│       ├── SwiftModelling.md                    # Root catalog
│       ├── Tutorials/
│       │   ├── Tutorials.md                     # Table of contents
│       │   ├── CLI-Workflows/
│       │   │   ├── 01-complete-mde-workflow.tutorial
│       │   │   ├── 02-model-refactoring-pipeline.tutorial
│       │   │   └── 03-cross-format-integration.tutorial
│       │   ├── Ecore-CLI/
│       │   │   ├── 01-first-metamodel.tutorial
│       │   │   ├── 02-model-instances.tutorial
│       │   │   ├── 03-metamodel-relationships.tutorial
│       │   │   ├── 04-advanced-features.tutorial
│       │   │   ├── 05-xmi-json-conversion.tutorial
│       │   │   ├── 06-cli-queries.tutorial
│       │   │   ├── 07-cross-resource-refs.tutorial
│       │   │   └── 08-building-dsls.tutorial
│       │   ├── ATL-CLI/
│       │   │   ├── 01-first-transformation.tutorial
│       │   │   ├── 02-helpers-guards.tutorial
│       │   │   ├── 03-working-collections.tutorial
│       │   │   ├── 04-advanced-patterns.tutorial
│       │   │   ├── 05-ocl-deep-dive.tutorial
│       │   │   ├── 06-debugging.tutorial
│       │   │   ├── 07-complex-transformations.tutorial
│       │   │   └── 08-performance.tutorial
│       │   └── MTL-CLI/
│       │       ├── 01-hello-world.tutorial
│       │       ├── 02-expressions-variables.tutorial
│       │       ├── 03-control-flow.tutorial
│       │       ├── 04-file-blocks.tutorial
│       │       ├── 05-queries-macros.tutorial
│       │       ├── 06-code-from-models.tutorial
│       │       ├── 07-protected-areas.tutorial
│       │       └── 08-complete-generator.tutorial
│       └── Resources/
│           ├── Code/                            # Code snippets per tutorial
│           ├── Images/                          # Diagrams and screenshots
│           ├── Metamodels/                      # .ecore files
│           ├── Models/                          # .xmi/.json files
│           ├── Transformations/                 # .atl files
│           └── Templates/                       # .mtl files
└── Tests/
    └── TutorialTests/
        ├── EcoreTutorialTests.swift
        ├── ATLTutorialTests.swift
        ├── MTLTutorialTests.swift
        └── WorkflowTutorialTests.swift
```

### Library Packages (API Tutorials)

Each of swift-ecore, swift-atl, swift-mtl, swift-aql gets:
```
package-name/
├── Documentation/
│   └── PackageName.docc/
│       ├── PackageName.md
│       ├── Tutorials/
│       │   ├── Beginner/
│       │   ├── Intermediate/
│       │   └── Advanced/
│       └── Resources/
└── Tests/
    └── PackageTests/
        └── TutorialValidationTests/
```

## DocC Tutorial Format

Standard structure for each tutorial:

```markdown
@Tutorial(time: <minutes>, projectFiles: "<optional-zip>") {
    @Intro(title: "<Title>") {
        <Hook and overview>
        @Image(source: "<image>", alt: "<description>")
    }

    @Section(title: "<Section Title>") {
        @ContentAndMedia {
            <Concept explanation>
            @Image(source: "<diagram>", alt: "<description>")
        }

        @Steps {
            @Step {
                <Action description>
                @Code(name: "<filename>", file: "<resource-file>")
            }
            <!-- 3-6 steps per section -->
        }
    }

    <!-- 2-4 sections per tutorial -->

    @Assessments {
        @MultipleChoice {
            <Question>
            @Choice(isCorrect: true) {
                <Answer>
                @Justification {<Explanation>}
            }
            <!-- 2-4 choices -->
        }
        <!-- 2-3 questions -->
    }
}
```

## Tutorial-Test Integration

### Test Pattern

Each tutorial step is validated by corresponding test:

```swift
@Suite("Tutorial: Creating Your First Metamodel")
struct EcoreTutorial01Tests {

    @Test("Step 1: Create Person class")
    func testStep01CreatePersonClass() async throws {
        // Validate code from Step 1
        let personClass = EClass(name: "Person")
        #expect(personClass.name == "Person")
    }

    @Test("Step 2: Add name attribute")
    func testStep02AddNameAttribute() async throws {
        // Validate Step 2 code
    }

    // ... tests for each tutorial step
}
```

### Resource Organization

```
Tests/TutorialTests/Resources/
├── Tutorial-01-First-Metamodel/
│   ├── step-01-person-class.ecore
│   ├── step-02-with-name.ecore
│   └── final-complete.ecore
├── Tutorial-02-Model-Instances/
│   ├── metamodel.ecore
│   ├── step-01-empty-instance.xmi
│   └── final-complete.xmi
└── ...
```

### Validation Strategy

Three-tier validation:
1. **Syntax**: CLI commands succeed/fail correctly
2. **Semantic**: Output matches expected structure
3. **Round-trip**: Save/load produces identical models

## Implementation Phases

### Phase 1: Foundation (2 weeks)

**Goal**: Set up infrastructure and first tutorial

**Tasks**:
- Create DocC catalog structure in swift-modelling
- Set up tutorial test infrastructure
- Convert TUTORIAL.md to DocC format (ATL-01)
- Create supporting resources (images, code files)
- Implement tutorial validation tests

**Files**:
- `swift-modelling/Documentation/SwiftModelling.docc/SwiftModelling.md`
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/Tutorials.md`
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/ATL-CLI/01-first-transformation.tutorial`
- `swift-modelling/Tests/TutorialTests/ATL01Tests.swift`
- `swift-modelling/Documentation/SwiftModelling.docc/Resources/`

### Phase 2: Ecore Path (2 weeks)

**Goal**: Complete beginner and intermediate Ecore tutorials

**Tasks**:
- Create tutorials 1-6 for Ecore
- Port test resources to tutorial format
- Create diagrams (metamodel structures, relationships)
- Write validation tests

**Files**:
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/Ecore-CLI/01-06-*.tutorial`
- `swift-modelling/Tests/TutorialTests/EcoreTutorialTests.swift`

### Phase 3: MTL Path (2 weeks)

**Goal**: Transform MTL examples into DocC tutorials

**Tasks**:
- Convert 7 MTL examples to tutorial format
- Add progression and narrative
- Create intermediate tutorial (code from models)
- Write advanced tutorial (complete generator)

**Files**:
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/MTL-CLI/01-08-*.tutorial`
- `swift-modelling/Tests/TutorialTests/MTLTutorialTests.swift`

### Phase 4: ATL Path Completion (2 weeks)

**Goal**: Complete ATL tutorial series

**Tasks**:
- Create tutorials 2-8 for ATL
- Add complex transformation examples
- Create performance optimization tutorial
- Write comprehensive tests

**Files**:
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/ATL-CLI/02-08-*.tutorial`
- Additional test coverage

### Phase 5: AQL Path (1 week)

**Goal**: Create AQL tutorial series

**Tasks**:
- Create 5 AQL tutorials
- Integrate with MTL tutorials
- Create cross-tutorial references

**Files**:
- AQL tutorials (location TBD - may go in swift-aql package)

### Phase 6: Integrated Workflows (2 weeks)

**Goal**: Create end-to-end workflow tutorials

**Tasks**:
- Design complete MDE workflow example
- Create model refactoring pipeline
- Build cross-format integration tutorial
- Add comprehensive testing

**Files**:
- `swift-modelling/Documentation/SwiftModelling.docc/Tutorials/CLI-Workflows/01-03-*.tutorial`
- Workflow test suites

### Phase 7: Library Package Tutorials (3 weeks)

**Goal**: Create API-focused tutorials in library packages

**Tasks**:
- Set up DocC catalogs in swift-ecore, swift-atl, swift-mtl, swift-aql
- Create programmatic API tutorials
- Document advanced patterns
- Cross-reference with CLI tutorials

**Files**:
- `swift-ecore/Documentation/ECore.docc/`
- `swift-atl/Documentation/ATL.docc/`
- `swift-mtl/Documentation/MTL.docc/`
- `swift-aql/Documentation/AQL.docc/`

### Phase 8: Polish & Launch (2 weeks)

**Goal**: Finalize documentation and publish

**Tasks**:
- Review all tutorials for consistency
- Add missing diagrams and screenshots
- Optimize tutorial progression
- Generate static documentation site
- Create quick-start guide

**Deliverables**:
- Complete tutorial suite (40+ tutorials)
- Static documentation site
- Quick-start guide

## Migration from Existing Resources

### TUTORIAL.md → DocC

**From**: `swift-modelling/TUTORIAL.md`
**To**: `Documentation/SwiftModelling.docc/Tutorials/ATL-CLI/01-first-transformation.tutorial`

**Process**:
1. Extract sections into @Section blocks
2. Convert code blocks to @Code with file references
3. Add @Step structure with progressive disclosure
4. Create supporting resource files
5. Add diagrams
6. Create assessment questions

### MTL Examples → Tutorials

**From**: `swift-mtl/Examples/01-hello-world.mtl` through `07-protected-areas.mtl`
**To**: Multiple tutorials with progression

**Mapping**:
- Examples 01-02 → Beginner Tutorial 01-02
- Example 03 → Beginner Tutorial 03
- Example 04 → Intermediate Tutorial 04
- Examples 05-06 → Intermediate Tutorial 05
- Example 07 → Advanced Tutorial 07

### Test Resources → Tutorial Resources

**From**: Scattered across `Tests/*/Resources/`
**To**: Organized by tutorial in `Documentation/SwiftModelling.docc/Resources/`

**Key Migrations**:
- `Tests/swift-atl-tests/Resources/Families2Persons/*` → ATL Tutorial 01 resources
- `Tests/swift-mtl-tests/Resources/templates/*.mtl` → MTL Tutorial resources
- `Tests/swift-ecore-tests/Resources/*.ecore` → Ecore Tutorial resources

## Success Criteria

### Coverage
- 40+ tutorials across 4 technologies
- 100% of tutorial steps validated by tests
- All code examples as separate files
- 80%+ tutorials have diagrams

### Quality
- Average duration: 20-45 minutes per tutorial
- 12-20 interactive steps per tutorial
- Clear beginner → intermediate → advanced progression
- 90%+ tutorials link to related content

### Validation
- All tutorial code compiles
- 100% of tutorial validation tests pass
- Zero DocC warnings/errors in build

## Critical Files

**Phase 1 (Foundation)**:
1. `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Documentation/SwiftModelling.docc/SwiftModelling.md`
2. `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Documentation/SwiftModelling.docc/Tutorials/Tutorials.md`
3. `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Documentation/SwiftModelling.docc/Tutorials/ATL-CLI/01-first-transformation.tutorial`
4. `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Tests/TutorialTests/ATL01Tests.swift`
5. `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Package.swift` (add DocC catalog configuration)

**Reference Files**:
- `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/TUTORIAL.md` (convert to DocC)
- `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-mtl/Examples/*.mtl` (convert to tutorials)
- `/Users/rh/Dropbox/Developer/src/other/MetaModels/swift-modelling/Tests/swift-atl-tests/Resources/Families2Persons/` (migrate to tutorial resources)

## Industry Standards Referenced

- **Acceleo**: "Getting Started 33" tutorial, UML-to-Java pattern
- **EMF**: Vogella tutorial progression, visual editor workflow
- **ATL**: "Simple ATL Transformation" tutorial, Families2Persons canonical example
- **DocC**: Apple's tutorial syntax, interactive step-by-step format
- **Swift.org**: DocC tutorial syntax documentation

## Key Design Decisions

1. **DocC Format**: Leverages Swift's native documentation system for interactive, testable tutorials
2. **Dual Location**: CLI tutorials in swift-modelling, API tutorials in library packages
3. **Test-Driven**: Every tutorial step validated by executable tests
4. **Progressive Disclosure**: Clear beginner → advanced path for each technology
5. **Integration Focus**: Both standalone + integrated workflow tutorials
6. **Resource Organization**: Centralized resources in DocC catalog
7. **Mirror Industry**: Follow established MDE tutorial patterns (Eclipse Wiki, Vogella, Acceleo)