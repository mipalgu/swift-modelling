# Template Sets

Add a language by adding a directory of templates and data.

## Overview

A template set generates code for one language. It is a directory named after the language that holds a descriptor, template modules and, optionally, data models. The bundled sets, `java`, `swift`, `c` and `cpp`, live in the `Templates` directory of this library. A set can also come from a directory that you name when you generate, so a new language can be tried without changing or rebuilding anything.

The descriptor, `templateset.json`, is read into a ``TemplateSetDescriptor``. Only the name, the main module and the main template are required:

```json
{
  "name": "java",
  "summary": "Java model code for the Eclipse Modeling Framework runtime",
  "mainModule": "generate",
  "mainTemplate": "generate",
  "fileCountTemplate": "fileCount",
  "dataModels": [
    { "name": "types", "metamodel": "TypeMapping.ecore", "model": "java-types.xmi" }
  ],
  "layout": { "sourceRootSetting": "modelDirectory", "includeSourceRoot": false },
  "options": { "lineDelimiter": "\n" }
}
```

The main template runs with the generator model as its only argument and writes files with `[file (...)]` blocks. The optional file count template writes the number of files that the main template will write; the pipeline runs it first so that progress reports can show a bar.

`layout.sourceRootSetting` names the generator model setting that holds the source directory, and `layout.includeSourceRoot` decides whether that directory is included in the output path by default. ``GenerationOptions/includeSourceRoot`` (`--model-directory` on the command line) overrides that choice. Templates can call `layoutIncludesSourceRoot()` to decide whether to write files beside the source directory, such as project metadata. `options.lineDelimiter` chooses the line delimiter of generated files. See <doc:JavaGeneration> for the Java source and project layout, <doc:SwiftGeneration> for the Swift layout, <doc:CGeneration> for the C layout and <doc:CppGeneration> for the C++ layout.

### Code styles

A template set writes its text in one layout. The optional `styles` member of the descriptor names other layouts as data, and `defaultStyle` names the one that applies when the caller does not choose, so the generator needs no knowledge of the target language:

```json
{
  "styles": {
    "tabs": {
      "summary": "Tabs, with the opening brace at the end of the preceding line",
      "sourceIndent": "  ",
      "targetIndent": "\t",
      "openerPlacement": "sameLine",
      "files": ["*.java"]
    },
    "spaces": { "sourceIndent": "  ", "targetIndent": "  ", "files": ["*.java"] }
  },
  "defaultStyle": "tabs"
}
```

Each style is a ``TemplateSetDescriptor/Style``. All members are optional:

- `sourceIndent` and `targetIndent` - the indentation unit that the templates write and the unit to produce (a tab if left out). Every unit at the start of a line is replaced; text after the first character that is not a unit is left alone.
- `openerPlacement` - `ownLine` leaves the text as the templates write it, `sameLine` moves a block opener that stands alone on its line to the end of the preceding line, unless that line ends in a statement terminator or a comment, or is itself an opener.
- `files` - glob patterns of the files that the style applies to; without patterns it applies to every file. A `[file]` block that passes `'layout=false'` is never converted.
- `openerToken`, `lineComments`, `blockComments` (a list of `{ "start": ..., "end": ... }`), `quotes` and `terminators` - the lexical conventions that tell code from comments and literals, with the brace conventions as the default.

A style with equal indentation units and `ownLine` selects the layout that the templates write. ``GenerationOptions/codeStyle`` chooses a style by name (`--code-style` on the command line); a name that the descriptor does not declare is rejected with ``GenerationError/unknownCodeStyle(_:_:_:)``, which lists the styles that exist, and so is any name for a set that declares none. A `defaultStyle` must be one of the declared styles. The conversion happens before the generated text is merged with an existing file, so kept members keep their layout.

### Overriding templates

``GenerationOptions/templatePaths`` lists directories that are searched before the bundled set. A file in such a directory replaces the bundled file of the same relative path. A directory either holds a directory named after the language, or the files of the set itself. Later directories win over earlier ones. ``TemplateSet/assemble(language:templatePaths:)`` copies the bundled files and the overrides into a scratch directory, so that modules import each other with the replacements in place.

### Modules

Modules are written in the Acceleo dialect of the Model-to-Text language. The module header names the metamodels that the templates use: the generator metamodel (`http://www.eclipse.org/emf/2002/GenModel`) and the namespace of each data model. Imports are not transitive.

A module declares how existing files are merged with `[merge (...)]`: the delimiters of leading comments, the tag that marks generated members, the tag that marks members to keep and the way blocks end. The language knowledge lives in that declaration and in the queries of the set.

The bundled sets show the two forms of leading comment. The Java set tags a member inside its block documentation comment, `[merge ('/**', '*/', '@generated', '@generated NOT', 'braces', 'files=*.java')/]`. The Swift set tags a member in a line comment of its own above the member, so that the tag stays out of the documentation: an empty end delimiter declares line comments, and because Swift ends a member at the end of its line instead of at a semicolon, the declaration also names the newline as a terminator. The C and C++ sets tag members the same way in `//` comments above the member, with the newline and the semicolon as terminators, and gather their `#include` lines with `[collect ('includes', ...)]` and `[emit ('includes') once]` so that includes added by hand survive.

