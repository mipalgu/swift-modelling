# Converting Ecore to GenModel and Java

Turn an Ecore model into a generator model and into Java source code with the command line tools.

## Overview

The Eclipse Modeling Framework generates Java in two stages. An Ecore model (`.ecore`) describes the structure; a generator model (`.genmodel`) adds the settings that decide what code is written for it; and the generator turns the generator model into Java. The Swift Modelling tools do the same, and the result compiles against the standard EMF runtime.

This article follows the extended library example of the Eclipse Modeling Framework, a model with fourteen classes, one enumeration and thirty-one features. It is published under the Eclipse Public License, so it is not part of this package; download it from its upstream location into the model directory of a project:

```bash
mkdir -p extlibrary/model && cd extlibrary/model
curl -LO https://raw.githubusercontent.com/eclipse-emf/org.eclipse.emf/master/examples/org.eclipse.emf.examples.library/model/extlibrary.ecore
cd ..
```

The layout `<project>/model/<name>.ecore` is the layout of an Eclipse model project. The tools use it to name the project: when the Ecore model lives in a directory called `model`, the project is the name of that directory's parent (here `extlibrary`). Any other layout names the project after the root package, and `--model-project` overrides both.

There are two routes. Both produce the same Java files.

- Two steps: `swift-ecore genmodel` writes the generator model, which you can inspect and edit, and `swift-ecore generate` writes Java from it.
- One step: `swift-atl generate` imports the Ecore model and writes Java without leaving a generator model behind.

### Step 1: the generator model

```bash
swift-ecore genmodel model/extlibrary.ecore --base-package org.example
```

This writes `model/extlibrary.genmodel` beside the Ecore model, named after it, and prints the path. Use `--output` to write elsewhere and `--verbose` for a progress report and a summary:

```text
Packages: 1, classes: 14, enumerations: 1, data types: 0, features: 31, operations: 0
```

With the default `--defaults headless`, the settings that Eclipse's headless generator leaves alone (operation reflection, the root class and import organising) are not written; <doc:MatchingEclipse> explains the presets and the options that change them.

The generator model refers to the Ecore model by relative path and opens unchanged in the Eclipse tooling. It holds the settings of the model (model directory, plug-in identifier, compliance level, copyright and the root class), of each package (prefix, base package, resource kind), and of each class, feature, enumeration and operation. Edit it with a text editor or with Eclipse to change what is generated. The same step is available as `swift-atl generate model/extlibrary.ecore --language genmodel`, which runs the bundled ATL transformation `Ecore2GenModel.atl` and stops after writing the generator model.

### Step 2: Java

```bash
swift-ecore generate --language java model/extlibrary.genmodel --output src-gen
```

The command writes the Java packages below `src-gen` and reports `Generated 36 files`. With the base package `org.example` and the package `extlibrary`, the files are:

| Location below `src-gen/org/example/extlibrary` | Content |
| --- | --- |
| `Book.java`, `Library.java`, ... | The interface of every class, including interfaces such as `Addressable` and `Lendable`. |
| `BookCategory.java` | The Java enumeration of the enumeration `BookCategory`. |
| `ExtlibraryPackage.java`, `ExtlibraryFactory.java` | The package interface with the identifiers of the classifiers and features, and the factory interface. |
| `impl/BookImpl.java`, ... | The implementation class of every class that is not an interface, with the package and factory implementations `ExtlibraryPackageImpl.java` and `ExtlibraryFactoryImpl.java`. |
| `util/ExtlibrarySwitch.java`, `util/ExtlibraryAdapterFactory.java` | The switch and the adapter factory. |
| `util/ExtlibraryXMLProcessor.java`, `util/ExtlibraryResourceFactoryImpl.java`, `util/ExtlibraryResourceImpl.java` | The XML processor, resource factory and resource of a package whose resource kind asks for them. |

A package with constraints also gets a validator in `util`. Without a base package, the Java package is the name of the Ecore package, so the files land in `src-gen/extlibrary`. On an interactive terminal a progress bar with the number of files appears; `--verbose` reports every file on its own line instead.

Giving the Ecore model instead of the generator model, `swift-ecore generate --language java model/extlibrary.ecore --output src-gen`, imports it into a temporary generator model on the way. No generator model remains, and the settings are the defaults of the importer.

### The project layout

