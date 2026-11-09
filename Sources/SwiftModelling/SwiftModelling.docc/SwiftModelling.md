# SwiftModelling

Build powerful Model-Driven Engineering (MDE) applications with Swift.

## Overview

SwiftModelling provides a comprehensive suite of CLI tools for Model-Driven Engineering using Swift 6. Transform, validate, and generate code from your models with industry-standard technologies including Ecore, ATL, MTL, and AQL.

### Key Technologies

- **Ecore**: EMF-compatible metamodelling and model validation
- **ATL**: Atlas Transformation Language for model-to-model transformations
- **MTL**: Model-to-Text Language for code generation
- **AQL**: Acceleo Query Language for model analysis
- **Henshin**: graph transformation rules and units, with critical pair analysis and state-space exploration
- **Epsilon**: the Epsilon Object, Validation, Transformation and Generation Languages (EOL, EVL, ETL and EGL)
- **Xtend**: Xtend classes and their methods and generators

### CLI Tools

- swift-ecore: Model validation, conversion, querying, generator models and code generation
- swift-atl: Model transformation execution and generation from Ecore models
- swift-mtl: Template-based code generation
- swift-aql: Evaluation of AQL queries against models
- swift-henshin: Henshin graph transformation: applying rules and units, validation, conflict and dependency analysis, and state-space exploration
- swift-epsilon: Epsilon languages: EOL programs, EVL constraints, ETL transformations and EGL templates
- swift-xtend: Xtend methods and generators run on models

The documentation of each tool lists its commands and options, and describes its features in detail.

### Architecture

The tools `swift-ecore`, `swift-atl`, `swift-mtl` and `swift-aql` are built on four packages, each a pure Swift implementation without Java dependencies:

- **swift-ecore**: the Ecore metamodel, resources, and XMI and JSON serialisation
- **swift-atl**: the ATL parser and execution engine
- **swift-mtl**: the MTL parser, runtime and generation engine
- **swift-aql**: the AQL expression language that templates and queries share

The tools `swift-henshin`, `swift-epsilon` and `swift-xtend` build on the packages of the same names, which implement Henshin, the Epsilon languages and Xtend in pure Swift on swift-ecore.

Besides the tools, this package offers these library products:

- **ModellingGenerators**: the generator model pipeline and the bundled template sets for Swift, Java, C and C++
- **ModellingPipeline**: steps for running ATL transformations and MTL generations on models in memory, a locator for template sets in the resource directories of other packages, and a pipeline that loads, transforms, generates from and saves models in sequence
- **ModelTyping**: model types and the checks of `check-compat` that decide whether an ATL transformation, an MTL template or an AQL expression written for one metamodel can be reused with another
- **ModellingCommandLine**: the option groups that the tools share, such as `--param`, `--template-path`, `--metamodel`, `--code-style`, `--encoding` and `--semantics`, and a parser for families of `name=value` options, for command-line tools of other packages

All model types are value types (structs) for thread safety, with ID-based reference resolution for bidirectional relationships. Resources provide object ownership and cross-reference resolution as in the Eclipse Modeling Framework, using actor-based concurrency.

### Interoperability