```text
[merge ('//', '', '@generated', '@generated NOT', 'braces', 'terminators=\n;', 'quotes="', 'files=*.swift')/]
```

Imports of the generated language are gathered with `[collect ('imports', name)/]` and written where an `[emit ('imports') once]...[/emit]` block stands. Which names need an import and how conflicts are resolved are queries of the set.

### Data models

A set can bundle small models for the templates to read, such as a table that maps model types to target types, the reserved words of the language, or the types that need no import. Each entry of `dataModels` names a metamodel and an instance. Templates reach the root objects of an instance with `templateData('name')`.

The Swift set keeps its type table in `swift-types.xmi`, described by `TypeMapping.ecore`. A mapping names the model type or the instance class of a data type, the Swift type, its zero value (`nil` for a type whose properties are optional), the module that provides the type and how a default value literal is written. A reserved word has a kind: a keyword is quoted with backticks wherever it names an element, and a word of the kind `type` or `member` gets a trailing underscore because it would hide a type of the runtime or a member of its protocol. A directory given with `--template-path` can replace the table without any change to the templates.

The `c` and `cpp` sets keep their tables in `c-types.xmi` and `cpp-types.xmi`. Besides the target type, zero value, header (`module`) and literal style, a C mapping names the way a value is stored (`storage`: scalar, string, bytes or pointer) and the type of a parameter, and a C++ mapping says whether a value is passed by value (`byValue`). Their reserved words are keywords of the language and names that would hide a standard type or a generated name; all of them get a trailing underscore.

### Services for templates

``GenModelServices`` offers language-neutral services on the objects of the generator model; ``GenModelServiceName`` lists the names. The services wrap the generator model facade, so they carry no knowledge of any language.

| Service | Result |
| --- | --- |
| `name()`, `capName()`, `uncapName()`, `uncapPrefixedName()`, `upperName()` | The name of the described Ecore element, formatted. Also available on text. |
| `formatName(separator, prefix, includePrefix)` | A text split into words and joined again. |
| `genModel()`, `genPackage()`, `parentGenPackage()`, `genClass()`, `genContainer()` | The enclosing element of a kind. |
| `allGenPackages()`, `genClassifiers()`, `orderedGenClasses()`, `orderedGenClassifiers()` | Packages and classifiers in model, identifier or dependency order. |
| `allGenFeatures()`, `inheritedGenFeatures()`, `implementedGenFeatures()`, `allGenOperations()` | The features and operations of a class, inherited ones first. |
| `baseGenClasses()`, `allBaseGenClasses()`, `baseGenClass()`, `classExtendsGenClass()`, `implementedGenClasses()` | Supertypes of a class. |
| `featureID(f)`, `featureCount()`, `operationID(o)`, `operationCount()`, `classifierID()`, `classifierIDName()` | Numbering. |
| `isMapEntry()`, `labelFeature()`, `isInterface()`, `isAbstract()`, `uniqueValuedGenEnumLiterals()` | Class and enumeration queries. |
| `ecorePackage()`, `ecoreClass()`, `ecoreFeature()`, `ecoreEnum()`, `ecoreEnumLiteral()`, `ecoreDataType()`, `genClassifier()` | The native Ecore element, or the generator classifier for an Ecore classifier. |
| `isAttributeType()`, `isReferenceType()`, `isContainment()`, `isContainer()`, `isBidirectional()`, `reverseGenFeature()`, `isListType()`, `isRequired()`, `isChangeable()`, `isVolatile()`, `isTransient()`, `isDerived()`, `isUnsettable()`, `isResolveProxies()`, `hasDefault()`, `defaultValueLiteral()`, `lowerBound()`, `upperBound()` | Properties of a feature. |
| `setting('name')`, `isSetting('name')` | A setting of the generator model with the default of the metamodel; whether it is set explicitly. |
| `documentation()`, `hasDocumentation()`, `annotationDetail(source, key)` | Model documentation and annotation details. |
| `lines()`, `indentLines(prefix)`, `join(separator)`, `characterCodes()`, `fromCharacterCode()`, `toHexString(width)`, `toOctalString(width)` | Text helpers that the AQL library lacks. |
| `detailKeys()`, `detailValue(key)` | The details of an annotation, in the order the model lists them. |
| `serialisedEcore()`, `serialisedEcore(source)` | The Ecore model of a generator package as `.ecore` text, optionally without the annotations of one source. |
| `templateData('name')` | The root objects of a data model of the set. |
| `layoutIncludesSourceRoot()` | Whether the output location contains the source directory of the generator model (`--model-directory`), as opposed to being that directory. |

Services with parentheses win over stored references of the same name, so derived navigation is written `element.genPackage()`; `element.genPackage` would read the stored reference of the generator metamodel.

### Adding a language

The `swift`, `c` and `cpp` sets are further examples of the steps below; <doc:SwiftGeneration>, <doc:CGeneration> and <doc:CppGeneration> describe what they write.

1. Create `Templates/<language>/templateset.json`.
2. Write a main module whose main template writes the files.
3. Add query modules for the names, types and imports of the language, and data models for its tables.
4. Declare the merge of existing files in the main module.

No Swift changes are needed.
