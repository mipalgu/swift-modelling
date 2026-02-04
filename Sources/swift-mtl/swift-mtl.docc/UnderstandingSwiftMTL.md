# Understanding swift-mtl

Learn the key concepts behind the swift-mtl command-line tool.

## Overview

The swift-mtl CLI tool executes MTL (Model-to-Text Language)
templates that generate code and text artefacts from models.
Understanding template structure, expression evaluation, protected
regions, and generation strategies is essential for effective code
generation.

## Model-to-Text Transformation

### What is Model-to-Text?

Model-to-text transformation generates text (usually code) from
models:

```
Model (M1)          Template           Generated Code
company.xmi    ──────────────────>   Employee.swift
(Company MM)                          Department.swift
```

Templates combine:
- **Static text** - Literal code/text appearing in output
- **Dynamic content** - Values extracted from the model
- **Control flow** - Loops and conditionals

### Template-Based Generation

MTL templates are text files with embedded expressions:

```mtl
[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] {           [comment Dynamic: class name /]
    [for (attr : Attribute | c.attributes)]
    var [attr.name/]: [attr.type/]
    [/for]
}                           [comment Static: class structure /]
[/file]
[/template]
```

Static portions appear verbatim, dynamic portions are evaluated
against the model.

## Template Structure

### Module Declaration

Every template module starts with a declaration:

```mtl
[module generate('http://www.example.org/mymodel')]
```

The URI identifies the metamodel. The tool uses this to:
- Load the correct metamodel
- Enable type checking
- Resolve element references

### Comments

Document templates with comments:

```mtl
[comment This generates the main class structure /]
[comment encoding = UTF-8 /]
```

Comments don't appear in generated output.

### Templates

Templates are generation entry points or reusable blocks:

```mtl
[template public main(model : Package)]
[comment Entry point for generation /]
[for (c : Class | model.eAllContents(Class))]
[generateClass(c)/]
[/for]
[/template]

[template public generateClass(c : Class)]
[comment Generates a single class /]
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] { }
[/file]
[/template]
```

The `main` template is the default entry point.

### Queries

Queries are reusable expressions:

```mtl
[query public publicAttributes(c : Class) : Sequence(Attribute) =
    c.attributes->select(a | a.visibility = 'public')
/]
```

Call in templates or other queries:

```mtl
[for (attr : Attribute | c.publicAttributes())]
public var [attr.name/]: [attr.type/]
[/for]
```

## Blocks and Expressions

### Text Blocks

Plain text appears directly in output:

```mtl
This is static text.
It appears exactly as written.
```

### Expression Blocks

Expressions are evaluated and inserted:

```mtl
Class name: [c.name/]
Uppercase: [c.name.toUpper()/]
Count: [c.attributes->size()/]
```

The `/]` closes the expression and inserts the result.

### File Blocks

File blocks create output files:

```mtl
[file (expression, overwrite, encoding)]
... content ...
[/file]
```

Parameters:
- **expression** - Filename (can include paths)
- **overwrite** - `false` to create new, `true` to append
- **encoding** - Character encoding

Example:

```mtl
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] { }
[/file]
```

Creates `Employee.swift`, `Department.swift`, etc.

### For Blocks

Iterate over collections:

```mtl
[for (variable : Type | collection)]
... body ...
[/for]
```

Options:
- `separator(text)` - Text between iterations
- `before(text)` - Text before loop (if not empty)
- `after(text)` - Text after loop (if not empty)

Example:

```mtl
[for (attr : Attribute | c.attributes) separator(', ')]
[attr.name/]: [attr.type/][/for]
```

Output: `name: String, age: Int, id: Int`

### If Blocks

Conditional generation:

```mtl
[if (condition)]
... generated if true ...
[elseif (condition2)]
... generated if condition2 true ...
[else]
... generated if all false ...
[/if]
```

Example:

```mtl
[if (c.isAbstract)]
abstract class [c.name/]
[else]
class [c.name/]
[/if]
```

### Let Blocks

Define local variables:

```mtl
[let variable : Type = expression]
... use variable ...
[/let]
```

Example:

```mtl
[let className : String = c.name.toUpperFirst()]
class [className/] {
    init() {
        print("Creating [className/]")
    }
}
[/let]
```

Variables are scoped to the let block.

## Protected Regions

### Purpose

Protected regions preserve user code across regeneration. This
enables a hybrid approach:
- Generator produces structure
- Developers add custom logic
- Regeneration preserves customisations

### Syntax

```mtl
[protected (uniqueID)]
... default content (first generation only) ...
[/protected]
```

The `uniqueID` must be unique within the file. Use expressions:

```mtl
[protected ('custom-' + c.name)]
// Custom code here
[/protected]
```

### Lifecycle

**First Generation**:

```swift
class Employee {
    var name: String

    // [protected (custom-Employee)]
    // Add your custom code here
    // [/protected]
}
```

