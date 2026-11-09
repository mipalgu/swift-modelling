# swift-epsilon

Run Epsilon programs, validations, transformations and templates against models from the command line.

## Overview

The `swift-epsilon` command-line tool runs programs of the Epsilon
model management languages against models in XMI, JSON or UML format:

- **EOL**: Epsilon Object Language programs, which query and change
  models and print their results
- **EVL**: Epsilon Validation Language constraints and critiques, with
  their fixes
- **ETL**: Epsilon Transformation Language transformations from source
  models into target models
- **EGL**: Epsilon Generation Language templates, and EGX rules that
  generate one file per model element, keeping hand-written protected
  regions

The tool is built on the swift-epsilon package
(https://github.com/mipalgu/swift-epsilon), a pure Swift implementation
of a subset of the Eclipse Epsilon languages
([Eclipse Epsilon](https://eclipse.dev/epsilon/)). The documentation of
that package lists the constructs of each language that are supported.

The commands are grouped by language:

```bash
swift-epsilon eol run <program.eol> [options]
swift-epsilon evl validate <constraints.evl> [options]
swift-epsilon etl transform <transformation.etl> [options]
swift-epsilon egl generate <template.egl|rules.egx> [options]
```

## Models

Every command binds its models by name, as Epsilon does:

- `--model <name=file>` - A model to read (repeatable). Programs refer
  to it by its name, as in `Bank!Account.all`. Aliases follow the name,
  separated by commas, as in `--model Source,Bank=bank.xmi`, and every
  name must be an identifier.
- `--target <name=file>` - A model that starts empty and is written to
  its file once the run has succeeded (repeatable; `eol run` and
  `etl transform` only).
- `--store <name[=file]>` - Write a model read with `--model` once the
  run has succeeded, back to its own file or to the file given
  (repeatable).
- `-m, --metamodel <file.ecore>` - A metamodel of the models in any
  metamodel format, such as Ecore, JSON, KM3 or EMOF (repeatable).

A model is read in the format of its extension (`xmi`, `json` or `uml`)
or, for any other extension, of its contents, and a model that is
written takes the format of the extension of its file. A model is never
written unless `--target` or `--store` names it, and nothing is written
when the run fails.

Each model read with `--model` is typed by the metamodels whose
namespace URIs its file uses, and each target by the metamodels that no
model read with `--model` uses, or by all of them if every one is used,
as when a model is copied into a model of the same metamodel. A type
name qualified with its model, such as `Ledger!Entry`, always refers to
that model; an unqualified name, such as `Account`, refers to the first
model, in command line order with the targets last, whose metamodel
defines it. A model file that is itself a metamodel, such as an Ecore
file, is typed by the Ecore metamodel, so that a program can work on
its classes, as in `EClass.all`.

A target needs at least one metamodel. Without `--metamodel`, the
classes of a model are inferred from its file but belong to no
metamodel, so programs cannot refer to their types; a warning with a
hint is printed on standard error.

## Commands

### eol run

Run an EOL program against the models.

```bash
swift-epsilon eol run <program.eol> [--model <name=file>]... [--target <name=file>]... [options]
```

What the program prints with `print` and `println` is written to
standard output, and what it prints with `err` and `errln` to standard
error. The program can create elements in a target model, which is
stored once the program has run, and change a model read with
`--model`, which `--store` keeps.

### evl validate

Check every constraint and critique of an EVL module against the
models.

```bash
swift-epsilon evl validate <constraints.evl> [--model <name=file>]... [options]
```

Each constraint or critique that an element does not satisfy is printed
on standard output, with its kind, the element and the message,
followed by the fixes that are offered for it, and a summary:

```
error: constraint NotOverdrawn on Account(cheque): Account cheque is overdrawn by 30
  fix: Clear the balance of cheque
warning: critique HasOwner on Account(holiday): Account holiday has no owner
1 error, 1 warning
```

An unsatisfied constraint is an error and fails validation; an
unsatisfied critique is a warning and fails it only with `--strict`.
When every constraint and critique holds, the command prints
`All constraints are satisfied`.

**Options:**

- `--fix` - Apply the first fix offered for each unsatisfied constraint
  or critique, validate the models again and print what remains, after
  a line `applied: <title>` for each fix applied; give `--store` to keep
  the repaired models
- `--strict`, `--no-strict` - Fail when a critique is unsatisfied as well, or not (off by
  default; the `strict` key of the configuration file sets it too)

### etl transform

Transform source models into target models.

```bash
swift-epsilon etl transform <transformation.etl> --model <name=file>... --target <name=file>... [options]
```

The rules name the models of their types, as in
`rule Account2Entry transform a : Bank!Account to e : Ledger!Entry`.
Each target model starts empty, is filled by the rules and is written
once the transformation has succeeded.

**Options:**

- `--trace` - Print every rule application on standard output, as
  `Account2Entry: Account(savings) -> Entry`
- `--reference-style <encoded|plain>` - How an XMI model that is
  written spells references into its own document (default `encoded`);
  `plain` writes them as Eclipse writes XMI model files. The option
  applies to every model that a command writes, and the
  `reference-style` key of the configuration file chooses it too.

### egl generate

Render an EGL template, or run the rules of an EGX module.

```bash
swift-epsilon egl generate <template.egl> [-o <file>] [options]
swift-epsilon egl generate <rules.egx> [-o <directory>] [options]
```

A template is rendered once, with the parameters as its variables, and
its text is written to standard output, or to the file that `-o`
names. When that file exists, the contents of its enabled protected
regions are kept, and a warning on standard error names each region of
the existing file whose contents are lost.

A file with the extension `.egx` is an EGX module. Its rules render
their templates, which are read relative to the module, and write the
files that their targets name below the directory that `-o` names, or
below the current directory. Each file is printed with what happened
to it, relative to that directory:

```
created: accounts/savings.txt
unchanged: accounts/cheque.txt
```

The status is `created`, `updated`, `unchanged`, `skipped` (the rule
does not overwrite an existing file) or `not written` (the rule has no
target, and the rule name is printed instead of a path). On an
interactive terminal, a progress bar on standard error counts the files
as they are written.

**Options:**

- `-o, --output <path>` - The file that receives the text of a template
  (default: standard output), or the directory below which EGX rules
  write their files (default: the current directory)
- `--no-merge` - Replace an existing output file of a template without
  keeping its protected regions (templates only; the rules of an EGX
  module choose with their `merge` property)
- `--allow-outside-output` - Let EGX rules write files outside the
  output directory, such as `../notes.txt` or an absolute path (EGX
  modules only)

### Options of every command

- `--param <name=value>` - A parameter for the program, which reads it
  as a global variable of that name (repeatable). The value is a
  Boolean for `true` or `false`, an Integer for a whole number, a Real
  for another number and a String otherwise. The name must be an
  identifier that is neither a keyword of EOL nor a variable that the
  languages bind themselves, such as `self` or `out`.
- `--max-call-depth <depth>` - The maximum depth of nested operation
  calls before the program stops with an error (default 1000)
- `-v, --verbose` - Report each step on standard error: the metamodels
  and models loaded, the program run and the models stored
- `--encoding <name>` - The character encoding of the source files,
  such as `ISO-8859-1` or `windows-1252`: the program, the modules it
  imports and the templates that EGX rules name, and the metamodels and
  models in text formats, such as KM3, Emfatic, Xcore, OCLinEcore,
  grammar formats or MetaDepth (default: UTF-8, and
  ISO-8859-1 with a warning on standard error for a file that is not
  valid UTF-8); the `encoding` key of the configuration file names it
  too, and a file that is not valid in the encoding named is an error
- `--output-encoding <name>` - The character encoding of the files
  written, such as `ISO-8859-1` or `windows-1252`: the files that EGX
  rules and `egl generate --output` write, and the stored and target
  models (default: UTF-8); the `output-encoding` key of the configuration
  file names it too. An XML model names the encoding in its declaration
  and writes a character that the encoding cannot hold as a numeric
  character reference; in generated text, such a character is an error
  that names the file, line and column, and the file is not written.
  JSON is always written in UTF-8, with a warning on standard error.
  Standard output is not affected
- `--km3-primitives <ecore|declared>`, `--package-name <name>`,
  `--ns-uri <uri>`, `--ns-prefix <prefix>`,
  `--asdl-enumerations <all-nullary|never>`,
  `--langium-types <normal|strict>`, `--sdf3-labels` /
  `--no-sdf3-labels` - How a metamodel is read from KM3 or imported
  from a grammar, as for `swift-ecore`
- `--container-scope <any-resource|this-resource>` - Whether a model
  finds the containers of objects of the other models that it holds in
  containment references; `--semantics <standard|legacy>` sets it as
  the other tools of the package do
- `--config <file>`, `--no-config` - Read the named configuration file
  instead of the `.swift-modelling.json` found from the current
  directory, or read none

## Source Files

Every source file is parsed before it runs. The problems that the
parser finds are written to standard error, each with its file, line
and column, such as
`error: report.eol: line 3, column 9: Expected an expression but found ';'`.
An error that a program raises while it runs, such as a `throw`
statement, an unknown property or a call nested too deeply, is written
as `Error: report.eol:5:1: <message>`.

A program may import modules with `import 'library.eol';`. A relative
path is read from the directory of the file that imports it, in the
encoding of the run.

Files are written in UTF-8 unless `--output-encoding` names another encoding. An existing
output file that a template or an EGX rule merges protected regions into is read in that
encoding too.

## Exit Statuses

| Status | Meaning |
|:--|:--|
| 0 | The command succeeded; for `evl validate`, every constraint holds, although critiques may not |
| 1 | A file could not be read or written, a source file has syntax errors, or the program raised an error |
| 2 | `evl validate` found an unsatisfied constraint, or with `--strict` an unsatisfied critique; the results have been printed and the models stored |
| 64 | The command line is not valid, such as a model given without a name, a name given twice, or `--store` of a model that `--model` does not bind |

Warnings, such as those about a source file read as ISO-8859-1 or a
protected region whose contents are lost, are printed on standard error
and do not change the exit status.

## Examples

```bash
# Print a report of the accounts of a bank
swift-epsilon eol run report.eol --model Bank=bank.xmi -m Bank.ecore

# Change a model and keep the change
swift-epsilon eol run deposit.eol --model Bank=bank.xmi -m Bank.ecore --store Bank

# Pass parameters
swift-epsilon eol run greeting.eol --param reader=Alice --param factor=2

# Validate, and fail on critiques too
swift-epsilon evl validate rules.evl --model Bank=bank.xmi -m Bank.ecore --strict

# Apply the fixes and save the repaired model as a new file
swift-epsilon evl validate rules.evl --model Bank=bank.xmi -m Bank.ecore \
    --fix --store Bank=repaired.xmi

# Transform a bank into a ledger in JSON, printing the trace
swift-epsilon etl transform bank2ledger.etl --model Bank=bank.xmi \
    --target Ledger=ledger.json -m Bank.ecore -m Ledger.ecore --trace

# Render a template to a file, keeping its protected regions
swift-epsilon egl generate accounts.egl --model Bank=bank.xmi -m Bank.ecore \
    --param title=Accounts -o accounts.txt

# Generate one file per account below generated/
swift-epsilon egl generate accounts.egx --model Bank=bank.xmi -m Bank.ecore \
    --output generated
```

## See Also

- [Eclipse Epsilon](https://eclipse.dev/epsilon/)
- [swift-epsilon](https://github.com/mipalgu/swift-epsilon)