- Every command exits with status 0 on success and with a non-zero status on an error, so the tools suit scripts and continuous integration pipelines. `--verbose` reports progress, which helps with large models.
- The tools behave identically on macOS, Linux and Windows.
- Swift Modelling aims for full round-trip compatibility with [emf4cpp](https://github.com/catedrasaes-umu/emf4cpp), the C++ implementation of the Eclipse Modeling Framework, and with [pyecore](https://github.com/pyecore/pyecore), its Python implementation. JSON written by `swift-ecore` is compatible with PyEcore for cross-language workflows.

### From Ecore to Java

Convert an Ecore model into an Eclipse generator model (`.genmodel`) and into Java that compiles against the EMF runtime, with `swift-ecore genmodel` and `swift-ecore generate --language java`, or in one step with `swift-atl generate --language java`.

- Converting Ecore to GenModel and Java: the commands, every option and the files written, with the Eclipse extended library example.
- Matching Eclipse: how the output relates to Eclipse's generator, and the options that choose between its behaviours.
- Both articles belong to the ModellingGenerators documentation, which also covers template sets and Java generation. Find them in the sidebar or on the front page of this site.
- <doc:Tutorials>: a step-by-step tutorial on the same conversion.

### From Ecore to Swift

Generate Swift model code that compiles against the ECore runtime, from an Ecore model or a generator model, with `swift-ecore generate` (Swift is its default language) or `swift-atl generate --language swift`. The code is written by the bundled `swift` template set, so it can be customised with `--template-path` like the Java output.

- Swift Generation: what the set writes for classes, enumerations, data types, packages and factories, how names are made safe, and how existing files are merged. Find it in the ModellingGenerators documentation.

### Incremental Execution

Applications that keep a model open, such as editors, can bring the results of queries and transformations up to date after each change instead of computing them afresh. Incremental execution is offered by the libraries only: every command of the tools reads its files, runs once and exits, so it has no incremental form.

- **ATL**: `ATLIncrementalTransformation` of the swift-atl package executes a module once, records what its guards and bindings read, and propagates later changes of the source models to the target models with `update()`. The article Incremental Transformations of the ATL library describes it.
- **AQL**: `AQLIncrementalExpression` of the swift-aql package keeps the value of an expression up to date and reports the elements added to and removed from it, and `AQLQueryObserver` refreshes many expressions at once. The article Incremental Queries of the AQL library describes them.
- **Ecore**: the ECore library of the swift-ecore package provides what both build on: change observation with `ResourceChangeQueue`, dependencies with `ModelDependencies` and `ModelDependencyRecorder`, and their impact with `ModelChangeImpact`, as its article Incremental Evaluation describes.

Changes must be made through the editing operations of `Resource`, such as `eSetWithChanges(objectId:feature:value:)`, so that they are observed.

### Compatibility with 0.6

The tools follow the behaviour of this release by default. Each behaviour that changed since version 0.6 has an option, and `--semantics legacy` selects the behaviour of version 0.6 for all of them at once. An option given on the command line overrides the preset, whatever the order of the options, so `--semantics legacy --block-line-breaks acceleo` behaves as version 0.6 apart from the line breaks. `--semantics standard` is the default.

| Behaviour | Default | Option | 0.6 behaviour | Applies to |
| :-- | :-- | :-- | :-- | :-- |
| Line break after a block written on one line, such as `[if (c)][helper()/][/if]` | dropped when the line is empty once the block has run, as in Acceleo 4 (`acceleo`) | `--block-line-breaks acceleo\|kept` | `kept` | templates |
| Collections passed to collection-typed parameters, such as `Sequence(String)` | any collection whose elements conform, including many-valued features and a single object, with overloads chosen by element types (`conforming`) | `--collection-parameters conforming\|exact` | `exact` | templates |
| Declared types of `let` variables | checked, and a mismatch handled as `--let-type-mismatches` says | `--check-let-types`, `--no-check-let-types` | `--no-check-let-types` | templates |
| Container lookups during a run | cached, so models may change during a run only through services that declare that they modify models | `--cache-containers`, `--no-cache-containers` | `--no-cache-containers` | templates |
| A collection added by `append`, `prepend`, `including` and `insertAt` | added whole, so `Sequence{'a'}->append(Sequence{'b', 'c'})` has two elements (`whole`) | `--collection-arguments whole\|first-element` | `first-element` | templates |
| Kinds of collections | sequences, ordered sets, sets and bags keep their kinds, and sets do not repeat elements (`distinguished`) | `--collection-kinds distinguished\|sequences` | `sequences` | templates |
| Arrow calls on a single value, such as `'a'->including('a')` | the value is a set, giving `Set{'a'}` (`set`) | `--single-value-collections set\|sequence` | `sequence` | templates |
| `union` of a sequence or a bag, such as `Sequence{'a', 'b'}->union(Sequence{'b'})` | keeps repeated elements, as in Eclipse AQL (`concatenation`) | `--sequence-union concatenation\|distinct` | `distinct`: leaves them out | templates |
| `+` with a null operand, such as `null + 'x'` | null counts as empty text, giving `'x'` (`empty-text`) | `--null-addition empty-text\|null` | `null`: the result is null | templates |
| The text of a collection, from `toString()` or `+` with a string | the texts of the elements joined, `'ab'` for `Sequence{'a', 'b'}` (`joined`) | `--text-form joined\|bracketed` | `bracketed`: `'[a, b]'` | templates |
| A call written with `.` on a collection, such as `Sequence{'ab', 'c'}.size()` | applies to each element, as in Eclipse AQL, giving `Sequence{2, 1}` (`each-element`); `->` always calls the collection operation | `--dot-calls each-element\|collection` | `collection`: calls the collection operation, giving `2` | templates |
| `eContainer()` and the services that depend on it | the registered resources are asked, so containers of nested metamodel contents are found (`resources`) | `--container-lookup resources\|registered-objects` | `registered-objects` | templates |
| Integer ranges in ATL collection literals, such as `Sequence{1..3}` | accepted, as in OCL (`ocl`) | `--collection-range-syntax ocl\|eclipse` | `eclipse`: rejected | ATL source |
| `/` with two Integer operands in ATL, such as `7 / 2` | a Real, `3.5`, as in OCL and Eclipse ATL (`real`) | `--integer-division real\|truncating` | `truncating`: the Integer `3` | ATL source |
| Bags in ATL, such as `Bag{2, 1, 2}` and `Set{1, 2}->collect(e \| 0)` | a collection kind of its own, as in OCL and Eclipse ATL, so `Bag{2, 1, 2}->oclType()` is `Bag` (`bag`) | `--bag-representation bag\|sequence` | `sequence`: Sequences, so `oclType()` is `Sequence` | ATL source |
| Containers of objects that another model of the run holds in a containment reference | found, as each model answers for the objects of any model (`any-resource`) | `--container-scope any-resource\|this-resource` | `this-resource`: each model answers only for its own objects | models |

The options for templates apply to `swift-mtl generate`, `swift-ecore generate` and `swift-atl generate`; the options of the expressions among them (`--collection-arguments`, `--collection-kinds`, `--single-value-collections`, `--sequence-union`, `--null-addition`, `--text-form`, `--dot-calls` and `--container-lookup`) also apply to `swift-aql`. The options for ATL source apply to `swift-atl parse`, `validate`, `analyze`, `compile`, `test`, `transform` and `query`, and to `swift-atl generate` for a transformation given with `--transformations`. `--container-scope` is accepted by every command that accepts `--semantics`, and applies to the models that `swift-mtl generate`, `swift-ecore generate`, `swift-atl generate`, `transform` and `query` load. `--unset-features` and `--let-type-mismatches` have the same defaults in both presets, `defaults` and `error`, and neither preset sets `--strict-aql`. No command writes ATL modules as XMI, so the encoding of ranges in ATL XMI has no option. The help of each command and the documentation of each tool describe the options.

#### Choosing the Semantics from the Environment

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable chooses the preset for every command that accepts `--semantics`. Its values are `standard` and `legacy`; an empty value counts as unset, and any other value stops the command with an error that names the variable, the value and the accepted values.

```bash
# Run every tool of this shell session as version 0.6 did
export SWIFT_MODELLING_SEMANTICS=legacy
swift-mtl generate template.mtl --model input.xmi --output generated/
```

#### Configuration File

A configuration file keeps the behaviours of a project with the project. A command that accepts `--semantics`, and each command of `swift-ecore` that reads models and metamodels, reads the first file named `.swift-modelling.json` that it finds in the current directory or one of its parent directories, up to and including the first directory that contains `.git`, which is the root of the repository. `--config <file>` reads exactly the named file instead, and `--no-config` reads none; the two cannot be combined.

The file holds a JSON object. Its keys are `semantics` (`standard` or `legacy`) and the names of the behaviour options without their leading `--`: `block-line-breaks`, `collection-parameters`, `check-let-types`, `cache-containers`, `collection-arguments`, `collection-kinds`, `single-value-collections`, `container-lookup`, `sequence-union`, `null-addition`, `text-form`, `dot-calls`, `collection-range-syntax`, `integer-division`, `bag-representation`, `container-scope`, `let-type-mismatches`, `unset-features` and `strict-aql`, `encoding` for the character encoding of source files (see Source File Encodings below), `output-encoding` for the character encoding of the files that the commands write (see Output File Encodings below), `km3-primitives` for the data types of KM3 metamodels (see Metamodels in KM3 below), and `package-name`, `ns-uri`, `ns-prefix`, `asdl-enumerations`, `langium-types` and `sdf3-labels` for metamodels imported from grammars (see Metamodel Formats below), and `level-crossing` and `ocl` for the multi-level models and Complete OCL documents that `swift-ecore` reads. Each value is the spelling of the option on the command line as a JSON string, except for `check-let-types`, `cache-containers`, `strict-aql` and `sdf3-labels`, which take `true` or `false`, `encoding` and `output-encoding`, which take the name or an alias of a supported encoding, such as `"ISO-8859-1"` or `"latin1"`, `package-name`, `ns-uri` and `ns-prefix`, which take any string, and `ocl`, which takes a JSON array of paths of Complete OCL documents or directories of them, each relative to the directory of the configuration file unless it is absolute. `km3-primitives` takes `"ecore"` or `"declared"`, `asdl-enumerations` `"all-nullary"` or `"never"`, and `langium-types` `"normal"` or `"strict"`. A key that does not apply to a command, such as `block-line-breaks` for `swift-atl parse`, is ignored. An unknown key, a value of the wrong JSON type or spelling, text that is not JSON, or JSON that is not an object stops the command with an error that names the file and, where it applies, the key, the value and the accepted values.

```json
{
  "semantics": "legacy",
  "block-line-breaks": "acceleo",
  "check-let-types": true,
  "container-scope": "any-resource",
  "let-type-mismatches": "skip"
}
```

With this file, the commands behave as version 0.6, apart from the line breaks after one-line blocks, the checked `let` types and the container scope, and skip typed `let` blocks of another type with a warning.

Each behaviour comes from the first of these sources that sets it:

| Precedence | Source | Example |
|--|--|--|
| 1 (highest) | A behaviour option on the command line | `--block-line-breaks kept` |
| 2 | The same option in the configuration file | `"block-line-breaks": "kept"` |
| 3 | `--semantics` on the command line | `--semantics legacy` |
| 4 | The `SWIFT_MODELLING_SEMANTICS` environment variable | `SWIFT_MODELLING_SEMANTICS=legacy` |
| 5 | `semantics` in the configuration file | `"semantics": "legacy"` |
| 6 (lowest) | The built-in default | `standard` |

Sources 3 to 6 choose the preset, and the preset chooses each behaviour that sources 1 and 2 leave open, including the container scope: `any-resource` for `standard` and `this-resource` for `legacy`. `--let-type-mismatches`, `--unset-features`, `--encoding`, `--output-encoding`, `--km3-primitives` and the options of grammar imports do not depend on the preset: the command line overrides the configuration file, which overrides their defaults, `error`, `defaults`, reading UTF-8 with a fallback to ISO-8859-1, writing UTF-8, and those of the importers. Without a configuration file and without the environment variable, every command behaves as with `--semantics standard`.

The commands of `swift-ecore` that read models and metamodels, `convert`, `validate`, `inspect`, `compare`, `statistics`, `query` and `create`, take no preset: neither `--semantics`, the environment variable nor the `semantics` key applies to them. They honour the keys of the options they take and ignore the others. `swift-ecore genmodel` takes the preset as `swift-ecore generate` does.

Every key has a command-line option of the same name with the same values, and an option given on the command line overrides its key. A key applies to the commands that take its option and read the configuration file:

| Key | Option | Commands that honour the key |
|--|--|--|
| `semantics` | `--semantics <standard\|legacy>` | `swift-atl` `transform`, `query`, `generate`, `compile`, `parse`, `validate`, `test`, `analyze`; `swift-mtl generate`; `swift-aql` `evaluate`, `query`; `swift-ecore` `generate`, `genmodel`; `swift-epsilon` and `swift-xtend` commands |
| `container-scope` | `--container-scope` | the commands that honour `semantics`, apart from the `swift-atl` commands that load no models (`compile`, `parse`, `validate`, `test`, `analyze`) |
| `block-line-breaks`, `collection-parameters`, `check-let-types`, `cache-containers` | the options of the same names | `swift-mtl generate`, `swift-atl generate`, `swift-ecore generate` |
| `collection-arguments`, `collection-kinds`, `single-value-collections`, `container-lookup`, `sequence-union`, `null-addition`, `text-form`, `dot-calls`, `strict-aql` | the options of the same names | the commands that honour `block-line-breaks`, and `swift-aql` `evaluate`, `query` |
| `strict-aql` | `--strict-aql`, `--no-strict-aql` | also `swift-ecore validate` |
| `collection-range-syntax`, `integer-division`, `bag-representation` | the options of the same names | the `swift-atl` commands apart from `check-compat` |
| `let-type-mismatches` | `--let-type-mismatches` | `swift-mtl generate`, `swift-atl generate`, `swift-ecore generate` |
| `unset-features` | `--unset-features` | the commands that honour `block-line-breaks`, `swift-atl` `transform`, `query`, `swift-aql` `evaluate`, `query`, and `swift-ecore genmodel` |
| `encoding` | `--encoding <name>` | the commands that read source files or documents in text formats and the configuration file, including `swift-ecore` `convert`, `validate`, `inspect`, `compare`, `statistics`, `query`, `create` and `generate` |
| `output-encoding` | `--output-encoding <name>` | the commands that write files and read the configuration file, including `swift-ecore` `convert`, `create`, `genmodel`, `generate`, and `validate`, `inspect`, `compare` and `statistics` with a report file |
| `km3-primitives`, `package-name`, `ns-uri`, `ns-prefix`, `asdl-enumerations`, `langium-types`, `sdf3-labels` | the options of the same names (`--sdf3-labels`, `--no-sdf3-labels`) | the commands that read metamodels and the configuration file |
| `level-crossing` | `--level-crossing <strict\|declared\|non-strict>` | `swift-ecore` `convert`, `validate`, `inspect` |
| `ocl` | `--ocl <file.ocl>`, repeatable, also for a directory | `swift-ecore` `convert`, `validate`, `inspect`, `compare`, `statistics`, `query` |
| `reference-style` | `--reference-style <encoded\|plain>` | `swift-ecore convert`, `swift-atl transform`, the `swift-epsilon` commands |
| `code-style` | `--code-style <style>` | `swift-ecore generate`, `swift-atl generate`, `swift-mtl generate` with a template set |
| `defaults`, `root-extends-class` | `--defaults <headless\|wizard>`, `--root-extends-class <name>` | `swift-ecore` `genmodel`, `generate`, `swift-atl generate` |
| `operation-reflection`, `import-organizing` | `--operation-reflection` (`true`), `--no-operation-reflection` (`false`), and the same for `import-organizing` | `swift-ecore` `genmodel`, `generate`, `swift-atl generate` |
| `base-package`, `prefix`, `jdk-level` | `--base-package <name>`, `--prefix <[package=]name>` (repeatable; the key takes a list), `--jdk-level <level>` | `swift-ecore genmodel`, `swift-atl generate` |
| `strict` | `--strict` (`true`), `--no-strict` (`false`) | `swift-ecore validate`, `swift-atl validate`, `swift-epsilon evl validate` |
| `require-explicit-values` | `--require-explicit-values` (`true`), `--no-require-explicit-values` (`false`) | `swift-ecore validate` |
| `check-dangling` | `--check-dangling` (`true`), `--no-dangling-check` (`false`) | `swift-henshin` `apply`, `explore`, `analyse` |
| `injective` | `--injective` (`true`), `--non-injective` (`false`) | `swift-henshin` `apply`, `explore` |

`--config` and `--no-config` choose the file itself and have no key. Options that name the files of one run, such as `--metamodel`, `--output` or `--deep-view`, have no key. The `check-compat` commands, `swift-mtl parse` and `validate`, and `swift-henshin translate` read no configuration file, so their options, such as `--encoding`, apply only from the command line. The other commands of `swift-henshin` read it for `encoding`, `output-encoding`, `check-dangling` and `injective`. A `code-style` from the file is ignored where the option is rejected: for the language `genmodel` of `swift-atl generate`, for a template file of `swift-mtl generate`, and for a template set that offers no code styles, such as `swift`, `c` and `cpp`, so that one file serves every language. A style that a template set with code styles does not offer is an error, as for the option.

#### Source File Encodings

ATL transformations and queries, MTL templates and template sets with the modules they import, and AQL expression files are read as UTF-8. A file that is not valid UTF-8 is read as ISO-8859-1 instead, which accepts every byte, so that sources written with older tools still load, and a warning on standard error names the file and the line and column of the first byte that is not UTF-8:

```
warning: Families2Persons.atl: line 3, column 12: The text is not valid UTF-8 and was read as ISO-8859-1
```

`--encoding <name>` names the encoding of the source files instead. The supported encodings are `UTF-8`, `UTF-16`, `UTF-16BE`, `UTF-16LE`, `ISO-8859-1`, `windows-1252` and `US-ASCII`, each also by its registered aliases, such as `latin1` or `cp1252`, in any case. With an explicit encoding, every source file is read in that encoding alone, without a warning, and a file that is not valid in it stops the command with an error that names the file and the encoding. The `encoding` key of the configuration file names the encoding as well, and `--encoding` overrides it. A file that is valid UTF-8 reads exactly as before.

| Tool | Commands that take `--encoding` | Source files |
|--|--|--|
| `swift-atl` | `parse`, `validate`, `analyze`, `compile`, `test`, `transform`, `query`, `check-compat` | the ATL transformations and queries |
| `swift-atl` | `generate` | a transformation given with `--transformations`, and the templates of the template set with the modules they import |
| `swift-mtl` | `generate`, `parse`, `validate`, `check-compat` | the template file, or the templates of a template set given with `--template-set`, and the modules they import |
| `swift-ecore` | `generate` | the templates of the template set and the modules they import |
| `swift-ecore` | `convert`, `validate`, `inspect`, `compare`, `statistics`, `query` | the documents in text formats that they read, such as KM3, Emfatic, Xcore, OCLinEcore, Complete OCL and the grammar formats, including the metamodels and Complete OCL documents they are given |
| `swift-aql` | `evaluate`, `query`, `check-compat` | an expression or query file |

The files of a template set are copied together with the files that `--template-path` puts in their place before they are read, so a warning names a template by its path within the set, such as `warning: Header.mtl: line 2, column 4: ...`. `swift-mtl parse` and `validate` and the `check-compat` commands read no configuration file, so only `--encoding` applies to them. Models and metamodels in XML or JSON, such as XMI, Ecore and JSON documents, take their encoding from the document itself.

#### Output File Encodings

The files that the commands write, such as converted and transformed models, generator models, generated code and report files, are written in UTF-8. `--output-encoding <name>` names another encoding, from the same list and with the same aliases as `--encoding`, and the `output-encoding` key of the configuration file names it as well; `--output-encoding` overrides the key. Without either, every file is written exactly as before. What a command prints on standard output is not affected.

An XML document, such as XMI, Ecore, EMOF, UML or a generator model, names the encoding in its XML declaration, for example `encoding="ISO-8859-1"`, and a character that the encoding cannot hold is written as a numeric character reference, such as `&#x20AC;`, as the Eclipse Modeling Framework writes it. In `ISO-8859-1`, `windows-1252` and `US-ASCII`, the text is first precomposed (Unicode normalisation form C), so that a letter followed by a combining mark, such as an `e` followed by a combining acute accent as macOS file names often hold it, is written as the single character `é`; UTF-8 and UTF-16 files are written with the text as it is. In plain text, such as generated code, a textual notation such as KM3 or Emfatic, or a text report, a character that the encoding cannot hold even then stops the command with an error that names the file and the line and column of the character, and the file is not written:

```
Error: Cannot write Library.emf: the character '€' (U+20AC) at line 4, column 18 cannot be written in ISO-8859-1
```

JSON is always written in UTF-8, as RFC 8259 requires; when another encoding is named, the file is written in UTF-8 and a warning on standard error says so. An MTL `[file]` block that names its charset, and an ATL `writeToWithCharset`, keep the charset they name; the option chooses the charset of the files that name none.

| Tool | Commands that take `--output-encoding` | Files written |
|--|--|--|
| `swift-ecore` | `convert`, `create`, `genmodel`, `generate` | the converted or created model or metamodel, the generator model, and the generated code and verification exports |
| `swift-ecore` | `validate`, `inspect`, `compare`, `statistics` | the report file that they write when asked to |
| `swift-atl` | `transform`, `query`, `generate` | the target models, the files that `writeTo` writes, and the generated files |
| `swift-atl` | `parse`, `analyze`, `validate`, `test` | the output or report file that they write when asked to |
| `swift-mtl` | `generate` | the generated files |
| `swift-epsilon` | `generate`, `transform`, `validate`, `run` | the generated files and the models that they save |
| `swift-xtend` | `generate`, `run` | the generated files and the models that they save |
| `swift-henshin` | `apply`, `convert`, `explore` | the resulting model, the Henshin Text module and the state space graph |

`swift-aql` writes no files, so it takes no `--output-encoding`. The `output-encoding` key of the configuration file names the encoding for the commands of `swift-henshin` as well.

#### Warnings of Reading Metamodels

As in the Eclipse Modeling Framework, a root package of a metamodel need not declare a namespace URI or prefix. Such a package is loaded with an empty one, and the commands that read the metamodel write a warning to standard error that names the file and the package:

```
warning: Library.ecore: The package 'Types' has no 'nsURI' and is not registered under a namespace
```

The warning does not change the exit status. `swift-ecore validate` still reports a missing namespace URI as an error of the constraint `WellFormedNsURI`. Errors of reading a metamodel that do not stop the command, such as a syntax error in a KM3 metamodel, are written to standard error in the same way, starting with `error:`.

#### Metamodels in KM3

Wherever a metamodel is accepted, with `--metamodel`, `--source-metamodel` or `--target-metamodel`, or as a metamodel that a command reads, it may be in any metamodel format that swift-ecore reads, such as an Ecore file (`.ecore`), a JSON metamodel (`.json`) or a KM3 file (`.km3`), the textual metamodel notation of the ATL tool chain. KM3 has no namespace URIs, so each root package of a KM3 metamodel is registered under its name, as the ATL tool chain does, with a warning on standard error, and a model refers to it by a namespace declaration with that name, such as `xmlns:Library="Library"`. `swift-aql` finds such a metamodel beside a model as it finds Ecore and JSON metamodels.

`--km3-primitives` chooses how the data types that a KM3 metamodel declares are read. With `ecore`, the default, a data type named after a primitive type, such as `String` or `Integer`, stands for the built-in Ecore data type, such as `EString` or `EInt`, so models of the metamodel read and write their values as with an Ecore metamodel. With `declared`, every declared data type becomes a data type of its package, as in the KM32EMF transformation of the ATL tool chain. The `km3-primitives` key of the configuration file chooses it as well, and the option overrides it. `swift-ecore convert` converts a metamodel between KM3, Ecore and JSON in either direction.

#### Metamodel Formats

The format registry of swift-ecore reads metamodels in Ecore, JSON, KM3, EMOF, Emfatic, Xcore and OCLinEcore, imports metamodels from ASDL, Langium, Xtext and SDF3 grammars, and reads models in XMI, JSON and UML. It chooses the format of a file from its extension and its contents, so a format that recognises its documents takes precedence over XMI: an EMOF metamodel saved as `shop.xmi` counts as a metamodel wherever a command decides whether a file is one, such as for `--metamodel`, a metamodel given with `swift-mtl generate --model`, and the metamodels that `swift-aql` finds beside a model. A model file with the extension `uml` is read and written as a UML model, in the layout of Eclipse UML2, rather than as generic XMI.

`--package-name`, `--ns-uri` and `--ns-prefix` name the package of a metamodel imported from a grammar (the name only for a grammar that declares none), `--asdl-enumerations <all-nullary|never>` chooses which ASDL sum types become enumerations, `--langium-types <normal|strict>` whether the classes of a Langium grammar come only from its declared types, and `--sdf3-labels` whether the argument labels of an SDF3 grammar name the features. Every command that reads metamodels accepts them, and the configuration file keys of the same names choose them too, for the tools that read a configuration file. Langium, Xtext and SDF3 are only read: writing a document in one of them is an error that lists the formats that can hold the document.

A UML class model (`.uml`) is accepted wherever a metamodel is, such as with `--metamodel`, `--source-metamodel` or `--target-metamodel`: the Ecore metamodel that it describes is derived as the Eclipse UML2 tools derive it. Multi-level models in the MetaDepth notation (`.mdepth`) are read by every tool: `swift-ecore` inspects, validates and converts them, with `--level-crossing <strict|declared|non-strict>` choosing which references may cross levels (`declared` by default), and `swift-aql` and `swift-mtl generate` present them as the deep view of a level with `--deep-view <level>`.

The commands of `swift-ecore` that read models and metamodels accept `--ocl <file.ocl>`, which can be given several times. Each Complete OCL document adds its constraints to the metamodels after they are loaded, so `swift-ecore validate` checks the invariants of the document, and `swift-ecore convert` writes them into a converted metamodel as OCL annotations. `swift-ecore validate` translates every OCL invariant into AQL before it evaluates it, so that OCL keeps its meaning where the two languages differ; an invariant without an AQL translation is reported as a warning.

#### Libraries

The libraries keep the API of version 0.6, and with it the behaviour of version 0.6:

- `GenerationOptions`, `GenerationStep`, `TransformationStep` and `GenModelImportOptions` created with the initialisers of version 0.6 carry `MTLOptions.legacy` or `ATLOptions.legacy`. These initialisers are deprecated in favour of initialisers that take `mtlOptions:` or `atlOptions:`; pass `.legacy` there to keep the behaviour of version 0.6, or `.standard` for the behaviour of this release. The options are held in the properties `mtlOptions` and `atlOptions`, and `unsetFeatureReads` of `GenerationOptions` and `GenerationStep` is part of `mtlOptions`.
- The functions of `GenerationPipeline` called without options use the options of version 0.6.
- `GenerationStep.Result` and `GenerationResult` also report the warnings of the templates, such as `let` blocks skipped with `MTLLetTypeMismatches.skip`.
- `ModellingCommandLine` offers the option groups `SemanticsOptions`, `MTLSemanticsOptions` and `ATLSemanticsOptions` for other command-line tools. `SemanticsOptions.settings(environment:currentDirectory:)` combines the command line, the environment variable and the configuration file into `SemanticsSettings`, which the option groups take in `mtlOptions(settings:)`, `atlOptions(settings:)` and `apply(to:settings:)`; `ModellingConfiguration` reads and finds configuration files. `ConfigurationFileOptions` offers `--config` and `--no-config` without a preset, for commands that choose no behaviours of the languages, and `MetamodelFormatOptions.ecoreLoadOptions(settings:encodingOptions:)` combines the metamodel formats and the encoding of a run with the configuration file.
- `GenerationOptions` and `GenModelImportOptions` have a `containerLookupScope`, which the generation pipelines give the resource sets they create. It is `nil` by default, which leaves the resource sets without a configured scope.
- `GenerationOptions.templateEncoding` and `GenerationStep.templateEncoding` name the encoding of the templates, and `GenModelImportOptions.transformationEncoding` that of a transformation that replaces the bundled one. They are `nil` by default, which reads UTF-8 with a fallback to ISO-8859-1; the warnings of the fallback are reported in `decodingWarnings` of `GenerationResult`, `GenerationStep.Result` and `GenModelResult`.
- `ModellingCommandLine` offers `SourceEncodingOptions` for `--encoding`, `SourceFile` to read a source file in the chosen encoding, `OutputEncodingOptions` for `--output-encoding`, `OutputFile` to write a file or save a model in the chosen output encoding, and `FileDiagnosticReport` to write the warnings and errors of reading a file to standard error. `MetamodelRegistration.registerMetamodels(at:into:announcement:verbose:debug:options:diagnosticOutput:)` registers every root package of a metamodel file in any metamodel format, as `--metamodel` does, `KM3Options` offers `--km3-primitives`, `GrammarImportOptions` the options of grammar imports and `MetamodelFormatOptions` both together, `CompleteOCLOptions` offers `--ocl`, `LevelCrossingOptions` and `DeepViewOptions` offer `--level-crossing` and `--deep-view`, `MultiLevelSupport` reads multi-level models and their deep views, `ATLDeepViewHelpers` offers ATL transformations and queries the deep services on the objects of a view, `MetamodelRegistration.holdsMetamodel(at:registry:)` decides with the format registry whether a file is a metamodel, and `ModelFileFormat.detectedInstanceFormat(of:explicit:)` chooses the format in which a model is read, from its contents when its extension names no format.

## Topics

### Tutorials

- <doc:Tutorials>
