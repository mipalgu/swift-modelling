# swift-atl

Transform models with the Atlas Transformation Language.

## Overview

The `swift-atl` command-line tool executes ATL (Atlas
Transformation Language) transformations to convert models from
one metamodel to another, and evaluates ATL queries. It also parses,
validates, tests, analyses and compiles ATL files, and generates
generator models and source code from Ecore models.

The tool is built on the swift-atl package
(https://github.com/mipalgu/swift-atl), which provides a pure
Swift implementation of the Eclipse ATL
([Eclipse ATL](https://eclipse.dev/atl/)) transformation language.

### Features

- **Eclipse ATL Compatibility**: Full syntax compatibility with Eclipse ATL transformations
- **Complete Parser**: Full ATL and OCL syntax support
- **XMI Serialisation**: The ATL XMI format of Eclipse, with round-trip support
- **Execution Engine**: A complete ATL virtual machine with expression evaluation
- **Advanced OCL**: Let expressions, tuple expressions, iterate operations and lambda expressions
- **Helpers**: Context helpers and standalone helpers
- **Module Parameters**: Values for `-- @param` declarations with `--param name=value`
- **Unset Features**: Unset features read as in the Eclipse Modeling Framework, or as undefined
  with `--unset-features undefined`
- **Built-in Metamodels**: The Ecore and generator metamodels resolve from `-- @nsURI` directives
  without metamodel files
- **Reflection**: `refImmediateComposite()`, `refGetValue`, `refSetValue`, `refUnsetValue` and
  `refInvokeOperation`, for container navigation without opposite references
- **Code Generation**: `generate` turns Ecore models into generator models and generated code
  with the shared pipeline
- **Queries**: `query` evaluates ATL query units, such as one that builds a Graphviz file from a
  model with `writeTo`, writing only inside an output directory unless told otherwise
- **Compatibility Checks**: `check-compat` decides whether a transformation can be used with
  revised or related metamodels, by structural model subtyping of the metamodels it uses
- **Integer Ranges**: Collection literals accept OCL integer ranges such as `Sequence{1..3}`
- **Integer Division**: `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and
  Eclipse ATL, and `div` gives the truncated Integer quotient

## Commands

### transform

Execute an ATL transformation to convert source models into target models.

```bash
swift-atl transform <transformation-file> [options]
```

**Options:**

- `--source <[ALIAS=]path>` - Source model file; repeat for several models, matched to the aliases of the `create` statement by order or by alias
- `--target <[ALIAS=]path>` - Target model file, matched in the same way
- `--param <name=value>` - Value for a module parameter declared with `-- @param` (repeatable)
- `--input-format <xmi|json>` - Format of the source models (default: from the file extension)
- `--output-format <xmi|json>` - Format of the target models (default: from the file extension)
- `--metamodel-path <directory>` - Directory searched for metamodels named by `-- @path` directives (repeatable)
- `--reference-style <encoded|plain>` - How an XMI target spells references into its own document (default `encoded`); see the output layout below
- `--unset-features <defaults|undefined>` - How the rules read features that a model does not set (default `defaults`); see below
- `--source-metamodel <[name=]file.ecore>` - Metamodel file for a source metamodel, matched to the metamodels after `from` (or `refining`) by order or by name (repeatable)
- `--target-metamodel <[name=]file.ecore>` - Metamodel file for a target metamodel, matched to the metamodels after `create` in the same way (repeatable)
- `--metamodel <[name=]file.ecore>` - Metamodel file for any metamodel of the module, such as one that source and target share; by position it follows the source metamodels and then the target metamodels, each name once (repeatable)
- `--refining` - Refine the source model, as a module declared with `refining` does
- `--validate-only` - Check the transformation against its metamodels and load the source models, without running it or writing targets
- `--quiet`, `-q` - Print nothing on success; cannot be combined with `--verbose` or `--debug`
- `--verbose` - Enable verbose output
- `--debug` - Trace the execution
- `--continue-after-errors` - Continue after metamodel loading errors
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Module parameters.** A transformation declares a parameter in a header comment, `-- @param name : Type` or `-- @param name : Type = default`, with the types `String`, `Integer`, `Real` and `Boolean`, and reads it as `thisModule.name`. `--param name=value` supplies the value; it is converted to the declared type, and the value is everything after the first `=`. A name that the module does not declare, a value of the wrong type, a required parameter without a value, and an argument that is not `name=value` are errors.

**Metamodel files and directives.** A metamodel file given on the command line takes the place of the `-- @path` and `-- @nsURI` directives of its metamodel; a metamodel that two options bind to different files, a name that the module header does not declare, and a positional list whose length differs from the declared metamodels are errors. A metamodel that neither a file nor a directive binds is an error unless `--continue-after-errors` is given. A `-- @path` that starts with `/` names a file in an Eclipse workspace, such as `/Families2Persons/Families.ecore`: it is looked up in each metamodel search directory as `Families2Persons/Families.ecore` and then as `Families.ecore`, with the search directory as the project directory. Without `--metamodel-path` or the `ECOREPATH` environment variable, the search directories are the directory of the transformation, its parent and the current directory. A metamodel file, in any metamodel format that swift-ecore reads, such as Ecore, JSON, KM3, EMOF (also in an `.xmi` file), Emfatic, Xcore, OCLinEcore, a grammar or a UML class model (`.uml`), whose Ecore metamodel is derived as the Eclipse UML2 tools derive it, binds its first root package. A root package without a namespace URI or prefix is loaded, as in the Eclipse Modeling Framework, with a warning on standard error that names the file and the package. `--km3-primitives <ecore|declared>` chooses whether the data types that a KM3 metamodel declares are the built-in Ecore data types of the same meaning (`ecore`, the default) or data types of their own package (`declared`); `transform` and `query` take the option, and the `km3-primitives` key of the configuration file chooses it too. `--package-name <name>`, `--ns-uri <uri>`, `--ns-prefix <prefix>`, `--asdl-enumerations <all-nullary|never>`, `--langium-types <normal|strict>` and `--sdf3-labels` / `--no-sdf3-labels` choose how a metamodel is imported from an ASDL, Langium, Xtext or SDF3 grammar, as for `swift-ecore`; `transform` and `query` take them, and the configuration file keys of the same names choose them too. A target model whose file has the extension `uml` is written as a UML model in the layout of Eclipse UML2, and a source model with that extension is read as one.

**Source encoding.** The transformation is read as UTF-8. A file that is not valid UTF-8 is read as ISO-8859-1 instead, with a warning on standard error that names the file and the line and column of the first byte that is not UTF-8, such as `warning: Families2Persons.atl: line 3, column 12: The text is not valid UTF-8 and was read as ISO-8859-1`. `--encoding` names the encoding instead (`UTF-8`, `UTF-16`, `UTF-16BE`, `UTF-16LE`, `ISO-8859-1`, `windows-1252` or `US-ASCII`, or an alias such as `latin1`); the file is then read in that encoding alone, and a file that is not valid in it is an error. Every command that reads ATL source takes the option. A model given with `--source` whose extension is not `xmi`, `json` or `ecore` is read in the format of its contents, XMI or JSON, unless `--input-format` names one.

**Refining mode.** A module declared as `create OUT : MM refining IN : MM;`, or run with `--refining`, starts each target model as a copy of the source model in the same position of the header. A rule changes the copy of the element it matches, through the first target pattern element of the type of its source pattern element; elements that no rule matches are kept. A rule whose `to` section starts with `drop`, alone or before target patterns of new elements, deletes the element it matches, with the elements it contains, once every other rule has run; references from the remaining elements to the deleted ones are removed. `drop` outside refining mode is an error, which `--validate-only` reports as well.

**Unset features.** `--unset-features defaults|undefined` chooses how the rules read features that a model does not set. With `defaults`, the default, they read as the Eclipse Modeling Framework's `eGet` reports them: an unset attribute as its declared default or the default of its data type (`false`, `0`, `0.0` or the first enumeration literal), an unset many-valued feature as an empty collection, and an unset string or reference as undefined. With `undefined`, every unset feature reads as undefined, so a guard such as `t.done = false` no longer matches a task that leaves `done` unset. `query` and `generate` accept the option too, as do `swift-ecore generate` and `swift-ecore genmodel`, for the import transformation and the templates.

**Integer ranges.** Collection literals accept OCL integer ranges, so `Sequence{0, 2..4}` holds `0, 2, 3, 4`. Eclipse ATL rejects them, and so does `--collection-range-syntax eclipse` (or `--semantics legacy`), with a message that names the portable alternatives. Every command that reads ATL source accepts the option: `parse`, `validate`, `analyze`, `compile`, `test`, `transform`, `query`, and `generate` for a transformation given with `--transformations`.

**Integer division.** `/` divides two Integers into a Real, as in OCL and Eclipse ATL, so `7 / 2` is `3.5` and `8 / 2` is `4.0`; `div` gives the truncated Integer quotient. `--integer-division truncating` (or `--semantics legacy`) makes `/` truncate the quotient of two Integers, as version 0.6 did. `transform` and `query` run ATL source with the option, and `generate` runs a transformation given with `--transformations` with it.

**Bags.** A Bag is a collection kind of its own, as in OCL and Eclipse ATL: `Bag{...}`, `asBag()`, and `collect` on a Set or a Bag give Bags, and so does navigating a feature over a Set or a Bag, as `collect` would. A Bag keeps its duplicates, is neither a Sequence nor a Set for `oclIsKindOf`, reports `Bag` as its `oclType()`, is written as `Bag{2, 1, 2}`, and equals a collection that holds each element equally often, in any order. It has no positions, so `at()` on a Bag is an error. A Bag receives the helpers declared for `Bag(T)`, then those for `Collection(T)`, then those for `OclAny`, but not those for `Sequence(T)`. `--bag-representation sequence` (or `--semantics legacy`) makes them Sequences, as version 0.6 did. `transform` and `query` run ATL source with the option, and `generate` runs a transformation given with `--transformations` with it.

**Validation only.** `--validate-only` reports a metamodel without classifiers, a model element type that its metamodel does not define, a binding of a feature that the class of its target element does not have, in the rules and helper contexts of the module, and a rule that uses `drop` outside refining mode. It then maps and loads the source models and maps the target models that are given. Expressions are not type-checked. With `--quiet`, nothing is printed on success.

**Built-in metamodels.** The Ecore metamodel (`http://www.eclipse.org/emf/2002/Ecore`) and the generator metamodel (`http://www.eclipse.org/emf/2002/GenModel`) are built in. A transformation names them with directives, so no metamodel file is needed:

```text
-- @nsURI Ecore=http://www.eclipse.org/emf/2002/Ecore
-- @nsURI GenModel=http://www.eclipse.org/emf/2002/GenModel
module Tiny;
create OUT : GenModel from IN : Ecore;
```

**Output layout.** A target that is an instance of a built-in metamodel is written in the layout of the Eclipse Modeling Framework: references to other models are `uri#fragment` attribute values (`ecorePackage="library.ecore#/"`), with relative URIs and name-based fragments, so that the result opens unchanged in the Eclipse tooling. Other targets keep the usual layout, unless `--reference-style plain` is given: such an XMI target is then also written in the layout of the Eclipse Modeling Framework, and a reference into the same document holds the fragment alone (`peer="/0"`) rather than `#/0`, as Eclipse writes XMI model files. `encoded`, the default, keeps the usual layout. Both styles load again.

**Empty targets.** A transformation whose rules match nothing still succeeds and writes each target as an empty model: an XMI document holding only the `xmi:XMI` element, or an empty JSON array.

**Examples:**

```bash
# Basic transformation
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi

# Explicit aliases and a metamodel directory
swift-atl transform MyTransformation.atl \
    --source IN=input.xmi \
    --target OUT=output.xmi \
    --metamodel-path metamodels/

# Metamodel files instead of -- @path directives
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi --source-metamodel Families.ecore \
    --target output-Persons.xmi --target-metamodel Persons.ecore

# Refine a model with one metamodel for source and target
swift-atl transform Cleanup.atl --refining \
    --source customers.xmi --target cleaned.xmi \
    --metamodel Customer.ecore

# Check a transformation without running it
swift-atl transform Families2Persons.atl --validate-only \
    --source-metamodel Families.ecore --target-metamodel Persons.ecore

# Parameters for a transformation that declares them with -- @param
swift-atl transform Library2Report.atl \
    --source IN=library.xmi \
    --target OUT=report.xmi \
    --param title=Catalogue --param limit=10

# Write same-document references of an XMI target as Eclipse writes XMI model files
swift-atl transform Families2Persons.atl --source families.xmi --target persons.xmi \
    --reference-style plain

# Metamodel files by name rather than by position
swift-atl transform Families2Persons.atl --source families.xmi --source-metamodel Families.ecore \
    --target persons.xmi --target-metamodel Persons=Persons.ecore
```

### query

Evaluate an ATL query unit over its input models and print its value.

```bash
swift-atl query <query-file> [options]
```

A query unit starts with `query Name = expression;` instead of a module header, and contains only helpers besides its query. `transform` rejects a query unit, and `query` rejects a module.

**Options:**

- `--source <[NAME[:METAMODEL]=]path>` - Input model file; repeat for several models. A bare path is matched to the metamodels of the query in order, `NAME=path` binds the model of the metamodel `NAME`, and `NAME:METAMODEL=path` names the model `NAME` and binds it to `METAMODEL`
- `-m, --metamodel <[NAME=]file.ecore>` - Ecore metamodel bound to the metamodel name `NAME`, or to the name of its package (repeatable)
- `--output-directory <directory>` - Directory that `writeTo` and `writeToWithCharset` write into (default: the current directory)
- `--allow-unrestricted-paths` - Let `writeTo` and `writeToWithCharset` write to absolute paths and outside the output directory
- `--print-result` / `--no-print-result` - Print the value of the query to standard output (default: print)
- `--param <name=value>` - Value for a parameter declared with `-- @param` (repeatable)
- `--input-format <xmi|json>` - Format of the input models (default: from the file extension)
- `--metamodel-path <directory>` - Directory searched for metamodels named by `-- @path` directives (repeatable)
- `--unset-features <defaults|undefined>` - How the query reads features that a model does not set
- `--verbose` - Write progress to standard error
- `--debug` - Trace the execution
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Input models.** A query has no `from` clause. Its metamodels are those named by its `-- @path` and `-- @nsURI` directives, followed by those given with `--metamodel`, and each is an input model of the same name. Type references such as `Flow!Step` resolve through the metamodel name, `allInstances()` collects the instances of every model of that metamodel, and `allInstancesFrom('IN')` selects the model named `IN`.

**Writing files.** `writeTo(path)` writes a string in UTF-8, and `writeToWithCharset(path, charset)` in `UTF-8`, `UTF-16`, `UTF-16BE`, `UTF-16LE`, `UTF-32`, `UTF-32BE`, `UTF-32LE`, `ISO-8859-1` or `US-ASCII`. Both return `true`, replace an existing file, create missing directories and add no line break. Relative paths are resolved against the output directory. Absolute paths and paths that lead outside the output directory, through `..` or through symbolic links, are rejected with an error that names the path, unless `--allow-unrestricted-paths` is given. Eclipse ATL resolves relative paths against the workspace or the working directory of the Java process and accepts any path; give `--allow-unrestricted-paths` only for queries you trust. Transformations run by `transform` cannot write files, so a transformation that calls `writeTo` fails.

**Result.** The value of the query is printed to standard output: a string as it is, followed by a line break unless it ends with one, and any other value as ATL writes it, such as `true`, `42`, `Sequence{'a', 'b'}` or `Bag{'a', 'a'}`. A query that ends with `writeTo` prints `true`. `--no-print-result` prints nothing. Messages, including the progress that `--verbose` reports, go to standard error. Eclipse ATL returns the value to the program that launched the query, and its launcher discards it.

**Examples:**

```bash
# Write the dot file that the query builds, below graphs/
swift-atl query Flow2Dot.atl --source order.xmi --output-directory graphs

# Print the value of a query to a file instead
swift-atl query FlowText.atl --source Flow=order.xmi > order.txt

# Name the model and give the metamodel on the command line
swift-atl query Count.atl --metamodel Flow=Flow.ecore \
    --source IN:Flow=order.xmi --param offset=10
```

### generate

Generate generator models and source code from Ecore models.

```bash
swift-atl generate <model.ecore | model.genmodel> [options]
```

The command is the ATL entry to the shared generation pipeline. An Ecore model is transformed into a generator model with the bundled `Ecore2GenModel.atl`; the pseudo-language `genmodel` stops there, and the name of a template set, such as `java`, `swift`, `c` or `cpp`, continues to source files. The verification targets `alloy`, `tla`, `eventb` and `lean` write the metamodel as a specification of the formal language instead; the help lists them apart from the code languages, and `swift-ecore generate --model` also exports models to them. A generator model is generated from directly.

**Options:**

- `-l, --language <name>` - `genmodel` (default), or the name of a template set; the help lists the bundled ones, and an unknown name is rejected with every language that can be used, including the ones that `--template-path` adds
- `-o, --output <path>` - Output directory (default: `Generated`); for `genmodel`, the directory or `.genmodel` file to write (default: beside the Ecore model)
- `--transformations <path>` - A transformation file, or a directory holding `Ecore2GenModel.atl`, that replaces the bundled transformation; the replacement receives the same parameters as the bundled one
- `--unset-features <defaults|undefined>` - How the transformation and the templates read features that a model does not set, as for `transform`
- `--base-package <name>`, `--prefix <[package=]name>` (repeatable), `--model-project <name>`, `--model-plugin-id <id>`, `--copyright <text>`, `--jdk-level <level>` - Settings of the generator model, as for `swift-ecore genmodel`
- `--defaults headless|wizard`, `--root-extends-class <name>`, `--operation-reflection` / `--no-operation-reflection`, `--import-organizing` / `--no-import-organizing` - The preset of the generator model defaults and its overrides, as for `swift-ecore genmodel`; they only apply to an Ecore model
- `--template-path <directory>` - Directory with template files that replace bundled templates (repeatable)
- `--force-overwrite` - Replace existing files without merging
- `--diff` - Write the generated text of existing files beside them as `.<name>.new`
- `--model-directory` - Write below the model directory of the generator model
- `--code-style <style>` - The layout of the generated text, one of the styles of the template set (`java`: `eclipse`, the default, or `emf`); rejected for the language `genmodel` and for sets that offer none, such as `swift`, `c` and `cpp`
- `--let-type-mismatches <error|skip>` - Whether a typed `let` in the templates whose value does not conform to the declared type stops the generation (`error`, the default) or is skipped with a warning on standard error (`skip`, as in Acceleo 3)
- `--block-line-breaks <acceleo|kept>`, `--collection-parameters <conforming|exact>`, `--check-let-types` / `--no-check-let-types`, `--cache-containers` / `--no-cache-containers`, `--collection-arguments <whole|first-element>`, `--collection-kinds <distinguished|sequences>`, `--single-value-collections <set|sequence>`, `--container-lookup <resources|registered-objects>`, `--sequence-union <concatenation|distinct>`, `--null-addition <empty-text|null>`, `--text-form <joined|bracketed>`, `--dot-calls <each-element|collection>` - The behaviours of the templates, as for `swift-mtl generate`; the first value is the default, and the second that of version 0.6
- `--strict-aql` / `--no-strict-aql` - Whether the expressions of the templates reject what Eclipse AQL rejects, as for `swift-mtl generate`; neither preset sets it
- `--collection-range-syntax <ocl|eclipse>` - Whether a transformation given with `--transformations` may use integer ranges such as `Sequence{1..3}` (`ocl`, the default) or not, as in Eclipse ATL and version 0.6 (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` in a transformation given with `--transformations` divides two Integers into a Real, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set in a transformation given with `--transformations` give Bags, as in OCL and Eclipse ATL (`bag`, the default), or Sequences as version 0.6 did (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`) for every behaviour option above; a behaviour option that is given overrides it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of a transformation given with `--transformations` and of the templates with the modules they import, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8; a template is named by its path within the template set); the `encoding` key of the configuration file names it too
- `--verbose` - One line for every file; without it a progress bar with counts appears on an interactive terminal

**Examples:**

```bash
# Create library.genmodel beside library.ecore
swift-atl generate model/library.ecore --language genmodel --base-package org.example

# Generate Swift in one step
swift-atl generate model/library.ecore --language swift -o Sources/Library

# Generate a C11 or a C++20 model API
swift-atl generate model/library.ecore --language c -o c-src
swift-atl generate model/library.ecore --language cpp -o cpp-src

# Generate Java in one step
swift-atl generate model/library.ecore --language java --base-package org.example -o src-gen

# Replace the transformation, customise the templates
swift-atl generate model/library.ecore --language java --transformations my-atl/ \
    --template-path my-templates -o src-gen
```

### parse

Parse ATL transformation files and report their structure.

```bash
swift-atl parse [<atl-files> ...] [options]
```

**Options:**

- `-f, --format <text|json|xml>` - Output format (default: `text`)
- `-o, --output <file>` - Write the results to a file
- `--metamodel-path <directory>` - Metamodel search path (repeatable)
- `-v, --verbose` - Enable verbose output
- `--show-structure`, `--show-rules`, `--show-helpers` - Show the module structure, the rule details, or the helper details
- `--enable-stop-after-errors`, `--disable-stop-after-errors` - Stop after metamodel loading errors (default: disabled)
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Examples:**

```bash
swift-atl parse Families2Persons.atl --verbose
swift-atl parse *.atl --output parsing-report.txt
swift-atl parse transformation.atl --format json
```

### validate

Validate ATL transformation files for syntax and semantic
correctness.

```bash
swift-atl validate [<atl-files> ...] [options]
```

**Options:**

- `-o, --output <file>` - Write the validation results to a file
- `--metamodel-path <directory>` - Metamodel search path (repeatable)
- `-v, --verbose` - Enable verbose output
- `--strict` - Enable strict validation mode
- `--check-metamodels` - Check metamodel compatibility
- `--check-rules` - Validate rule completeness
- `--enable-stop-after-errors`, `--disable-stop-after-errors` - Stop after metamodel loading errors (default: disabled)
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Examples:**

```bash
# Basic validation
swift-atl validate Families2Persons.atl

# Strict validation of several files, with a log
swift-atl validate *.atl --strict --output validation.log

# Check metamodel compatibility
swift-atl validate transformation.atl --check-metamodels \
    --metamodel-path metamodels/
```

### test

Run parsing, validation and transformation execution tests on ATL
files, or on a directory of them.

```bash
swift-atl test [<atl-files> ...] [options]
```

**Options:**

- `-d, --directory <directory>` - Directory containing ATL test files
- `-t, --timeout <seconds>` - The time limit for checking each file, a positive number of seconds (default: 60); a file whose checks take longer is reported as failed with 'Test timed out after N seconds', and testing continues with the next file. Each file is reported as soon as its checks finish. Parsing cannot be interrupted, so a file whose parsing overruns the limit keeps using processor time until its parsing ends or the command exits
- `-o, --output <file>` - Write the test results to a file
- `-v, --verbose` - Enable verbose output
- `--fail-fast` - Stop on the first test failure
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Examples:**

```bash
swift-atl test Families2Persons.atl
swift-atl test --directory Tests/ATLTests/Resources
swift-atl test *.atl --timeout 30 --verbose
```

### analyze

Report complexity metrics, rule and helper analysis, and
transformation patterns for ATL files.

```bash
swift-atl analyze [<atl-files> ...] [options]
```

**Options:**

- `--metrics <list>` - Comma-separated metrics to compute from `complexity`, `rules`, `helpers` and `patterns` (default: all)
- `-o, --output <file>` - Write the results to a file
- `-f, --format <text|json>` - Output format (default: `text`)
- `-v, --verbose` - Enable verbose output
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Examples:**

```bash
swift-atl analyze Families2Persons.atl
swift-atl analyze *.atl --metrics complexity,rules,helpers
swift-atl analyze transformation.atl --output analysis.json
```

### compile

Compile an ATL transformation file.

```bash
swift-atl compile <atl-file> [options]
```

The command parses the transformation and names the compiled module, which defaults to the input file name with a `.atlc` extension. Run transformations with `swift-atl transform` on the `.atl` source file.

**Options:**

- `-o, --output <file>` - Output file for the compiled transformation
- `-v, --verbose` - Enable verbose output
- `--optimise` - Optimise the transformation code
- `--collection-range-syntax <ocl|eclipse>` - Whether collection literals accept integer ranges such as `Sequence{1..3}` (`ocl`, the default) or reject them as Eclipse ATL and version 0.6 do (`eclipse`)
- `--integer-division <real|truncating>` - Whether `/` divides two Integers into a Real, so `7 / 2` is `3.5`, as in OCL and Eclipse ATL (`real`, the default), or truncates the quotient to an Integer as version 0.6 did (`truncating`)
- `--bag-representation <bag|sequence>` - Whether `Bag{...}`, `asBag()` and `collect` on a Set give Bags, a collection kind of their own as in OCL and Eclipse ATL (`bag`, the default), or Sequences as in version 0.6 (`sequence`)
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`); `--collection-range-syntax`, `--integer-division` and `--bag-representation` override it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models of the run that it holds in containment references (`any-resource`, the default) or only of its own objects (`this-resource`, as in version 0.6); without the option, it follows the preset
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of the ATL source, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too

**Example:**

```bash
swift-atl compile Families2Persons.atl --output families2persons.atlc
```

### check-compat

Check whether a transformation can be used with other metamodels, such as revised versions of its
source or target metamodels, without running it.

```bash
swift-atl check-compat <atl-file> --metamodel <name=file> ... --target-metamodel <name=file> ... [options]
```

The command extracts the footprint of the transformation, the classes, features and enumeration
literals that it reads, creates and writes, and checks the target metamodels against it by
structural model subtyping. Each `--metamodel` is named after a metamodel of the module header,
such as `Families` in `create OUT : Persons from IN : Families`: the metamodels of source models
are checked for what the transformation reads, and those of target models for what it creates and
writes. A metamodel of the header without `--metamodel` is not checked, which makes the verdict
inconclusive. The library behind the command is described in the ModelTyping documentation.

**Options:**

- `-m, --metamodel <name=file>` - A metamodel that the transformation was written against, named after a metamodel of the module header (repeatable); the file may be in any metamodel format, such as Ecore, JSON, KM3 or EMOF
- `--target-metamodel <name=file>` - A metamodel to check the transformation against, under the name of a `--metamodel` (repeatable); a metamodel without one is checked against itself, as if it were unchanged
- `--mode <total-isomorphic|total-non-isomorphic|partial-isomorphic|partial>` - The subtyping relation to decide (default: `partial`): whether every element of the metamodel (`total-...`) or only the elements the transformation uses (`partial...`) must exist in the target metamodel, and whether under the same names (`...isomorphic`) or after the renamings of `--rename`
- `--subtyping <access-refined|object-type-matching|mof-class-matching>` - How model subtyping matches classes and features (default: `access-refined`, which compares each element by how the transformation reads, writes or instantiates it); `object-type-matching` (alias `steel-jezequel`) and `mof-class-matching` (alias `guy`) are the published definitions of [Steel and Jézéquel (2007)](https://doi.org/10.1007/s10270-006-0036-6) and [Guy et al. (2012)](https://doi.org/10.1007/978-3-642-31491-9_30)
- `--rename <required=provided>` - Map a name of the original metamodel to a name of the target metamodel, as `Class=NewClass` for a class, enumeration or data type, or `Owner.member=newMember` for a feature or literal (repeatable, or separated by commas); renamings apply in the modes `partial` and `total-non-isomorphic`
- `--allow-widening` - Let numeric types widen in the direction of use: an attribute that is read may have a narrower type in the target metamodel, such as `EInt` where `ELong` was declared, and one that is written a wider type
- `--lenient-lower-bounds` - Report lower bounds that do not conform as warnings instead of errors
- `--format <text|json>` - The format of the report (default: `text`); `json` writes one object with the flags `compatible` and `conclusive`, the mode, the findings, the footprint and the renaming hints
- `--encoding <name>` - The character encoding of the transformation (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8)
- `--km3-primitives`, `--package-name`, `--ns-uri`, `--ns-prefix`, `--asdl-enumerations`, `--langium-types`, `--sdf3-labels` - How metamodels in KM3 and grammar formats are read, as for the other commands

The report is printed to standard output. Its first line states the verdict, the mode and the
numbers of errors and warnings, such as `incompatible (partial): 1 error(s), 0 warning(s)`;
each finding follows on a line of its own, starting with `error:` or `warning:` and naming the
element, such as `Families!Member.firstName`, then each `uncertain:` use whose type could not be inferred, and
each hint, such as `hint: --rename Member.firstName=givenName`, with the reason for it in parentheses, that would
reconcile a missing element.

**Exit status:**

- `0` - The target metamodels are compatible
- `1` - The target metamodels are not compatible
- `2` - No incompatibility was found, but the types of some expressions could not be inferred, so the verdict is inconclusive
- `3` - The check could not be made, such as for a file that cannot be read or parsed, or a metamodel name that the module header does not declare
- `64` - The arguments are invalid, such as a `--target-metamodel` whose name no `--metamodel` gives

**Examples:**

```bash
# Check the transformation against a revised source metamodel
swift-atl check-compat Families2Persons.atl \
    --metamodel Families=Families.ecore --metamodel Persons=Persons.ecore \
    --target-metamodel Families=FamiliesV2.ecore

# Apply the suggested renaming
swift-atl check-compat Families2Persons.atl \
    --metamodel Families=Families.ecore --metamodel Persons=Persons.ecore \
    --target-metamodel Families=FamiliesV2.ecore --rename Member.firstName=givenName

# Decide total isomorphic subtyping with MOF class matching, as JSON
swift-atl check-compat Families2Persons.atl \
    --metamodel Families=Families.ecore --metamodel Persons=Persons.ecore \
    --target-metamodel Persons=PersonsV2.ecore \
    --mode total-isomorphic --subtyping mof-class-matching --format json
```

## Environment and Configuration File

The Compatibility with 0.6 section of the [SwiftModelling documentation](https://mipalgu.github.io/swift-modelling/documentation/swiftmodelling/swiftmodelling/index.html) lists every behaviour option with its default and its version 0.6 behaviour, and describes the environment variable and the configuration file in full.

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable (`standard` or `legacy`) chooses the preset, and then the `semantics` key of a configuration file. The configuration file is the first `.swift-modelling.json` in the current directory or one of its parents, up to the directory that holds `.git`; `--config` names another file and `--no-config` reads none. Its keys are the names of the behaviour options without their leading `--`, with the spellings of the command line as JSON strings, or JSON booleans for `check-let-types`, `cache-containers` and `strict-aql`; a key that does not apply to a command is ignored. A behaviour option given on the command line overrides the file, an option in the file overrides the preset, `--semantics` overrides the environment variable, and the environment variable overrides `semantics` in the file. `--let-type-mismatches` and `--unset-features` do not depend on the preset: the command line overrides the file, which overrides their defaults. An invalid value of the variable, or an unknown key or an invalid value in the file, stops the command with an error that names it.

```json
{
  "semantics": "legacy",
  "block-line-breaks": "acceleo",
  "check-let-types": true,
  "container-scope": "any-resource"
}
```

## Common Workflows

### Developing and Testing Transformations

```bash
# 1. Validate transformation syntax
swift-atl validate Families2Persons.atl --verbose

# 2. Run the transformation with execution tracing
swift-atl transform Families2Persons.atl \
    --source sample-Families.xmi \
    --target output-Persons.xmi \
    --debug

# 3. Validate output model
swift-ecore validate output-Persons.xmi \
    --metamodel Persons.ecore
```

### Batch Processing Multiple Models

```bash
# Process multiple models with the same transformation
for input in models/*.xmi; do
    output="output/$(basename "$input")"
    swift-atl transform Families2Persons.atl \
        --source "$input" \
        --target "$output" \
        --verbose
done
```

## Transformation Syntax Reference

### Module Declaration

```atl
module Families2Persons;
create OUT: Persons from IN: Families;
```

### Helpers

```atl
-- Context helper
helper context Families!Member def: fullName: String =
    self.firstName + ' ' + self.lastName;

-- Module helper
helper def: isMale(m: Families!Member): Boolean =
    not m.isFemale();
```

### Matched Rules

```atl
rule Member2Male {
    from
        s: Families!Member (not s.isFemale())
    to
        t: Persons!Male (
            fullName <- s.firstName + ' ' + s.familyName
        )
}
```

### Lazy Rules

```atl
lazy rule CreateAddress {
    from
        s: Families!Member
    to
        t: Persons!Address (
            street <- s.street,
            city <- s.city
        )
}
```

### Called Rules

```atl
rule ProcessFamily {
    from
        s: Families!Family
    to
        t: Persons!Group (
            members <- s.members->collect(m | thisModule.CreatePerson(m))
        )
}

called rule CreatePerson(member: Families!Member) {
    to
        p: Persons!Person (
            name <- member.firstName
        )
    do {
        p;
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:UnderstandingSwiftATL>

## See Also

- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
