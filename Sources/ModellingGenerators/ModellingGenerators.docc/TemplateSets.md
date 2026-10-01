# Template Sets

Add a language by adding a directory of templates and data.

## Overview

A template set generates code for one language. It is a directory named after the language that holds a descriptor, template modules and, optionally, data models. The bundled sets live in the `Templates` directory of this library. A set can also come from a directory that you name when you generate, so a new language can be tried without changing or rebuilding anything.

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

### Overriding templates

``GenerationOptions/templatePaths`` lists directories that are searched before the bundled set. A file in such a directory replaces the bundled file of the same relative path. A directory either holds a directory named after the language, or the files of the set itself. Later directories win over earlier ones. ``TemplateSet/assemble(language:templatePaths:)`` copies the bundled files and the overrides into a scratch directory, so that modules import each other with the replacements in place.

### Modules

Modules are written in the Acceleo dialect of the Model-to-Text language. The module header names the metamodels that the templates use: the generator metamodel (`http://www.eclipse.org/emf/2002/GenModel`) and the namespace of each data model. Imports are not transitive.

A module declares how existing files are merged with `[merge (...)]`: the delimiters of leading comments, the tag that marks generated members, the tag that marks members to keep and the way blocks end. The language knowledge lives in that declaration and in the queries of the set.

Imports of the generated language are gathered with `[collect ('imports', name)/]` and written where an `[emit ('imports') once]...[/emit]` block stands. Which names need an import and how conflicts are resolved are queries of the set.

### Data models

A set can bundle small models for the templates to read, such as a table that maps model types to target types, the reserved words of the language, or the types that need no import. Each entry of `dataModels` names a metamodel and an instance. Templates reach the root objects of an instance with `templateData('name')`.

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
| `isContainment()`, `isContainer()`, `isBidirectional()`, `reverseGenFeature()`, `isListType()`, `isRequired()`, `isChangeable()`, `isVolatile()`, `isTransient()`, `isDerived()`, `isUnsettable()`, `isResolveProxies()`, `hasDefault()`, `defaultValueLiteral()`, `lowerBound()`, `upperBound()` | Properties of a feature. |
| `setting('name')`, `isSetting('name')` | A setting of the generator model with the default of the metamodel; whether it is set explicitly. |
| `documentation()`, `hasDocumentation()`, `annotationDetail(source, key)` | Model documentation and annotation details. |
| `lines()`, `indentLines(prefix)`, `join(separator)`, `characterCodes()`, `fromCharacterCode()`, `toHexString(width)`, `toOctalString(width)` | Text helpers that the AQL library lacks. |
| `detailKeys()`, `detailValue(key)` | The details of an annotation. |
| `templateData('name')` | The root objects of a data model of the set. |

Services with parentheses win over stored references of the same name, so derived navigation is written `element.genPackage()`; `element.genPackage` would read the stored reference of the generator metamodel.

### Adding a language

1. Create `Templates/<language>/templateset.json`.
2. Write a main module whose main template writes the files.
3. Add query modules for the names, types and imports of the language, and data models for its tables.
4. Declare the merge of existing files in the main module.

No Swift changes are needed.
