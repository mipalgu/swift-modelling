# swift-aql

Evaluate AQL queries against models from the command line.

## Overview

The `swift-aql` command-line tool evaluates Acceleo Query Language
(AQL) expressions against models in XMI or JSON format, or against
Ecore metamodels, and prints their values. It uses the same
expression engine as the templates of `swift-mtl`, so a query that
you try out on the command line behaves exactly as it does in a
template.

The tool is built on the swift-aql package
(https://github.com/mipalgu/swift-aql), a pure Swift implementation
of the query language used by Eclipse Acceleo and Sirius
([Eclipse Acceleo](https://eclipse.dev/acceleo/)).

## Commands

### evaluate

Evaluate an expression against the models given with `--model`.

```bash
swift-aql evaluate --model <file> --expression <expression> [options]
swift-aql evaluate --model <file> --expression-file <file.aql> [options]
```

**Options:**

- `--model <file>` - A model to evaluate the expression against (repeatable). Without a model, the expression is evaluated on its own.
- `-e, --expression <expression>` - The expression to evaluate
- `-f, --expression-file <file.aql>` - A file that holds the expression to evaluate; give either this or `--expression`

### query

Evaluate a query against the model given as an argument.

```bash
swift-aql query <file> <expression> [options]
swift-aql query <file> --query <expression> [options]
swift-aql query <file> --query-file <file.aql> [options]
```

**Options:**

- `-q, --query <expression>` - The query to evaluate, instead of the argument after the model
- `-f, --query-file <file.aql>` - A file that holds the query to evaluate

### Options of both commands

- `--context <id-or-name>` - The object to bind to `self` (see below)
- `-m, --metamodel <file.ecore>` - A metamodel of the models in any metamodel format, such as Ecore, JSON, KM3 or EMOF (repeatable); without it, the metamodels beside the models are found automatically
- `--km3-primitives <ecore|declared>` - Whether the data types that a KM3 metamodel declares, such as `String` or `Integer`, are the built-in Ecore data types of the same meaning (`ecore`, the default) or data types of their own package (`declared`); the `km3-primitives` key of the configuration file chooses it too
- `--package-name <name>`, `--ns-uri <uri>`, `--ns-prefix <prefix>`, `--asdl-enumerations <all-nullary|never>`, `--langium-types <normal|strict>`, `--sdf3-labels` / `--no-sdf3-labels` - How a metamodel is imported from an ASDL, Langium, Xtext or SDF3 grammar: the name of the package of a grammar that declares none, its namespace URI and prefix, whether ASDL sum types whose constructors have no fields become enumerations, whether Langium classes come only from declared types, and whether SDF3 constructor labels name the classes; the configuration file keys of the same names choose them too (see the `swift-ecore` article)
- `--deep-view <level>` - Present each multi-level model, such as a MetaDepth document (`.mdepth`), as the deep view of that level, so that `Type.allInstances()` finds the deep instances of a type at the level and the services `clabjectName()`, `ontologicalType()` and `linguisticType()` are available; without it, a multi-level model is read as instances of the linguistic metamodel of multi-level models
- `--unset-features <defaults|undefined>` - Whether unset features read as their defaults (`defaults`, the default, as in the Eclipse Modeling Framework) or as undefined
- `--semantics <standard|legacy>` - The behaviour of this release (`standard`, the default) or of version 0.6 (`legacy`) for every behaviour option below; an option that is given overrides it
- `--container-scope <any-resource|this-resource>` - Whether a model finds the containers of objects of the other models that it holds in containment references
- `--config <file>`, `--no-config` - Read the named configuration file instead of the `.swift-modelling.json` found from the current directory, or read none
- `--encoding <name>` - The character encoding of an expression or query file, such as `ISO-8859-1` or `windows-1252` (default: UTF-8, and ISO-8859-1 with a warning on standard error for a file that is not valid UTF-8); the `encoding` key of the configuration file names it too, and a file that is not valid in the encoding named is an error
- `--collection-arguments <whole|first-element>`, `--collection-kinds <distinguished|sequences>`, `--single-value-collections <set|sequence>`, `--container-lookup <resources|registered-objects>`, `--sequence-union <concatenation|distinct>`, `--null-addition <empty-text|null>`, `--text-form <joined|bracketed>`, `--dot-calls <each-element|collection>` - The behaviours of expressions, with the same meaning and defaults as for `swift-mtl`
- `--strict-aql`, `--no-strict-aql` - Reject the expressions that Eclipse AQL rejects, such as `Sequence{'a'}->union(Set{'b'})` or `Sequence{'a'}->concat('b')`, with a type error instead of accepting them, or accept them (the default); neither preset sets it, and without either flag the `strict-aql` key of the configuration file (`true` or `false`) chooses

The Compatibility with 0.6 section of the [SwiftModelling documentation](https://mipalgu.github.io/swift-modelling/documentation/swiftmodelling/swiftmodelling/index.html) lists every behaviour option with its default and its version 0.6 behaviour, and describes the `SWIFT_MODELLING_SEMANTICS` environment variable and the `.swift-modelling.json` configuration file.

## Variables

Before an expression is evaluated, the tool binds these variables:

- `self` is the context object: the object that `--context` selects, or else the first root object of the first model. Without a model, `self` is `null`.
- Every root object of the models is bound to the name of its class with a lower-case first letter, so the root object of class `Company` is `company`, and that of class `University` is `university`. When several root objects have classes of the same name, the variable holds the first of them. A variable never replaces `self`.

All models are visible to services that search whole models, such as
`allInstances()`, `eContainer()` and `eInverse()`.

## Selecting the Context Object

`--context` looks up its value in three ways, in this order:

1. as an identifier that a model declares with `xmi:id`, such as `company1`;
2. if it starts with a slash, as a fragment path such as `//@departments.0/@employees.1` (the first root object) or `/1/@items.0` (the second root object);
3. as the label of an object, which is the value of its `name` attribute, or else of its first string attribute, such as `Alice Smith`.

A value that matches no object, or a label that several objects share,
is reported as an error.

## Metamodels

A model refers to its metamodels by their namespace URIs. Without
`--metamodel`, the tool registers each metamodel file in the directory
of a model whose namespace URI the model uses, so that the attributes of
the model have the types that the metamodel declares: a `budget` of
type `EDouble` is the real number `500000.0`, not a string. If several
Ecore files beside a model declare the same namespace URI, the tool
asks you to choose one with `--metamodel`. With `--metamodel`, only
the metamodels given are registered, each with every root package that
has a namespace URI. A root package without one is loaded with a
warning on standard error, but not registered. KM3 has no namespace
URIs, so each root package of a KM3 metamodel is registered under its
name instead, and a model refers to it by a namespace declaration with
that name, such as `xmlns:Library="Library"`.

The format registry of swift-ecore decides from the extension and the
contents of each file whether it is a metamodel: an Ecore, JSON, KM3,
EMOF, Emfatic, Xcore or OCLinEcore file, or a grammar from which a
metamodel is imported. An EMOF metamodel saved with the extension
`xmi` is therefore found as a metamodel, while an XMI model is not.
A grammar declares the namespace URI that its import gives, so
`--ns-uri` and its configuration key apply to discovery as well.

A model is read as XMI or JSON by its extension, `xmi` or `json`, and
a file with any other extension in the format of its contents. A file
whose contents are neither XML nor JSON is reported with the supported
formats.

A metamodel file in any metamodel format can itself be given as the
model, so that its first package can be queried, as in
`self.eClassifiers.name`.

A UML class model given with `--metamodel` registers the Ecore
metamodel that it describes. A multi-level model in the MetaDepth
notation (`.mdepth`) is queried as the deep view of a level with
`--deep-view`:

```bash
swift-aql query products.mdepth 'BookStore::ProductType.allInstances()->collect(p | p.clabjectName())' --deep-view 0
```

## Output

The tool prints the value of the expression on one line:

| Value | Printed as |
| --- | --- |
| null | `null` |
| String | in double quotes, with `"`, `\` and control characters escaped: `"Acme Corp"` |
| Integer | its digits: `1995` |
| Real | with a fraction or an exponent, at full precision: `500000.0`, `41666.666666666664` |
| Boolean | `true` or `false` |
| Model object | its class and its label: `Employee(Alice Smith)`, or its class alone if it has no label |
| Collection | its elements in square brackets, whatever its kind: `["Engineering", "Marketing"]` |
| Type | its qualified name: `company::Employee` |

The label of an object is the value of its `name` attribute (ignoring
case) if its class has one, else of its first single-valued string
attribute, else of its first single-valued attribute, as in the
editors of the Eclipse Modeling Framework.

A command exits with status 0 when the expression has been evaluated.
A missing file, an invalid expression, an unknown variable or a failed
operation is reported on standard error, and the command exits with a
non-zero status, so scripts can rely on `set -e`. Warnings are printed on
standard error as `warning: line <line>, column <column>: <message>` and do
not change the exit status: for example, `Sequence{1, 2}.size()` applies
`size` to each integer and warns that `Sequence{1, 2}->size()` calls the
`size` of the collection.

## Examples

```bash
# Navigate from the root object, bound to the name of its class
swift-aql evaluate --model company-data.xmi \
    --expression "company.departments->first().budget"

# Filter and collect
swift-aql evaluate --model company-data.xmi \
    --expression "company.departments.employees->select(e | e.age < 30).name"

# Query from an object selected by its identifier
swift-aql query company-model.xmi --query "self.employees" --context company1

# Read a query from a file and use it in a script
count=$(swift-aql query company-model.xmi --query-file queries/count.aql)

# Name the metamodel explicitly
swift-aql evaluate --model data/company.xmi --metamodel metamodels/Company.ecore \
    --expression "company.name"

# Query a metamodel
swift-aql evaluate --model Company.ecore --expression "self.eClassifiers.name"

# Evaluate an expression without a model
swift-aql evaluate --expression "Sequence{1, 2, 3}->sum()"
```

## Topics

### Essentials

- <doc:GettingStarted>

## See Also

- [Eclipse Acceleo](https://eclipse.dev/acceleo/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