By default the output directory receives the Java packages and nothing else. A generator model also has a model directory (`/extlibrary/src` by default: the project, then the source folder). Add `--model-directory` to write below it:

```bash
swift-ecore generate --language java model/extlibrary.genmodel --output project --model-directory
```

This writes `project/extlibrary/src/org/example/extlibrary/...` and, because the project directory is now known, the project files that Eclipse writes for a model project: `project/extlibrary/plugin.xml`, `plugin.properties`, `build.properties` and `META-INF/MANIFEST.MF`, forty files in all, plus the plug-in class when the generator model names one. To choose another project or source folder, set it when you create the generator model:

```bash
swift-ecore genmodel model/extlibrary.ecore --model-project org.example.library --model-directory /org.example.library/src-gen --model-plugin-id org.example.library
```

Note that `--model-directory` means different things on the two commands. On `swift-ecore genmodel` it takes a value, the source directory stored in the generator model. On the generate commands it is a flag that makes the output follow the stored directory.

### The single step

```bash
swift-atl generate model/extlibrary.ecore --language java --base-package org.example --output src-gen
```

The input is an Ecore model or a generator model. For an Ecore model the bundled transformation creates the generator model in memory, and the files written are exactly those of the two-step route, so the two output trees are identical for the example. The default output directory is `Generated`. The language `genmodel` (the default) writes the generator model instead, beside the Ecore model unless `--output` names a directory or a `.genmodel` file.

### Command reference

#### swift-ecore genmodel

`swift-ecore genmodel <model.ecore> ... [options]` imports one or more Ecore models into a generator model. Several models each contribute their root packages to one generator model; the first one names the output.

| Option | Meaning |
| --- | --- |
| `--base-package <name>` | The base package of the root packages. |
| `--prefix <Name>` or `--prefix <package>=<Name>` | The prefix of the root package, or of one named package. Repeatable. |
| `--model-project <name>` | The name of the model project. |
| `--model-plugin-id <id>` | The plug-in identifier of the model project. |
| `--model-directory <dir>` | The source directory of the model project, such as `/project/src`. |
| `--copyright <text>` | The copyright text, written at the head of every generated file. |
| `--jdk-level <level>` | The compliance level of the generated code, such as `17.0` (the default). Levels below 5.0 are not supported by the Java templates. |
| `--defaults headless\|wizard` | Which Eclipse defaults the new generator model gets; see <doc:MatchingEclipse>. The default is `headless`. With `--reload`, a preset replaces the three settings of the existing model. |
| `--root-extends-class <name>` | The root class that implementation classes extend. Overrides the preset. |
| `--operation-reflection`, `--no-operation-reflection` | Switch operation reflection on or off, overriding the preset. |
| `--import-organizing`, `--no-import-organizing` | Switch import organising on or off, overriding the preset. |
| `--reload <file.genmodel>` | An existing generator model whose settings are kept; see below. |
| `-o, --output <file>` | The generator model to write (default: beside the first Ecore model). |
| `-v, --verbose` | Show progress and a summary. |

#### swift-ecore generate

`swift-ecore generate <input> [options]` generates code from a generator model or, with an Ecore model, from a temporary generator model. The input can also be an XMI or JSON model for the built-in languages `swift`, `cpp`, `c` and `llvm`, which this article does not cover.

| Option | Meaning |
| --- | --- |
| `-l, --language <name>` | The target language: `java`, the name of a template set that `--template-path` adds, or a built-in language. The default is `swift`, so give `--language java`. An unknown language is reported together with the list of languages that exist. |
| `-o, --output <dir>` | The directory to write below (default: the current directory). |
| `--template-path <dir>` | A directory whose files replace bundled template files of the same name. Repeatable; later directories win. |
| `--force-overwrite` | Replace existing files without merging. |
| `--diff` | Leave existing files alone and write the generated text beside them as `.<name>.new`. |
| `--model-directory` | Write below the model directory of the generator model, and write the project files. |
| `--code-style eclipse\|emf` | The code style of the generated Java; see <doc:MatchingEclipse>. The default is `eclipse`. |
| `--defaults headless\|wizard` | The Eclipse defaults of the temporary generator model. |
| `--root-extends-class <name>`, `--operation-reflection`, `--no-operation-reflection`, `--import-organizing`, `--no-import-organizing` | The same overrides as for `genmodel`. |

