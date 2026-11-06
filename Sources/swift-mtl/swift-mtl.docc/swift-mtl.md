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

### Features

- **MTL Parser**: Parses MTL templates from text files following the OMG MOFM2T v1.0 specification
- **MTL Runtime**: Executes templates with high performance using the concurrent execution model
  of Swift
- **Model Loading**: Loads models in XMI and JSON formats, and Ecore metamodels
- **Expression Language**: Full integration of AQL (Acceleo Query Language) for expressions
- **Advanced Features**: File blocks, protected areas, queries, macros and control flow
- **Command Line**: Generates, parses and validates MTL templates, with template search paths,
  parameters, template sets, and merge or diff handling of existing files
- **Unset Features**: Templates read unset features as in the Eclipse Modeling Framework, or as
  undefined with `--unset-features undefined`
- **Typed Let Blocks**: A value that does not conform to the declared type of a `let` variable is
  an error, or, with `--let-type-mismatches skip`, skips the block with a warning, as in Acceleo 3
- **Behaviour Options**: Templates follow the behaviour of this release by default;
  `--semantics legacy` and one option per behaviour select that of version 0.6
- **Standard Compliance**: Implements OMG MOFM2T v1.0 with compatibility for Acceleo-specific
  extensions

## Commands

### generate

Execute an MTL template to generate text from models.

```bash
swift-mtl generate <template-file> [options]
swift-mtl generate --template <template-file> [options]
swift-mtl generate --template-set <directory|language> [options]
```

**Options:**