**User Adds Code**:

```swift
class Employee {
    var name: String

    // [protected (custom-Employee)]
    func displayName() -> String {
        return "Name: \(name)"
    }
    // [/protected]
}
```

**Regeneration**:

Model changes, new attribute added:

```swift
class Employee {
    var name: String
    var age: Int         // [comment New attribute /]

    // [protected (custom-Employee)]
    func displayName() -> String {
        return "Name: \(name)"
    }
    // [/protected]
}
```

The `displayName()` method is preserved.

### Implementation

When `--preserve-protected` is enabled:

1. Tool scans existing files for protected regions
2. Stores region content keyed by ID
3. Generates new file content
4. Replaces protected region content from store
5. Writes final result

### Best Practices

**Use stable IDs**:

```mtl
[comment Good - stable across regeneration /]
[protected ('methods-' + c.name)]

[comment Bad - might change /]
[protected ('methods-' + c.attributes->size())]
```

**Document protected regions**:

```mtl
[protected ('init-' + c.name)]
// Custom initialisation logic
// Add additional setup here
[/protected]
```

**Back up before regeneration**:

```bash
swift-mtl extract-protected src/ --output backup.json
```

## Expression Language

MTL uses OCL (Object Constraint Language) for expressions.

### Navigation

Access model features:

```mtl
[c.name/]                   [comment Attribute /]
[c.package/]                [comment Reference /]
[c.package.name/]           [comment Chained navigation /]
[c.attributes/]             [comment Collection /]
```

### Collections

OCL collection operations:

```mtl
[c.attributes->size()/]                  [comment Count /]
[c.attributes->first()/]                 [comment First element /]
[c.attributes->select(a | a.required)/]  [comment Filter /]
[c.attributes->collect(a | a.name)/]     [comment Map /]
[c.attributes->exists(a | a.isId)/]      [comment Any match /]
[c.attributes->forAll(a | a.valid)/]     [comment All match /]
```

### Strings

String operations:

```mtl
[name.toUpper()/]               [comment Uppercase /]
[name.toLower()/]               [comment Lowercase /]
[name.concat('.swift')/]        [comment Concatenate /]
[name.substring(0, 5)/]         [comment Substring /]
[name.size()/]                  [comment Length /]
[name.startsWith('get')/]       [comment Prefix check /]
[name.replaceAll('_', '')/]     [comment Replace /]
```

### Conditionals

Inline conditionals:

```mtl
[if c.isAbstract then 'abstract ' else '' endif/]
```

### Type Operations

Type checking and casting:

```mtl
[if c.oclIsKindOf(Entity)]
// Entity-specific generation
[/if]

[c.oclAsType(Entity).entityId/]
```

## Template Visibility

Control template access:

### Public Templates

Callable from other modules:

```mtl
[template public generateClass(c : Class)]
[comment Can be imported and used elsewhere /]
[/template]
```

### Protected Templates

Callable from submodules:

```mtl
[template protected generateHelper(c : Class)]
[comment Available to modules that extend this one /]
[/template]
```

### Private Templates

Only within this module:

```mtl
[template private internalHelper(c : Class)]
[comment Only callable within this module /]
[/template]
```

## Template Inheritance

### Extending Modules

```mtl
[module derived extends base]
```

The `derived` module can:
- Call base templates
- Override base templates
- Add new templates

### Overriding Templates

```mtl
[template public generateClass(c : Class) overrides generateClass]
[comment Custom generation /]
class [c.name/] {
    [comment Call base implementation /]
    [super/]

    [comment Add additional content /]
    // Extended functionality
}
[/template]
```

The `[super/]` directive invokes the base template.

## Compilation and Optimisation

### Bytecode Compilation

Compile templates to bytecode:

```bash
swift-mtl compile Template.mtl --optimise
```

Creates `Template.emtl` with:
- Pre-parsed template structure
- Type-checked expressions
- Optimised evaluation paths

**Execution time improvement**: 5-10× faster typical.

### Optimisation Passes

The `--optimise` flag enables:

- **Constant folding** - Evaluate constant expressions at compile time
- **Expression simplification** - Reduce complex expressions
- **Loop optimisation** - Efficient iteration
- **Template inlining** - Inline small templates

### When to Compile

**Compile for**:
- Production generation
- Batch processing
- Large models
- Repeated generation

**Don't compile for**:
- Template development (rapid iteration)
- One-off generation
- Debugging templates

## Generation Strategies

### Overwrite Modes

Control how existing files are handled:

**All** - Always overwrite:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite all
```

Use when starting fresh or regenerating everything.

**None** - Never overwrite:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite none
```

Use for incremental generation of new files only.

**Smart** (default) - Intelligent overwriting:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite smart
```

Smart mode:
- Overwrites files with generation markers
- Preserves manually-created files
- Respects protected regions
- Safest for iterative development

### File Encoding

Specify character encoding:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --encoding UTF-8
```

