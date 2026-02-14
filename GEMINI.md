# Swift Modelling - Gemini Context

## Workspace Overview

This workspace contains the **CLI Tools** for the Swift Modelling Framework. It wraps the core libraries (`swift-ecore`, `swift-atl`, `swift-mtl`) into executable command-line interfaces.

**Primary Goal**: Provide a robust, cross-platform (macOS/Linux) CLI for Model-Driven Engineering (MDE) tasks using Swift 6.

## 🚀 Active CLI Tools

### 1. `swift-ecore` (Core EMF & OCL)
*   **Purpose**: Model validation, conversion, and querying.
*   **Key Commands**:
    *   `validate`: Checks `.xmi`, `.json` (models), and `.ecore` (metamodels) for structural correctness.
    *   `convert`: Converts between XMI and JSON formats (round-trip compatible).
    *   `query`: Runs OCL-like queries (e.g., `find`, `count`, `tree`) on models.
    *   `generate`: (In Progress) Generates Swift/C++/LLVM code from models.
*   **Entry Point**: `Sources/swift-ecore/SwiftEcore.swift`

### 2. `swift-atl` (Model Transformation)
*   **Purpose**: Executing ATL (Atlas Transformation Language) transformations.
*   **Key Commands**:
    *   `transform`: (Implied) Execute `.atl` files against source models to produce target models.
    *   `parse`: Inspect ATL files.
*   **Entry Point**: `Sources/swift-atl/SwiftATL.swift`

### 3. `swift-mtl` (Model-to-Text)
*   **Purpose**: Generating text/code from models using MTL (MOF Model-to-Text / Acceleo) templates.
*   **Key Commands**:
    *   `generate`: Execute `.mtl` templates against models.
    *   `parse`: Debug template structure.
    *   `validate`: Check template syntax.
*   **Entry Point**: `Sources/swift-mtl/SwiftMTL.swift`

## 🛠 Build & Run

The project uses **Swift Package Manager (SPM)**.

```bash
# Build all tools
swift build

# Run specific tools
swift run swift-ecore --help
swift run swift-atl --help
swift run swift-mtl --help

# Run Tests (Includes Tutorial & Integration tests)
swift test
swift test --sanitize=thread  # Recommended for concurrency checks
```

## 🏗 Architecture & Conventions

### 1. Structure
*   **CLI Wrapper**: This repo is primarily a CLI wrapper. It depends on the core libraries defined in `Package.swift`:
    *   `swift-ecore` (Library)
    *   `swift-atl` (Library)
    *   `swift-mtl` (Library)
*   **Sources**:
    *   `Sources/<tool-name>/Commands/`: Contains `ParsableCommand` implementations (using `swift-argument-parser`).
    *   `Sources/<tool-name>/Utilities/`: Helper logic specific to the CLI (e.g., file handling, output formatting).

### 2. Concurrency (Swift 6)
*   **Strict Concurrency**: Enabled.
*   **Pattern**: The CLI (`@main`) runs on the main thread. It spawns `actors` (from the core libraries) for model loading, query execution, and transformation to avoid blocking and ensure thread safety.

### 3. File Formats
*   **XMI**: Standard EMF persistence.
*   **JSON**: Custom JSON format compatible with `pyecore`.
*   **ECore**: Metamodel definitions.
*   **ATL/MTL**: Transformation and Template definitions.

## 📂 Key Directories
*   `Sources/`: Source code for the CLI tools.
*   `Tests/`: Integration and Unit tests.
    *   `TutorialTests/`: Tests that verify the scenarios in `TUTORIAL.md`.
*   `Documentation/`: Project documentation.

## 📝 Current Context (Dec 2025)
*   **Focus**: Integrating `swift-mtl` and ensuring robust CLI UX.
*   **Tutorials**: A comprehensive tutorial plan exists (`TUTORIAL_PLAN.md`) and is partially implemented in `TUTORIAL.md`.
*   **Testing**: The `TutorialTests` target is critical for ensuring the documented examples actually work.