- `--model <path>` - Input model (XMI `.xmi`, JSON `.json` or Ecore `.ecore`); repeat for several models. The root object of each model is passed to the main template in command line order. An Ecore file is also registered as a metamodel and its package is passed as an argument.
- `--metamodel <path>` - Ecore metamodel to register without passing it to the template (repeatable)
- `-o, --output <path>` - Output directory for generated files (default: the current directory)
- `-t, --template <name|file.mtl>` - Main template to run (default: the template marked `@main`, otherwise the first); a value that ends in `.mtl` names the template file instead, when no template file argument is given
- `--template-set <directory|language>` - Template set to run instead of a template file: a directory with a `templateset.json` descriptor, or the language of a bundled set
- `--template-path <directory>` - Directory searched for imported modules after the directory of the template (repeatable); with a template set, its files replace the files of the set with the same relative path
- `--param <name=value>` - Parameter for the templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new` and leave the files alone
- `--print-standard-output` - Print the text that the templates write outside `[file]` blocks on standard output instead of saving it as `stdout` in the output directory
- `--code-style <style>` - One of the code styles that the descriptor of a template set declares
- `--unset-features <defaults|undefined>` - Whether unset features read as their defaults (`defaults`, the default, as in the Eclipse Modeling Framework) or as undefined
- `--let-type-mismatches <error|skip>` - Whether a typed `let` whose value does not conform to the declared type stops the generation (`error`, the default) or is skipped with a warning on standard error (`skip`, as in Acceleo 3)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`) for every option below; an option below that is given overrides it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--block-line-breaks <acceleo|kept>` - Whether the line break after a block written on one line is dropped when the line is empty once the block has run (`acceleo`, the default, as in Acceleo 4) or always written (`kept`, as in version 0.6)
- `--collection-parameters <conforming|exact>` - Whether any collection whose elements conform, a many-valued feature or a single object conforms to a collection-typed parameter (`conforming`, the default) or collection types are matched as in version 0.6 (`exact`)
- `--check-let-types`, `--no-check-let-types` - Whether typed `let` blocks check their values (the default) or bind them unchecked, as in version 0.6
- `--cache-containers`, `--no-cache-containers` - Whether containers are looked up once per run (the default) or every time, as in version 0.6
- `--collection-arguments <whole|first-element>` - Whether a collection passed to `append`, `prepend`, `including` or `insertAt` is added whole (`whole`, the default) or only its first element (`first-element`, as in version 0.6)
- `--collection-kinds <distinguished|sequences>` - Whether collections keep their kinds (`distinguished`, the default) or all behave as sequences (`sequences`, as in version 0.6)
- `--single-value-collections <set|sequence>` - Whether an arrow call on a single value sees a set (`set`, the default) or a sequence (`sequence`, as in version 0.6)
- `--container-lookup <resources|registered-objects>` - Whether `eContainer()` asks the registered resources (`resources`, the default) or only the registered model objects (`registered-objects`, as in version 0.6)
- `--sequence-union <concatenation|distinct>` - Whether the `union` of a sequence or a bag keeps repeated elements (`concatenation`, the default, as in Eclipse AQL) or leaves them out (`distinct`, as in version 0.6)
- `--null-addition <empty-text|null>` - Whether `+` treats a null operand as empty text, so `null + 'x'` is `'x'` (`empty-text`, the default, as in Eclipse AQL), or gives null (`null`, as in version 0.6)
- `--text-form <joined|bracketed>` - Whether the text of a collection joins the texts of its elements, `'ab'` (`joined`, the default, as in Eclipse AQL), or brackets them, `'[a, b]'` (`bracketed`, as in version 0.6)
- `--dot-calls <each-element|collection>` - Whether a call written with `.` on a collection applies to each element, so `names.size()` gives the length of each name (`each-element`, the default, as in Eclipse AQL), or calls the collection operation, so `names.size()` gives the number of names (`collection`, as in version 0.6); `names->size()` gives the number of names under both
- `--strict-aql`, `--no-strict-aql` - Make the expressions of the templates reject what Eclipse AQL rejects, such as a union of a sequence with a set or a single value passed to `concat`, `sub` or `union`, or accept it (the default); neither preset sets it, and without either flag the `strict-aql` key of the configuration file chooses
- `-v, --verbose` - Enable verbose output
- `--debug` - Print the traces of the template and model parsers, for diagnosing the parsers; `--verbose` reports progress without them

**Template path.** Imported modules (`[import shared::Common/]`) are searched in the directory of the template and then in the `--template-path` directories, in order. A directory that does not exist is an error.

**Template sets.** `--template-set` runs a template set instead of a single template file; give one or the other. A path names a directory that holds a `templateset.json` descriptor, and a plain name is the language of a bundled set. The main template of the set, named by its descriptor, receives the root objects of the models in command line order, and the data models of the set are available through `templateData('name')`. The modules that the descriptor lists under `imports` are copied beside the set, so that its modules import them by qualified name. `--code-style` chooses one of the code styles of the set; `--template` does not apply to a set.

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

**Metamodels.** `--metamodel` registers an Ecore file so that an instance model can be parsed against it, without passing its `EPackage` to the template. An Ecore file given with `--model` is registered as well, and its `EPackage` is also passed to the main template as an argument, in command line order, like any other model. Navigating the features of a native `EPackage` inside a template requires a swift-ecore release with reflective metamodel objects.

**Unset features.** `--unset-features defaults|undefined` chooses how templates read features that a model does not set. With `defaults`, the default, `[c.count/]` writes `0` for an unset integer, as the Eclipse Modeling Framework and Acceleo do; with `undefined` it writes nothing, because every unset feature reads as undefined.

**Existing files.** A file that exists is merged with the generated text when the module declares a merge, and replaced otherwise. `--force-overwrite` always replaces it. `--diff` keeps it and writes the generated text beside it; `--force-overwrite` wins when both are given.

**Text outside file blocks.** Text that the templates write outside their `[file]` blocks is saved as `stdout` in the output directory. Nothing is saved when that text is only white space, such as the line breaks between file blocks, and a `stdout` file that a `[file]` block of the same run wrote is kept. `--print-standard-output` prints the text on standard output instead, before the completion message, and saves no `stdout` file.

**Typed let blocks.** A `let` variable may declare a type, as in `[let n : Integer = c.size]...[/let]`. By default a value that does not conform to that type stops the generation with an error that names the variable and both types; `null` conforms to every type. The OMG MOFM2T specification and Acceleo 3 treat a typed `let` as a type test instead. `--let-type-mismatches skip` follows them: the `let` block is skipped, the generation continues, and a warning that names the variable, its declared type and the type of the value is written to standard error, such as `warning: line 4, column 1: Variable 'n' of type Integer cannot hold a value of type String, so the let block is skipped`. A mismatch that recurs, for instance in a loop, is reported once. With `--no-check-let-types`, values are bound unchecked, as version 0.6 did, and the option has no effect. `swift-ecore generate` and `swift-atl generate` accept the option too, for their templates.

**Dot calls on collections.** A call written with `.` on a collection applies to each element, so `[names.size()/]` writes the length of each name and `[names->size()/]` the number of names. When a dot call reaches an element without the operation while the collection has it, as in `[Sequence{1, 2}.size()/]`, a warning that suggests `->size()` is written to standard error with the other generation warnings, such as `warning: line 3, column 1: ...`. Warnings do not change the exit status. `swift-ecore generate` and `swift-atl generate` report them too, for their templates.

**Strict AQL.** `--strict-aql` makes the expressions reject what Eclipse AQL rejects, such as a union of a sequence with a set or a single value passed to `concat`, `sub` or `union`, and `--no-strict-aql` overrides a configuration file that sets `strict-aql`. `swift-aql`, `swift-ecore generate`, `swift-atl generate` and the OCL invariants of `swift-ecore validate` accept the option too.

**Compatibility with 0.6.** The templates follow the behaviour of this release. `--semantics legacy` gives every behaviour that changed since version 0.6 its earlier form: one-line blocks keep their line breaks, collection types are matched exactly, `let` types are not checked, containers are looked up every time, and the expressions add the first element of a collection argument, treat every collection as a sequence, see a single value as a sequence and find containers among the registered objects only. Each option above overrides the preset, whatever the order, so `--semantics legacy --block-line-breaks acceleo` behaves as version 0.6 apart from the line breaks. `swift-ecore generate` and `swift-atl generate` accept the same options, for their templates. The Compatibility with 0.6 section of the [SwiftModelling documentation](https://mipalgu.github.io/swift-modelling/documentation/swiftmodelling/swiftmodelling/index.html) lists every behaviour option with its default and its version 0.6 behaviour, and describes the environment variable and the configuration file in full.

**Environment and configuration file.** Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable (`standard` or `legacy`) chooses the preset, and then the `semantics` key of a configuration file. The configuration file is the first `.swift-modelling.json` in the current directory or one of its parents, up to the directory that holds `.git`; `--config` names another file and `--no-config` reads none. Its keys are the names of the behaviour options without their leading `--`, with the spellings of the command line as JSON strings, or JSON booleans for `check-let-types`, `cache-containers` and `strict-aql`; a key that does not apply to a command is ignored. A behaviour option given on the command line overrides the file, an option in the file overrides the preset, `--semantics` overrides the environment variable, and the environment variable overrides `semantics` in the file. `--let-type-mismatches` and `--unset-features` do not depend on the preset: the command line overrides the file, which overrides their defaults. An invalid value of the variable, or an unknown key or an invalid value in the file, stops the command with an error that names it. For example, this file gives the behaviour of version 0.6 apart from the line breaks and the containers:

```json
{
  "semantics": "legacy",
  "block-line-breaks": "acceleo",
  "check-let-types": true,
  "container-scope": "any-resource"
}
```

**Examples:**

```bash
# Basic generation
swift-mtl generate GenerateSwift.mtl --model mymodel.xmi --output generated/

