# swift-mtl

Generate code from models using templates.

## Overview

The `swift-mtl` command-line tool executes MTL (Model-to-Text
Language) templates to generate code and other text artefacts from
models. It provides a complete implementation of the OMG MOFM2T
(MOF Model-to-Text Transformation) standard with support for file
generation, template inheritance, query expressions, and protected
regions.

The tool is built on the swift-mtl package
(https://github.com/mipalgu/swift-mtl), which provides a pure
Swift implementation of the MTL template language used by Eclipse
Acceleo ([Eclipse Acceleo](https://eclipse.dev/acceleo/)).

## Commands

### generate

Execute an MTL template to generate text from models.

```bash
swift-mtl generate <template-file> [options]
```

**Options:**

- `--model <path>` - Input model (XMI, JSON or Ecore); repeat for several models. The root object of each model is passed to the main template in command line order. An Ecore file is also registered as a metamodel and its package is passed as an argument.
- `--metamodel <path>` - Ecore metamodel to register without passing it to the template (repeatable)
- `-o, --output <path>` - Output directory for generated files (default: the current directory)
- `-t, --template <name>` - Main template to run (default: the template marked `@main`, otherwise the first)
- `--template-path <directory>` - Directory searched for imported modules after the directory of the template (repeatable)
- `--param <name=value>` - Parameter for the templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new` and leave the files alone
- `-v, --verbose` - Enable verbose output

**Template path.** Imported modules (`[import shared::Common/]`) are searched in the directory of the template and then in the `--template-path` directories, in order. A directory that does not exist is an error.

**Parameters.** Every `--param name=value` is available to the templates in three ways: as the bare variable `[name/]`, through `parameter('name')`, which returns the value or `null`, and through `hasParameter('name')`, which tells whether it was given. The value is a boolean for `true` and `false`, an integer for a whole number, and a string otherwise. The value is everything after the first `=`, and a later argument replaces an earlier one of the same name. A name must be an identifier (a letter or underscore followed by letters, digits or underscores) that is not an MTL or AQL reserved keyword; an invalid name, a reserved keyword, or an argument without a name or without `=` is rejected with an error before generation starts.

```text
[template public main()]
[file ('settings.txt')]
package=[package/]
same=[parameter('package')/]
[if (hasParameter('verbose'))]verbose output requested[/if]
[/file]
[/template]
```

**Metamodels.** `--metamodel` registers an Ecore file so that an instance model can be parsed against it, without passing its `EPackage` to the template. An Ecore file given with `--model` is registered as well, and its `EPackage` is also passed to the main template as an argument.

**Existing files.** A file that exists is merged with the generated text when the module declares a merge, and replaced otherwise. `--force-overwrite` always replaces it. `--diff` keeps it and writes the generated text beside it; `--force-overwrite` wins when both are given.

**Examples:**

```bash
# Basic generation
swift-mtl generate GenerateSwift.mtl --model mymodel.xmi --output generated/

# Modules from a shared directory, with parameters
swift-mtl generate GenerateCode.mtl --model input.xmi --output src/ \
    --template-path shared/templates \
    --param package=com.example --param version=1.0.0

# Keep existing files and review the differences
swift-mtl generate GenerateCode.mtl --model input.xmi --output src/ --diff

# An Ecore model passed to the template as its EPackage
swift-mtl generate ecore2dot.mtl --model library.ecore --output generated/
```

### validate

Validate one or more MTL template files for syntax errors and structural issues.

```bash
swift-mtl validate <templates>... [options]
```

**Options:**

- `-v, --verbose` - Enable verbose output

The command prints one result per template and a summary, and exits with code 0 only if every template is valid.

**Examples:**

```bash
# Validate a single template
swift-mtl validate GenerateSwift.mtl

# Validate several templates
swift-mtl validate Template1.mtl Template2.mtl

# Validate every template in a directory
swift-mtl validate Templates/*.mtl

# Verbose validation
swift-mtl validate GenerateSwift.mtl --verbose
```

### parse

Parse one or more MTL template files and display their structure.

```bash
swift-mtl parse <templates>... [options]
```

**Options:**

- `-d, --detailed` - Show detailed information about templates
- `--json` - Output as JSON
- `-v, --verbose` - Enable verbose output

**Examples:**

```bash
# Basic parsing
swift-mtl parse GenerateSwift.mtl

# Detailed output
swift-mtl parse GenerateSwift.mtl --detailed

# JSON output
swift-mtl parse GenerateSwift.mtl --json

# Parse several files
swift-mtl parse Template1.mtl Template2.mtl --detailed
```

## Common Workflows

### Developing and Testing Templates

```bash
# 1. Validate template syntax
swift-mtl validate GenerateSwift.mtl

# 2. Inspect the template structure
swift-mtl parse GenerateSwift.mtl --detailed

# 3. Generate into a scratch directory with verbose output
swift-mtl generate GenerateSwift.mtl \
    --model sample.xmi \
    --output /tmp/generated \
    --verbose
```

### Regenerating into Existing Source

```bash
# Review the differences first: new text is written beside existing files
swift-mtl generate GenerateSwift.mtl \
    --model production.xmi \
    --output src/ \
    --diff

# Then regenerate, merging with the existing files where the module declares a merge
swift-mtl generate GenerateSwift.mtl \
    --model production.xmi \
    --output src/
```

### Batch Generation from Multiple Models

```bash
# Generate code for multiple models
for model in models/*.xmi; do
    output="generated/$(basename "$model" .xmi)"
    mkdir -p "$output"
    swift-mtl generate GenerateSwift.mtl \
        --model "$model" \
        --output "$output" \
        --verbose
done
```

## Template Syntax Reference

### Module Declaration

```mtl
[module generate('http://www.example.org/mymodel')]
```

### File Generation

```mtl
[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
// Generated code for [c.name/]
class [c.name/] {
    [for (attr : Attribute | c.attributes)]
    var [attr.name/]: [attr.type/]
    [/for]
}
[/file]
[/template]
```

### Protected Regions

```mtl
[template public generateClass(c : Class)]
[file (c.name + '.swift', false, 'UTF-8')]
class [c.name/] {
    [protected ('custom-code-' + c.name, '// ', '// ')]
    // Add your custom code here
    [/protected]
}
[/file]
[/template]
```

### Template Inheritance

```mtl
[module child extends parent]

[template public generateClass(c : Class) overrides generateClass]
[super/]
// Additional generation
[/template]
```

### Query Expressions

```mtl
[query public getAllClasses(pkg : Package) : Sequence(Class) =
    pkg.eAllContents()->filter(Class)
/]

[template public generatePackage(pkg : Package)]
[for (c : Class | pkg.getAllClasses())]
[generateClass(c)/]
[/for]
[/template]
```

### Conditional Generation

```mtl
[template public generateProperty(attr : Attribute)]
[if (attr.isRequired())]
var [attr.name/]: [attr.type/]
[else]
var [attr.name/]: [attr.type/]?
[/if]
[/template]
```

### Let Expressions

```mtl
[template public generateClass(c : Class)]
[let className : String = c.name.toUpperFirst()]
class [className/] {
    [for (attr : Attribute | c.attributes)]
    [let propName : String = attr.name.toLowerFirst()]
    var [propName/]: [attr.type/]
    [/let]
    [/for]
}
[/let]
[/template]
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftMTL>

## See Also

- [OMG MOFM2T (MOF Model-to-Text Transformation)](https://www.omg.org/spec/MOFM2T/)
- [Eclipse Acceleo](https://eclipse.dev/acceleo/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
