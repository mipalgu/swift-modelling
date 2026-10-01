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

The tool has three subcommands: `generate` (the default, so
`swift-mtl template.mtl --model m.xmi` also works), `parse` and
`validate`. Run `swift-mtl help <subcommand>` for details.

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
swift-mtl validate GenerateSwift.mtl
```

This reports syntax errors and structural issues for each template given
and exits with a non-zero code if any template is invalid. To see how a
template was understood, display its structure:

```bash
swift-mtl parse GenerateSwift.mtl --detailed
```

### Generating Code

Run the template against your model:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --output generated/
```

The tool:
1. Loads the model
2. Executes the main template (the one named with `--template`, otherwise
   the template marked `@main`, otherwise the first)
3. Evaluates expressions and loops
4. Writes files to the output directory (the current directory by default)

### Using Ecore Metamodels

An Ecore file can take one of two roles on the command line.

Use `--model` when the template should process the metamodel itself, for
example a template whose main template takes an `EPackage`:

```bash
swift-mtl generate Ecore2Dot.mtl \
    --model library.ecore \
    --output generated/
```

The metamodel is registered, so that instance models can be parsed against it,
and its root `EPackage` is passed to the main template as an argument. Like
every other `--model` file, it is registered under its file name without
extension, and its argument position follows the command line order.

Use `--metamodel` when an instance model needs its metamodel but the template
does not want the `EPackage` as an argument. The option can be repeated:

```bash
swift-mtl generate GenerateBooks.mtl \
    --metamodel library.ecore \
    --model books.xmi \
    --output generated/
```

Here the template receives only the root object of `books.xmi`. With
`--verbose`, each Ecore file is announced as either registered only or
registered and used as an input model.

> Note: Navigating the features of a native `EPackage` inside a template, such
> as `aPackage.name` or `aPackage.eClassifiers`, requires a swift-ecore release
> whose native metamodel objects support reflection.

### Passing Parameters and Extra Template Directories

Pass values to templates with `--param name=value`, which can be repeated.
Each parameter is available as the bare variable `[name/]`, through
`parameter('name')` and tested with `hasParameter('name')`:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --param package=com.example \
    --param verbose=true \
    --output generated/
```

```mtl
package [package/]
[if (hasParameter('verbose'))]// verbose output requested[/if]
[parameter('package')/]
```

A value of `true` or `false` is a boolean, a whole number is an integer, and
anything else is a string. A parameter name must be an identifier that is not
an MTL or AQL reserved keyword; otherwise the tool stops with an error.

Modules that a template imports are searched for in the directory of the
template and then in each `--template-path` directory (repeatable):

```bash
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --template-path shared/templates \
    --output generated/
```

### Existing Files

When an output file already exists, it is merged with the generated text if
the module declares a merge, and replaced otherwise. Two flags change this:

- `--force-overwrite` always replaces existing files without merging.
- `--diff` keeps existing files and writes the generated text beside them as
  `.<name>.new`, so that you can compare the two. If both flags are given,
  `--force-overwrite` wins.

```bash
swift-mtl generate GenerateSwift.mtl \
    --model company.xmi \
    --output src/ \
    --diff
```

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
swift-mtl validate MyTemplate.mtl

# 3. Generate to temporary directory
swift-mtl generate MyTemplate.mtl \
    --model sample.xmi \
    --output /tmp/generated

# 4. Review generated files
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

    [protected ('custom-' + c.name, '// ', '// ')]
    // Add your custom code here
    // It will be preserved across regeneration
    [/protected]
}
[/file]
[/template]
```

The `protected` ID must be unique within the file. The second and third
arguments are the text placed in front of the start and end markers, so that
they are comments in the target language.

### Using Protected Regions

First generation creates the region:

```swift
class Employee {
    var name: String
    var age: Int

    // START PROTECTED REGION custom-Employee
    // Add your custom code here
    // It will be preserved across regeneration
    // END PROTECTED REGION custom-Employee
}
```

Add custom code:

```swift
class Employee {
    var name: String
    var age: Int

    // START PROTECTED REGION custom-Employee
    func greet() -> String {
        return "Hello, I'm \(name)"
    }
    // END PROTECTED REGION custom-Employee
}
```

Regenerate into the same output directory; the custom code is preserved
because the tool scans the existing file for protected regions first:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model updated-company.xmi \
    --output src/
```

The `greet()` method remains even though the model changed.

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

### Existing Files

Control what happens to files that already exist in the output directory:

- By default, an existing file is merged with the generated text when the
  module declares a merge, and replaced otherwise.
- `--force-overwrite` always replaces existing files.
- `--diff` leaves existing files alone and writes the generated text beside
  them as `.<name>.new`.

```bash
swift-mtl generate Template.mtl \
    --model input.xmi \
    --output generated/ \
    --force-overwrite
```

### Template Parameters

Pass configuration to templates with `--param`:

```bash
swift-mtl generate GenerateSwift.mtl \
    --model input.xmi \
    --output generated/ \
    --param packageName=com.example \
    --param version=1.2.3 \
    --param author=System
```

Access in templates as bare variables or through the services:

```mtl
// Package: [packageName/]
// Version: [parameter('version')/]
[if (hasParameter('author'))]// Author: [author/][/if]
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
        --output "$outdir"
done
```

## Troubleshooting

### Template Syntax Errors

**Problem**: "Parse error" or "Syntax error"

**Solution**: Validate the template, and display its structure:

```bash
swift-mtl validate MyTemplate.mtl --verbose
swift-mtl parse MyTemplate.mtl --detailed
```

Check the reported error for the location of the problem.

### Expression Errors

**Problem**: "Unknown feature" or "Type mismatch"

**Solution**: Generate with verbose output, which reports the loaded
models and metamodels:

```bash
swift-mtl generate MyTemplate.mtl \
    --metamodel MyModel.ecore \
    --model test.xmi \
    --output /tmp/test \
    --verbose
```

Ensure attributes/references exist and types match.

### Files Not Generated

**Problem**: Template runs but no files created

**Solution**: Check the main template:

```bash
swift-mtl parse MyTemplate.mtl --detailed
```

Ensure the main template exists (mark it with `@main`, or name it with
`--template`) and calls the templates that generate files.

If files exist already, check whether `--diff` was used: the generated text
is then written beside them as `.<name>.new`.

## Next Steps

- <doc:UnderstandingSwiftMTL> - Learn MTL concepts
- **swift-ecore** - Work with models
- **swift-atl** - Transform models before generation

## See Also

- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [Eclipse Acceleo](https://eclipse.dev/acceleo/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