The `--defaults` option and the overrides apply only when an Ecore model is imported. Giving them with a `.genmodel` input, or with a built-in language, is an error.
| `-v, --verbose` | Report every file. |

#### swift-atl generate

`swift-atl generate <model> [options]` accepts the same inputs and performs the import with an ATL transformation.

| Option | Meaning |
| --- | --- |
| `-l, --language <name>` | `genmodel` (the default) or the name of a template set, such as `java`. |
| `-o, --output <path>` | The output directory (default `Generated`); for the language `genmodel`, the directory or `.genmodel` file to write, by default beside the Ecore model. |
| `--transformations <path>` | An ATL file, or a directory that holds `Ecore2GenModel.atl`, that replaces the bundled transformation. |
| `--base-package`, `--prefix`, `--model-project`, `--model-plugin-id`, `--copyright`, `--jdk-level` | As for `swift-ecore genmodel`. |
| `--defaults`, `--root-extends-class`, `--operation-reflection`, `--no-operation-reflection`, `--import-organizing`, `--no-import-organizing` | As for `swift-ecore genmodel`; see <doc:MatchingEclipse>. |
| `--template-path`, `--force-overwrite`, `--diff`, `--model-directory`, `--code-style` | As for `swift-ecore generate`. |
| `-v, --verbose` | Report every file. |

`swift-atl generate` has no `--reload`: to keep the settings of an existing generator model, use `swift-ecore genmodel --reload`, or give the generator model itself as input.

### Regenerating

Generated files are meant to live beside hand-written code. Generating into a directory that holds earlier output merges the new text into the existing Java files:

- A member whose documentation comment carries `@generated` is regenerated.
- A member whose comment says `@generated NOT` is kept exactly as you wrote it.
- A member without the tag, such as a method that you added, is kept, and so are imports that you added.

To take over a generated method, edit it and change the tag in its comment:

```java
/**
 * @generated NOT
 */
public int getPages()
{
    return Math.max(pages, 1);
}
```

Two options change the merge. `--force-overwrite` replaces every existing file with the generated text. `--diff` leaves existing files alone and writes the generated text beside each as a hidden file `.<name>.new` (for example `.Book.java.new`), so that you can compare it with a tool of your choice. When both are given, `--force-overwrite` wins.

Only Java files are merged. Of the project files, an existing `plugin.xml`, `MANIFEST.MF` and `plugin.properties` are kept as they are unless `--force-overwrite` is given, and `build.properties` is replaced only while there is no `plugin.xml` yet. They are never merged by key.

### Changing the model and keeping the settings

When the Ecore model changes, create the generator model again with `--reload`, so that the settings you edited survive:

```bash
swift-ecore genmodel model/extlibrary.ecore --reload model/extlibrary.genmodel --base-package org.example
```

Settings are kept for the elements that still exist, matched by name; new elements get the defaults and removed elements are dropped. Options given on the command line override the existing settings, and the compliance level is kept unless `--jdk-level` is given. The three Eclipse settings (operation reflection, root class and import organising) are kept too, unless you give `--defaults`, which replaces all three, or one of their flags, which replaces that setting. Then generate again as above: your `@generated NOT` members stay.

### Changing the templates

`--template-path <dir>` replaces bundled template files by file name. A directory with a copy of `Header.mtl` changes the head of every file and nothing else:

```bash
swift-ecore generate --language java model/extlibrary.genmodel --output src-gen --template-path my-templates
```

See <doc:TemplateSets> for the layout of a set and <doc:JavaGeneration> for the modules of the Java set.

### Compiling the result

The generated code needs the EMF runtime: the `org.eclipse.emf.common`, `org.eclipse.emf.ecore` and `org.eclipse.emf.ecore.xmi` libraries, the OSGi framework and the Eclipse core runtime. The script `Scripts/fetch-emf-runtime.sh` of the swift-modelling repository downloads the jars from Maven Central and prints the class path:

```bash
CLASSPATH="$(Scripts/fetch-emf-runtime.sh emf-runtime)"
mkdir -p classes
javac -nowarn -d classes -cp "$CLASSPATH" $(find src-gen -name '*.java')
```

For the example the thirty-six files compile without errors. In a Maven or Gradle build, depend on the same artefacts under the group `org.eclipse.emf`.

### Using the library

The command line tools are thin layers over ``GenerationPipeline``; see <doc:GettingStarted> for an example.