# Generate as version 0.6 did
swift-mtl generate GenerateSwift.mtl --model mymodel.xmi --output generated/ --semantics legacy

# Modules from a shared directory, with parameters
swift-mtl generate GenerateCode.mtl --model input.xmi --output src/ \
    --template-path shared/templates \
    --param package=com.example --param version=1.0.0

# Keep existing files and review the differences
swift-mtl generate GenerateCode.mtl --model input.xmi --output src/ --diff

# An Ecore model passed to the template as its EPackage
swift-mtl generate ecore2dot.mtl --model library.ecore --output generated/

# A template set, from its directory, in one of its code styles
swift-mtl generate --template-set report-set/ --model input.xmi --output generated/ --code-style tabs

# Several models, passed to the main template in command line order
swift-mtl generate template.mtl --model families.xmi --model departments.xmi --output generated/

# Name the main template, or name the template file with --template instead of as an argument
swift-mtl generate template.mtl --model input.xmi --template generateAll --output generated/
swift-mtl generate --template template.mtl --model input.xmi --output generated/

# Register a metamodel only, and pass just the instance model to the template
swift-mtl generate template.mtl --metamodel library.ecore --model books.xmi --output generated/

# Replace existing files instead of merging, with progress and statistics
swift-mtl generate template.mtl --model input.xmi --force-overwrite --output generated/ --verbose
```

### validate

Validate one or more MTL template files for syntax errors and structural issues.

```bash
swift-mtl validate <templates>... [options]
```

**Options:**

- `-v, --verbose` - Enable verbose output
- `--debug` - Print the trace of the template parser, for diagnosing the parser; `--verbose` reports progress without it

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
- `--debug` - Print the trace of the template parser, for diagnosing the parser; `--verbose` reports progress without it

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

### A First Template

A template that writes no `[file]` block, saved as `hello.mtl`:

```mtl
[module HelloWorld('http://example.com')]

[template main()]
Hello, World!
This is a simple MTL template.
[/template]
```

Its text is saved as `stdout` in the output directory:

```bash
swift-mtl generate hello.mtl --output /tmp/output/
cat /tmp/output/stdout
```

### Generating from an Ecore Model

A template whose main template receives the `EClass` objects of an Ecore model:

```mtl
[module ClassGenerator('http://www.eclipse.org/emf/2002/Ecore')]

[template generateClass(c : EClass)]
[file (c.name + '.swift', 'overwrite', 'UTF-8')]
// Generated from [c.name/]
class [c.name/] {
[for (attr in c.eAttributes) separator('\n')]
    var [attr.name/]: [attr.eType.name/]
[/for]
}
[/file]
[/template]
```

```bash
swift-mtl generate ClassGenerator.mtl --model mymodel.ecore --output generated-swift/
```

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
