# SwiftModelling

Build powerful Model-Driven Engineering (MDE) applications with Swift.

## Overview

SwiftModelling provides a comprehensive suite of CLI tools for Model-Driven Engineering using Swift 6. Transform, validate, and generate code from your models with industry-standard technologies including Ecore, ATL, MTL, and AQL.

### Key Technologies

- **Ecore**: EMF-compatible metamodelling and model validation
- **ATL**: Atlas Transformation Language for model-to-model transformations
- **MTL**: Model-to-Text Language for code generation
- **AQL**: Acceleo Query Language for model analysis

### CLI Tools

- swift-ecore: Model validation, conversion, querying, generator models and code generation
- swift-atl: Model transformation execution and generation from Ecore models
- swift-mtl: Template-based code generation
- swift-aql: Evaluation of AQL queries against models

The documentation of each tool lists its commands and options, and describes its features in detail.

### Architecture

The tools are built on four packages, each a pure Swift implementation without Java dependencies:

- **swift-ecore**: the Ecore metamodel, resources, and XMI and JSON serialisation
- **swift-atl**: the ATL parser and execution engine
- **swift-mtl**: the MTL parser, runtime and generation engine
- **swift-aql**: the AQL expression language that templates and queries share

Besides the four tools, this package offers these library products:

- **ModellingGenerators**: the generator model pipeline and the bundled template sets for Swift, Java, C and C++
- **ModellingPipeline**: steps for running ATL transformations and MTL generations on models in memory, a locator for template sets in the resource directories of other packages, and a pipeline that loads, transforms, generates from and saves models in sequence
- **ModellingCommandLine**: the option groups that the tools share, such as `--param`, `--template-path`, `--metamodel`, `--code-style` and `--semantics`, and a parser for families of `name=value` options, for command-line tools of other packages

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
| `eContainer()` and the services that depend on it | the registered resources are asked, so containers of nested metamodel contents are found (`resources`) | `--container-lookup resources\|registered-objects` | `registered-objects` | templates |
| Integer ranges in ATL collection literals, such as `Sequence{1..3}` | accepted, as in OCL (`ocl`) | `--collection-range-syntax ocl\|eclipse` | `eclipse`: rejected | ATL source |
| `/` with two Integer operands in ATL, such as `7 / 2` | a Real, `3.5`, as in OCL and Eclipse ATL (`real`) | `--integer-division real\|truncating` | `truncating`: the Integer `3` | ATL source |
| Containers of objects that another model of the run holds in a containment reference | found, as each model answers for the objects of any model (`any-resource`) | `--container-scope any-resource\|this-resource` | `this-resource`: each model answers only for its own objects | models |

The options for templates apply to `swift-mtl generate`, `swift-ecore generate` and `swift-atl generate`; the options of the expressions among them (`--collection-arguments`, `--collection-kinds`, `--single-value-collections`, `--sequence-union`, `--null-addition`, `--text-form` and `--container-lookup`) also apply to `swift-aql`. The options for ATL source apply to `swift-atl parse`, `validate`, `analyze`, `compile`, `test`, `transform` and `query`, and to `swift-atl generate` for a transformation given with `--transformations`. `--container-scope` is accepted by every command that accepts `--semantics`, and applies to the models that `swift-mtl generate`, `swift-ecore generate`, `swift-atl generate`, `transform` and `query` load. `--unset-features` and `--let-type-mismatches` have the same defaults in both presets, `defaults` and `error`, and neither preset sets `--strict-aql`. No command writes ATL modules as XMI, so the encoding of ranges in ATL XMI has no option. The help of each command and the documentation of each tool describe the options.

#### Choosing the Semantics from the Environment

Without `--semantics`, the `SWIFT_MODELLING_SEMANTICS` environment variable chooses the preset for every command that accepts `--semantics`. Its values are `standard` and `legacy`; an empty value counts as unset, and any other value stops the command with an error that names the variable, the value and the accepted values.

```bash
# Run every tool of this shell session as version 0.6 did
export SWIFT_MODELLING_SEMANTICS=legacy
swift-mtl generate template.mtl --model input.xmi --output generated/
```

#### Configuration File

A configuration file keeps the behaviours of a project with the project. A command that accepts `--semantics` reads the first file named `.swift-modelling.json` that it finds in the current directory or one of its parent directories, up to and including the first directory that contains `.git`, which is the root of the repository. `--config <file>` reads exactly the named file instead, and `--no-config` reads none; the two cannot be combined.

The file holds a JSON object. Its keys are `semantics` (`standard` or `legacy`) and the names of the behaviour options without their leading `--`: `block-line-breaks`, `collection-parameters`, `check-let-types`, `cache-containers`, `collection-arguments`, `collection-kinds`, `single-value-collections`, `container-lookup`, `sequence-union`, `null-addition`, `text-form`, `collection-range-syntax`, `integer-division`, `container-scope`, `let-type-mismatches`, `unset-features` and `strict-aql`. Each value is the spelling of the option on the command line as a JSON string, except for `check-let-types`, `cache-containers` and `strict-aql`, which take `true` or `false`. A key that does not apply to a command, such as `block-line-breaks` for `swift-atl parse`, is ignored. An unknown key, a value of the wrong JSON type or spelling, text that is not JSON, or JSON that is not an object stops the command with an error that names the file and, where it applies, the key, the value and the accepted values.

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

Sources 3 to 6 choose the preset, and the preset chooses each behaviour that sources 1 and 2 leave open, including the container scope: `any-resource` for `standard` and `this-resource` for `legacy`. `--let-type-mismatches` and `--unset-features` do not depend on the preset: the command line overrides the configuration file, which overrides their defaults, `error` and `defaults`. Without a configuration file and without the environment variable, every command behaves as with `--semantics standard`.

#### Libraries

The libraries keep the API of version 0.6, and with it the behaviour of version 0.6:

- `GenerationOptions`, `GenerationStep`, `TransformationStep` and `GenModelImportOptions` created with the initialisers of version 0.6 carry `MTLOptions.legacy` or `ATLOptions.legacy`. These initialisers are deprecated in favour of initialisers that take `mtlOptions:` or `atlOptions:`; pass `.legacy` there to keep the behaviour of version 0.6, or `.standard` for the behaviour of this release. The options are held in the properties `mtlOptions` and `atlOptions`, and `unsetFeatureReads` of `GenerationOptions` and `GenerationStep` is part of `mtlOptions`.
- The functions of `GenerationPipeline` called without options use the options of version 0.6.
- `GenerationStep.Result` and `GenerationResult` also report the warnings of the templates, such as `let` blocks skipped with `MTLLetTypeMismatches.skip`.
- `ModellingCommandLine` offers the option groups `SemanticsOptions`, `MTLSemanticsOptions` and `ATLSemanticsOptions` for other command-line tools. `SemanticsOptions.settings(environment:currentDirectory:)` combines the command line, the environment variable and the configuration file into `SemanticsSettings`, which the option groups take in `mtlOptions(settings:)`, `atlOptions(settings:)` and `apply(to:settings:)`; `ModellingConfiguration` reads and finds configuration files.
- `GenerationOptions` and `GenModelImportOptions` have a `containerLookupScope`, which the generation pipelines give the resource sets they create. It is `nil` by default, which leaves the resource sets without a configured scope.

## Topics

### Tutorials

- <doc:Tutorials>
