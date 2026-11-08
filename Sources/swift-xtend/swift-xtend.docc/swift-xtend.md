# swift-xtend

Run Xtend code generators and model methods from the command line.

## Overview

The `swift-xtend` command-line tool interprets a documented subset of
[Eclipse Xtend](https://eclipse.dev/Xtext/xtend/) over models, without a Java virtual machine.
It calls a method of an Xtend class on a model and prints the result, optionally writing the
model that the method changed or created, and it runs an Xtend generator over a model to write
files into output directories.

The tool is built on the swift-xtend package
(https://github.com/mipalgu/swift-xtend), which interprets classes with dispatch and create
methods, extension methods, lambdas and rich strings with Xtend's whitespace rules. Java code
outside the documented subset is reported with its position instead of being ignored.

### Features

- **Run**: `run` calls a method of a class with arguments taken from the model and the command line
- **Generate**: `generate` runs an `IGenerator` style class over a model and writes the files it generates
- **Output Configurations**: named output configurations are mapped to directories with `--output-configuration`
- **Model Output**: `run --output` writes the model that a method changed or that a transformation created
- **Model Formats**: models in XMI, JSON and UML are read and written by file extension or contents
- **Metamodels**: Ecore and the other metamodel formats of the registry are registered with `--metamodel`
- **Source Encodings**: UTF-8 with a reported fallback to ISO-8859-1, or `--encoding`

## Commands

### run

Call a method of an Xtend class on a model and print its result.

```bash
swift-xtend run <file.xtend> --method <method> [options]
```

**Options:**

- `-n, --method <method>` - The method to call (required)
- `--class <class>` - The class to use (default: the only class of the source; with several classes it is an error to omit it)
- `--model <file>` - A model to work on; repeat for several models. The first model is the input of the method
- `-m, --metamodel <file.ecore>` - A metamodel of the models (repeatable)
- `--include <file.xtend>` - A further Xtend source file of the same program (repeatable)
- `--argument <value>` - A text, number or Boolean argument of the method (repeatable, in parameter order)
- `--object <name>` - The name of the model object to pass for a parameter of a model class
- `-o, --output <file>` - Write the model to this file, in the format that its extension names
- `--encoding <name>` - The character encoding of the Xtend sources
- `--semantics <standard|legacy>`, `--config <file>`, `--no-config` - The behaviours of the languages and the configuration file
- `-v, --verbose` - Report progress on standard error

The parameters of the method take their values from their declared types:

| Parameter type | Value |
| --- | --- |
| `Resource` | The first model |
| A class of the metamodel, or `EObject` | The first instance in the models, or the instance whose `name` (or first string attribute) is the `--object` value |
| `List`, `Collection`, `Iterable` or `Set` of a class | All instances of the class |
| `String`, `int`, `long`, `double`, `boolean` and their wrappers | The next `--argument`, converted to the type |
| No declared type | The next `--argument`, read as a number or Boolean where it looks like one, else the first model object |

The result is printed on standard output as Xtend's `toString` would print it. A model object is
printed as its class name followed by its name in parentheses, such as `Book(Dune)`, lists in
square brackets and maps in braces. A method that returns nothing prints nothing. Text written
with `print` or `println` is printed before the result.

With `--output`, the objects that the method created with `new` are written to the file as a
new model, for example the target of a transformation. If it created none, the first model is
written after the method has run, which is useful for methods that change the model.

A source that refers to the types of a metamodel needs `--metamodel`, so that its imports and
parameter types are known.

```bash
# Print a description of the library
swift-xtend run Report.xtend --model library.xmi --metamodel Library.ecore --method describe

# Pass a literal argument after the model
swift-xtend run Report.xtend --model library.xmi -m Library.ecore -n longBooks --argument 400

# Pass a named object
swift-xtend run Report.xtend --model library.xmi -m Library.ecore -n pageCount --object Emma

# Change the model and write the result
swift-xtend run Cleanup.xtend --model library.xmi -m Library.ecore -n retire --output retired.xmi

# Transform a model into a model of another metamodel
swift-xtend run Transform.xtend --model library.xmi -m Library.ecore -m Catalogue.ecore \
    --method toCatalogue --output catalogue.xmi
```

### generate

Run an Xtend generator over a model and write the generated files.

```bash
swift-xtend generate <file.xtend> --model <file> --output <directory> [options]
```

The generator is the class that `--class` names, or else the first class with a `doGenerate` or
`generate` method that takes the model as a `Resource` and an `IFileSystemAccess`, optionally
followed by an `IGeneratorContext`, which is passed as `null`.

**Options:**

- `--model <file>` - The model to generate from (required)
- `-o, --output <directory>` - The directory of the default output configuration (required)
- `--output-configuration <name=directory>` - Map a named output configuration to a directory (repeatable)
- `--class <class>` - The generator class
- `-m, --metamodel <file.ecore>` - A metamodel of the model (repeatable)
- `--include <file.xtend>` - A further Xtend source file of the same program (repeatable)
- `-q, --quiet` - Do not list the generated files
- `--encoding <name>` - The character encoding of the Xtend sources
- `--semantics <standard|legacy>`, `--config <file>`, `--no-config` - The behaviours of the languages and the configuration file
- `-v, --verbose` - Report each file as it is written on standard error

A generator writes to the default output configuration with `fsa.generateFile(path, contents)`,
and to a named one with `fsa.generateFile(path, "name", contents)`. Each name is mapped to a
directory with `--output-configuration name=directory`; the directory is relative to the
working directory, not to `--output`. Writing to a name that is not mapped is an error. Missing
directories are created, and a generated path cannot be absolute or leave its directory.

Each file written is listed on standard output, preceded by the name of its output
configuration and a colon if it is not the default one. Text written with `println` is printed
first. A progress line is shown on an interactive standard error, and a generator that writes
no files produces a warning.

```bash
# Generate files below out/
swift-xtend generate Catalogue.xtend --model library.xmi --metamodel Library.ecore --output out

# Map the docs output configuration to its own directory
swift-xtend generate Catalogue.xtend --model library.xmi -m Library.ecore -o out \
    --output-configuration docs=out/docs

# Choose one generator of several
swift-xtend generate Generators.xtend --class SwiftGenerator --model library.xmi -m Library.ecore -o out
```

## Source Encodings

`--encoding` names the character encoding of the Xtend sources, such as `latin1` or
`windows-1252`. Without it, a source file is read as UTF-8, and a file that is not valid UTF-8 is
read as ISO-8859-1 with a warning on standard error. With it, a file that is not valid in that
encoding is an error. The `encoding` key of the configuration file names the encoding as well,
and the option overrides it.

## Exit Statuses

| Status | Meaning |
| --- | --- |
| 0 | The command succeeded |
| 1 | A file cannot be read or written, the Xtend source has errors, no class or method matches, an argument cannot be bound, or the program fails |
| 64 | The command line is invalid, such as a missing option or a malformed `--output-configuration` |

Warnings, diagnostics and progress are written to standard error; results and the list of
generated files are written to standard output.

## Limitations

- Java classes outside the documented subset of the library cannot be used.
- `run` cannot call a method that needs a file system access; use `generate` for generators.
- Arguments of collection types other than all instances of a model class cannot be given.

## See Also

- [Eclipse Xtend](https://eclipse.dev/Xtext/xtend/documentation/)
- [swift-xtend](https://github.com/mipalgu/swift-xtend)
