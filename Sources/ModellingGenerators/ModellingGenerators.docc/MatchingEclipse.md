# Matching Eclipse

How the generator model and the Java code relate to what the Eclipse Modeling Framework writes, and which options choose between Eclipse's behaviours.

## Overview

The `java` template set is written to reproduce the model code of the Eclipse Modeling Framework generator: the same files, names, members, documentation comments and `@generated` tags, so that files from either tool can be merged with the same hand-written code. Two things in Eclipse itself differ from each other, and the Swift Modelling tools let you choose:

- The settings that a new generator model receives differ between Eclipse's headless generator (`Generator -ecore2GenModel`) and its interactive New EMF Generator Model wizard.
- The layout of the Java text depends on the formatter preferences of the Eclipse workspace, and EMF's own sources use a different style from a default workspace.

### Defaults of the generator model

`--defaults` chooses which Eclipse behaviour a new generator model follows. It is available on `swift-ecore genmodel`, on `swift-ecore generate` when the input is an Ecore model and the language is a template language such as `java`, and on `swift-atl generate` with an Ecore model. A generator model that already exists keeps its own settings, so these options are rejected with an error when the input is a `.genmodel` file or when the built-in language `swift`, `cpp`, `c` or `llvm` is generated.

| Setting | `--defaults headless` (the default) | `--defaults wizard` |
| --- | --- | --- |
| `operationReflection` | Not written; stays at its default of `false`, so there are no operation count constants and no `eInvoke` method. | `true` |
| `rootExtendsClass` | Not written; implementation classes extend `EObjectImpl`. | `org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container` |
| `importOrganizing` | Not written; stays at its default of `false`, so imports are not organised. | `true` |

All other settings are the same in both modes: the importer identifier, the compliance level (`17.0` unless `--jdk-level` says otherwise), the model directory `/<project>/src`, the plug-in identifier, the package prefixes, the resource kind and the settings of classes, features, enumerations, data types, operations and parameters.

The three settings can be overridden individually, on top of either mode, on the same commands:

| Option | Effect |
| --- | --- |
| `--root-extends-class <name>` | The class that implementation classes extend, for example `org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container`. Written to the generator model whatever the preset. |
| `--operation-reflection` / `--no-operation-reflection` | Writes the operation identifiers and the reflective `eInvoke` method, or leaves them out. |
| `--import-organizing` / `--no-import-organizing` | Chooses whether the generated imports are organised. |

An override always wins over the preset: `--defaults wizard --no-operation-reflection` gives the wizard settings without operation reflection. Switching operation reflection off removes both the operation count constants of the package interface and the `eInvoke` method of the implementation classes.

With import organising off, the factory implementation, the switch and the adapter factory import the interface package of the model with a wildcard (`import org.example.extlibrary.*;`), and the other imports are grouped by package with a blank line between groups, as Eclipse writes them. With it on, they import each type that they use explicitly, sorted, in the groups `java`, `javax`, `org`, `com` and then everything else, with a blank line between groups.

When you reload an existing generator model with `swift-ecore genmodel --reload`, its settings are kept unless you say otherwise: with no flag the three settings keep their values, `--defaults` replaces all three with the preset (a `headless` reload removes values that a `wizard` model had written), and an individual flag is applied after that.

Because the settings are stored in the generator model, `--defaults` and the overrides matter only when a generator model is created. Generating from an existing `.genmodel` uses the settings in the file, whichever tool created it. A generator model that was written by the Eclipse wizard therefore produces wizard-style code, and one written by `Generator -ecore2GenModel` produces headless-style code.

### Differences from the bare Eclipse generator

Apart from the three settings above, `--defaults headless` is not byte for byte what `Generator -ecore2GenModel` writes on its own. The tools additionally:

- write `importerID` (`org.eclipse.emf.importer.ecore`), which marks the model as produced by the Ecore importer;
- derive the model directory and the plug-in identifier from the project (`/<project>/src` and `<project>`), where the bare generator leaves them to its arguments;
- capitalise the model name, which is taken from the name of the generator model file;
- write `complianceLevel` (`17.0` unless `--jdk-level` says otherwise);
- write the `foreignModel` and the model references as paths relative to the generator model, so that the pair can be moved together.

The generated Java depends only on the settings in the generator model, so none of these changes it.

### Code style

`--code-style` on `swift-ecore generate` and `swift-atl generate` chooses the layout of the Java text.

| Style | Indentation | Opening brace | Matches |
| --- | --- | --- | --- |
| `eclipse` (the default) | Tabs | On the same line | What Eclipse writes into a workspace that has the default Java formatter preferences. |
| `emf` | Two spaces | On its own line | The layout of EMF's own sources. |

A code style is not a feature of the tool. It is defined by the template set: the styles that exist are the ones the set provides, and `swift-ecore generate --help` is the authority for the set you have. A template set that you add with `--template-path` defines its own styles or none.

### What is not reproduced

- Eclipse's optional code formatter pass (the `-codeFormatting` option of the headless generator, which runs the workspace formatter over the result). The code styles above fix the common layouts instead.
- Merging an existing `plugin.xml`, `MANIFEST.MF` or properties file by key. Existing project files are kept, or replaced when `--force-overwrite` is given; see <doc:ConvertingEcoreToJava>.
- Code for the edit, editor and test projects. Only the model code and the model project files are written.
- Compliance levels below 5.0, and runtimes older than 2.7.
- Models with generic type parameters or generic exceptions in the metamodel, and generic data types with array or parameterised instance types.
- Reflective, dynamic and virtual feature delegation, array accessors, packed enumeration flags, setting delegates, and invariant operations with validation delegates.
- Suppressed interfaces, suppressed reflective metadata, and classes that are external interfaces.
- Data types that derive from a base type, list item type or union member types through extended metadata.
- The Google Web Toolkit runtime platform.

<doc:JavaGeneration> lists what each part of the template set covers.
