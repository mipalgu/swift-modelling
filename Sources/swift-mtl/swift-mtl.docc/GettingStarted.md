# Getting Started with swift-mtl

Learn how to use the swift-mtl command-line tool to generate code
from models using templates.

## Overview

The swift-mtl CLI executes MTL (Model-to-Text Language) templates
that generate code and text artefacts from models. This guide
demonstrates common code generation patterns to help you start
generating code quickly.

## Installation

The swift-mtl tool is part of the swift-modelling package.

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mipalgu/swift-modelling.git",
             branch: "main"),
]
```

Build the tool:

```bash
swift build -c release
```

The executable will be available at:
`.build/release/swift-mtl`

## Your First Template

### Creating a Simple Template

Create a template file `GenerateSwift.mtl`:

```mtl
[module generate('http://www.example.org/company')]

[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
// Generated class for [c.name/]

class [c.name/] {
    [for (attr : Attribute | c.attributes)]
    var [attr.name/]: [attr.type/]
    [/for]

    init([for (attr : Attribute | c.attributes) separator(', ')]
        [attr.name/]: [attr.type/][/for]
    ) {
        [for (attr : Attribute | c.attributes)]
        self.[attr.name/] = [attr.name/]
        [/for]
    }
}
[/file]
[/template]

[template public main(model : Package)]
[comment Generate all classes /]
[for (c : Class | model.eAllContents(Class))]
[generateClass(c)/]
[/for]
[/template]
```

### Validating the Template

Check template syntax before running:

```bash
swift-mtl validate GenerateSwift.mtl \
    --metamodel Company.ecore
```

This verifies:
- Template syntax is correct
- Referenced metamodel classes exist
- Query expressions are well-formed
- File paths are valid

### Generating Code

Run the template against your model:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --output generated/
```

The tool:
1. Loads the model
2. Executes the `main` template
3. Evaluates expressions and loops
4. Writes files to the output directory

### Previewing Output

Preview without writing files:

```bash
swift-mtl preview GenerateSwift.mtl \
    --model company.xmi
```

Shows generated content on stdout, useful for debugging templates
before committing to file generation.

## Template Basics

### File Generation

The `[file]` block creates output files:

```mtl
[file (filename, overwrite, encoding)]
... content ...
[/file]
```

- `filename` - Expression evaluating to file path
- `overwrite` - `false` to create new, `true` to append
- `encoding` - Character encoding (typically 'UTF-8')

Example:

```mtl
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] { }
[/file]
```

### Expressions

Insert computed values with `[expression/]`:

```mtl
Class name: [c.name/]
Upper name: [c.name.toUpper()/]
Attribute count: [c.attributes->size()/]
```

### Loops

Iterate with `[for]` blocks:

```mtl
[for (attr : Attribute | c.attributes)]
var [attr.name/]: [attr.type/]
[/for]
```

With separators:

```mtl
[for (attr : Attribute | c.attributes) separator(', ')]
[attr.name/]: [attr.type/][/for]
```

With before/after text:

```mtl
[for (attr : Attribute | c.attributes)
     before('(') after(')') separator(', ')]
[attr.name/]: [attr.type/][/for]
```

### Conditionals

Generate conditionally with `[if]` blocks:

```mtl
[if (c.isAbstract)]
abstract class [c.name/]
[else]
class [c.name/]
[/if]
```

Multiple conditions:

```mtl
[if (c.visibility = 'public')]
public class [c.name/]
[elseif (c.visibility = 'protected')]
protected class [c.name/]
[else]
private class [c.name/]
[/if]
```

## Development Workflow

### Iterative Development

Use this workflow when developing templates:

```bash
# 1. Edit template
vim MyTemplate.mtl

# 2. Validate syntax
swift-mtl validate MyTemplate.mtl \
    --metamodel MyModel.ecore

# 3. Preview output
swift-mtl preview MyTemplate.mtl \
    --model sample.xmi | less

# 4. Generate to temporary directory
swift-mtl generate MyTemplate.mtl \
    --model sample.xmi \
    --output /tmp/generated

# 5. Review generated files
ls -la /tmp/generated
cat /tmp/generated/MyClass.swift
```

### Testing with Sample Data

Create small test models covering all cases:

```bash
# Test normal case
swift-mtl generate Template.mtl \
    --model test-normal.xmi \
    --output test-output/normal/

# Test edge cases
swift-mtl generate Template.mtl \
    --model test-empty.xmi \
    --output test-output/empty/

swift-mtl generate Template.mtl \
    --model test-complex.xmi \
    --output test-output/complex/
```

Review all outputs to ensure templates handle all scenarios.

## Protected Regions

### Adding Protected Regions

Preserve user code across regeneration:

```mtl
[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] {
    [for (attr : Attribute | c.attributes)]
    var [attr.name/]: [attr.type/]
    [/for]

    // [protected ('custom-' + c.name)]
    // Add your custom code here
    // It will be preserved across regeneration
    // [/protected]
}
[/file]
[/template]
```

The `protected` ID must be unique within the file.

### Using Protected Regions

First generation creates the region:

```swift
class Employee {
    var name: String
    var age: Int

    // [protected (custom-Employee)]
    // Add your custom code here
    // It will be preserved across regeneration
    // [/protected]
}
```

Add custom code:

```swift
class Employee {
    var name: String
    var age: Int

    // [protected (custom-Employee)]
    func greet() -> String {
        return "Hello, I'm \(name)"
    }
    // [/protected]
}
```

Regenerate - custom code is preserved:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model updated-company.xmi \
    --output src/ \
    --preserve-protected
```

The `greet()` method remains even though the model changed.

### Extracting Protected Regions

Back up protected regions before regeneration:

```bash
# Extract existing regions
swift-mtl extract-protected src/ \
    --output protected-backup.json

# Regenerate (safe with backup)
swift-mtl generate GenerateSwift.mtl \
    --model updated.xmi \
    --output src/ \
    --preserve-protected
```

The backup enables recovery if something goes wrong.

## Queries

### Defining Queries

Queries are reusable expressions:

```mtl
[query public getAllClasses(pkg : Package) : Sequence(Class) =
    pkg.eAllContents()->filter(Class)
/]

[query public publicAttributes(c : Class) : Sequence(Attribute) =
    c.attributes->select(a | a.visibility = 'public')
/]
```

### Using Queries

Call queries in templates:

```mtl
[template public generatePackage(pkg : Package)]
[for (c : Class | pkg.getAllClasses())]
[generateClass(c)/]
[/for]
[/template]

[template public generateClass(c : Class)]
class [c.name/] {
    [for (attr : Attribute | c.publicAttributes())]
    public var [attr.name/]: [attr.type/]
    [/for]
}
[/template]
```

Queries improve readability and enable reuse.

## Template Organisation

### Multiple Templates

Split generation into focused templates:

```mtl
[template public main(model : Package)]
[generateClasses(model)/]
[generateProtocols(model)/]
[generateExtensions(model)/]
[/template]

[template private generateClasses(model : Package)]
[for (c : Class | model.eAllContents(Class))]
[generateClass(c)/]
[/for]
[/template]

[template private generateProtocols(model : Package)]
[for (p : Protocol | model.eAllContents(Protocol))]
[generateProtocol(p)/]
[/for]
[/template]
```

### Template Visibility

Control access with visibility modifiers:

- `public` - Callable from other modules
- `protected` - Callable from submodules
- `private` - Only within this module

```mtl
[template public generate(c : Class)]
...main generation...
[/template]

[template private generateHelperMethod(c : Class)]
...internal helper...
[/template]
```

## Production Use

### Compilation

Compile templates for faster execution:

```bash
swift-mtl compile GenerateSwift.mtl --optimise
```

Creates `GenerateSwift.emtl` bytecode.

Run compiled templates:

```bash
swift-mtl generate GenerateSwift.emtl \
    --model production.xmi \
    --output generated/
```

**Benefits:**
- 5-10× faster execution
- Reduced parse overhead
- Optimised expression evaluation

**Use for:**
- Large models
- Batch generation
- Production pipelines
- Repeated generation

### Overwrite Strategies

Control file overwriting:

**All** - Always overwrite:

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite all
```

**None** - Never overwrite (skip existing files):

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite none
```

**Smart** - Overwrite only generated files (default):

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --overwrite smart
```

Smart mode preserves manually-created files and respects
protected regions.

### Template Properties

Pass configuration to templates:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model input.xmi \
    --output generated/ \
    --property "packageName=com.example" \
    --property "version=1.2.3" \
    --property "author=System"
```

Access in templates:

```mtl
[comment Use property /]
// Package: [getProperty('packageName')/]
// Version: [getProperty('version')/]
```

## Integration with Other Tools

### Validate Before Generation

Ensure model is valid:

```bash
# Validate model
swift-ecore validate company.xmi \
    --metamodel Company.ecore

# Generate if valid
if [ $? -eq 0 ]; then
    swift-mtl generate GenerateSwift.mtl \
        --model company.xmi \
        --output generated/
fi
```

### Transform Then Generate

Chain transformations and generation:

```bash
# Transform model
swift-atl transform UML2Database.atl \
    --source design.xmi \
    --target schema.xmi

# Validate transformation result
swift-ecore validate schema.xmi \
    --metamodel Database.ecore

# Generate SQL DDL
swift-mtl generate GenerateSQL.mtl \
    --model schema.xmi \
    --output sql/
```

### Batch Generation

Process multiple models:

```bash
#!/bin/bash
for model in models/*.xmi; do
    name=$(basename "$model" .xmi)
    outdir="generated/$name"
    mkdir -p "$outdir"

    echo "Generating $name..."
    swift-mtl generate GenerateSwift.mtl \
        --model "$model" \
        --output "$outdir" \
        --preserve-protected
done
```

## Troubleshooting

### Template Syntax Errors

**Problem**: "Parse error" or "Syntax error"

**Solution**: Validate template:

```bash
swift-mtl validate MyTemplate.mtl \
    --metamodel MyModel.ecore \
    --strict \
    --report errors.json \
    --format json
```

Check the error report for line/column information.

### Expression Errors

**Problem**: "Unknown feature" or "Type mismatch"

**Solution**: Validate against metamodel:

```bash
swift-mtl validate MyTemplate.mtl \
    --metamodel MyModel.ecore
```

Ensure attributes/references exist and types match.

### Files Not Generated

**Problem**: Template runs but no files created

**Solution**: Check the main template:

```bash
swift-mtl list-templates MyTemplate.mtl --detail full
```

Ensure `main` template exists and calls generation templates.

Preview to see what would be generated:

```bash
swift-mtl preview MyTemplate.mtl --model test.xmi
```

## Next Steps

- <doc:UnderstandingSwiftMTL> - Learn MTL concepts
- **swift-ecore** - Work with models
- **swift-atl** - Transform models before generation

## See Also

- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [Eclipse Acceleo](https://eclipse.dev/acceleo/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
