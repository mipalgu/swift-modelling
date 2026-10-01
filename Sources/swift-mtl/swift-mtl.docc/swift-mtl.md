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

**Parameters.** Every `--param name=value` is available to the templates through `parameter('name')`, which returns the value or `null`, and `hasParameter('name')`, which tells whether it was given. The value is a boolean for `true` and `false`, an integer for a whole number, and a string otherwise. The value is everything after the first `=`, and a later argument replaces an earlier one of the same name. Parameters are read with parentheses; they are not variables.

```text
[template public main()]
[file ('settings.txt')]
package=[parameter('package')/]
[if (hasParameter('verbose'))]verbose output requested[/if]
[/file]
[/template]
```

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

Validate an MTL template file for syntax and semantic correctness.

```bash
swift-mtl validate <template-file> [options]
```

**Options:**

- `--metamodel <path>` - Metamodel for validation
- `--strict` - Enable strict validation mode
- `--report <path>` - Write validation report to file
- `--format <text|json>` - Report format (default: text)

**Examples:**

```bash
# Basic validation
swift-mtl validate GenerateSwift.mtl

# Validation with metamodel
swift-mtl validate MyTemplate.mtl \
    --metamodel MyMetamodel.ecore

# Strict validation with JSON report
swift-mtl validate ComplexTemplate.mtl \
    --metamodel MyMetamodel.ecore \
    --strict \
    --report validation-report.json \
    --format json
```

### preview

Preview generated output without writing files.

```bash
swift-mtl preview <template-file> [options]
```

**Options:**

- `--model <path>` - Input model file path (required)
- `--template-name <name>` - Specific template to preview (default: main template)
- `--output <path>` - Write preview to file instead of stdout
- `--format <text|json>` - Output format (default: text)

**Examples:**

```bash
# Preview generation
swift-mtl preview GenerateSwift.mtl --model mymodel.xmi

# Preview specific template
swift-mtl preview Templates.mtl \
    --model mymodel.xmi \
    --template-name generateClass

# Save preview to file
swift-mtl preview GenerateCode.mtl \
    --model input.xmi \
    --output preview.txt
```

### list-templates

List available templates in a template module.

```bash
swift-mtl list-templates <template-file> [options]
```

**Options:**

- `--detail <summary|full>` - Level of detail (default: summary)
- `--format <text|json>` - Output format (default: text)
- `--filter <pattern>` - Filter templates by name pattern

**Examples:**

```bash
# List all templates
swift-mtl list-templates GenerateSwift.mtl

# List with full details
swift-mtl list-templates MyTemplate.mtl --detail full

# List filtered templates as JSON
swift-mtl list-templates AllTemplates.mtl \
    --filter "generate*" \
    --format json
```

### compile

Compile an MTL template module to bytecode for faster execution.

```bash
swift-mtl compile <template-file> [options]
```

**Options:**

- `--output <path>` - Output bytecode file path (default: same name with .emtl extension)
- `--optimise` - Enable optimisation passes
- `--metamodel <path>` - Metamodel for type checking

**Examples:**

```bash
# Compile template
swift-mtl compile GenerateSwift.mtl

# Compile with optimisation
swift-mtl compile MyTemplate.mtl \
    --output MyTemplate.emtl \
    --optimise \
    --metamodel MyMetamodel.ecore
```

### extract-protected

Extract protected regions from existing generated files.

```bash
swift-mtl extract-protected <directory> [options]
```

**Options:**

- `--output <path>` - Output file for extracted regions (required)
- `--pattern <glob>` - File pattern to process (default: "**/*.swift")
- `--format <text|json>` - Output format (default: json)

**Examples:**

```bash
# Extract protected regions
swift-mtl extract-protected generated/ \
    --output protected-regions.json

# Extract from specific files
swift-mtl extract-protected src/ \
    --output regions.json \
    --pattern "**/*.swift"
```

## Common Workflows

### Developing and Testing Templates

```bash
# 1. Validate template syntax
swift-mtl validate GenerateSwift.mtl \
    --metamodel MyMetamodel.ecore

# 2. Preview generation
swift-mtl preview GenerateSwift.mtl \
    --model sample.xmi

# 3. Generate with verbose output
swift-mtl generate GenerateSwift.mtl \
    --model sample.xmi \
    --output generated/ \
    --verbose
```

### Production Code Generation Pipeline

```bash
# 1. Compile template with optimisation
swift-mtl compile GenerateSwift.mtl --optimise

# 2. Extract existing protected regions
swift-mtl extract-protected src/ \
    --output protected-backup.json

# 3. Generate code preserving protected regions
swift-mtl generate GenerateSwift.emtl \
    --model production.xmi \
    --output src/ \
    --preserve-protected \
    --overwrite smart
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
    // [protected ('custom-code-' + c.name)]
    // Add your custom code here
    // [/protected]
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