Common encodings: UTF-8, ISO-8859-1, ASCII.

### Template Properties

Pass configuration to templates:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --property "version=1.0.0" \
    --property "author=Generator"
```

Access in templates:

```mtl
// Version: [getProperty('version')/]
// Author: [getProperty('author')/]
```

Use for:
- Package names
- Version numbers
- Copyright information
- Build configuration

## Validation

### Syntax Validation

Check template syntax:

```bash
swift-mtl validate Template.mtl
```

Verifies:
- Template structure
- Block nesting
- Expression syntax
- File block parameters

### Semantic Validation

Validate against metamodel:

```bash
swift-mtl validate Template.mtl \
    --metamodel MyModel.ecore \
    --strict
```

Verifies:
- Referenced classes exist
- Attributes and references are valid
- Type compatibility
- Query well-formedness

### Validation Reports

Generate detailed reports:

```bash
swift-mtl validate Template.mtl \
    --metamodel MyModel.ecore \
    --report validation.json \
    --format json
```

Reports include:
- Error locations (line, column)
- Error descriptions
- Severity levels
- Suggested fixes

## Best Practices

### Organise Templates Logically

One template per concept:

```mtl
[template public generateClass(c : Class)]...[/template]
[template public generateProtocol(p : Protocol)]...[/template]
[template public generateExtension(e : Extension)]...[/template]
```

Group related templates in modules.

### Use Queries for Complex Logic

Extract complex expressions:

```mtl
[comment Good /]
[query public requiredAttributes(c : Class) : Sequence(Attribute) =
    c.attributes->select(a | a.required and not a.derived)
/]

[template public generateClass(c : Class)]
[for (attr : Attribute | c.requiredAttributes())]
var [attr.name/]: [attr.type/]
[/for]
[/template]

[comment Bad - complex inline expression /]
[template public generateClass(c : Class)]
[for (attr : Attribute | c.attributes->select(a | a.required and not a.derived))]
var [attr.name/]: [attr.type/]
[/for]
[/template]
```

### Preserve User Code

Use protected regions for customisation points:

```mtl
[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] {
    [comment Generated properties /]
    [for (attr : Attribute | c.attributes)]
    var [attr.name/]: [attr.type/]
    [/for]

    [comment User can add custom methods /]
    // [protected ('methods-' + c.name)]
    // Add custom methods here
    // [/protected]
}
[/file]
[/template]
```

### Validate Before Generation

Always validate models:

```bash
swift-ecore validate input.xmi --metamodel MyModel.ecore
swift-mtl generate Template.mtl --model input.xmi --output generated/
```

Invalid models produce incorrect code.

### Compile for Production

```bash
# Development
swift-mtl generate Template.mtl --model test.xmi --output /tmp/test/

# Production
swift-mtl compile Template.mtl --optimise
swift-mtl generate Template.emtl --model prod.xmi --output generated/
```

### Test with Edge Cases

Test templates with:
- Empty collections
- Null/undefined values
- Minimum/maximum cardinalities
- All enumeration values
- Deep nesting

### Version Generated Code

Mark generated files:

```mtl
// Generated by swift-mtl [getProperty('version')/]
// Date: [now()/]
// DO NOT EDIT - changes will be overwritten
```

Helps users identify generated vs manual code.

## Integration Patterns

### Validation Pipeline

```bash
#!/bin/bash
# 1. Validate model
swift-ecore validate input.xmi --metamodel Model.ecore --strict
if [ $? -ne 0 ]; then
    echo "Model validation failed"
    exit 1
fi

# 2. Validate template
swift-mtl validate Template.mtl --metamodel Model.ecore --strict
if [ $? -ne 0 ]; then
    echo "Template validation failed"
    exit 1
fi

# 3. Generate
swift-mtl generate Template.mtl --model input.xmi --output generated/
```

### Transform-Generate Pipeline

```bash
# Transform model
swift-atl transform Process.atl \
    --source input.xmi \
    --target processed.xmi

# Validate transformation result
swift-ecore validate processed.xmi \
    --metamodel Processed.ecore

# Generate code
swift-mtl generate Template.mtl \
    --model processed.xmi \
    --output generated/
```

### Multi-Stage Generation

```bash
# Stage 1: Generate interfaces
swift-mtl generate GenerateInterfaces.mtl \
    --model design.xmi \
    --output generated/interfaces/

# Stage 2: Generate implementations
swift-mtl generate GenerateImplementations.mtl \
    --model design.xmi \
    --output generated/implementations/

# Stage 3: Generate tests
swift-mtl generate GenerateTests.mtl \
    --model design.xmi \
    --output generated/tests/
```

## Next Steps

- <doc:GettingStarted> - Practical examples
- **swift-ecore** - Work with models
- **swift-atl** - Transform models

## See Also

- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [Eclipse Acceleo](https://eclipse.dev/acceleo/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
