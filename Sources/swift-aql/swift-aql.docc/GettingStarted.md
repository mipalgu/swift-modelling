# Getting Started with swift-aql

Learn how to query a model with the swift-aql command-line tool.

## Overview

This guide builds a small metamodel and model, and queries them with
`swift-aql`. The same queries work in the templates of `swift-mtl`.

## Installation

The swift-aql tool is part of the swift-modelling package. Build it
with:

```bash
swift build -c release
```

The executable is then available at `.build/release/swift-aql`.
Run `swift-aql help evaluate` or `swift-aql help query` for the
options of each command.

## A Model to Query

Save this metamodel as `Shop.ecore`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ecore:EPackage xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ecore="http://www.eclipse.org/emf/2002/Ecore"
    name="shop" nsURI="http://www.example.org/shop" nsPrefix="shop">
  <eClassifiers xsi:type="ecore:EClass" name="Shop">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="name"
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EReference" name="items" upperBound="-1"
        eType="#//Item" containment="true"/>
  </eClassifiers>
  <eClassifiers xsi:type="ecore:EClass" name="Item">
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="title"
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EString"/>
    <eStructuralFeatures xsi:type="ecore:EAttribute" name="price"
        eType="ecore:EDataType http://www.eclipse.org/emf/2002/Ecore#//EDouble"/>
  </eClassifiers>
</ecore:EPackage>
```

and this model, beside it, as `shop.xmi`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
    xmlns:shop="http://www.example.org/shop">
  <shop:Shop xmi:id="corner" name="Corner Shop">
    <items xmi:id="tea" title="Green Tea" price="4.5"/>
    <items title="Teapot" price="25.0"/>
  </shop:Shop>
</xmi:XMI>
```

The model declares the namespace `http://www.example.org/shop`, so
`swift-aql` registers `Shop.ecore` as its metamodel and reads `price`
as a real number.

## Your First Queries

The root object of the model is bound to `self` and to the name of
its class with a lower-case first letter, `shop`:

```bash
swift-aql evaluate --model shop.xmi --expression "shop.name"
# "Corner Shop"

swift-aql evaluate --model shop.xmi --expression "shop.items"
# [Item(Green Tea), Item(Teapot)]

swift-aql evaluate --model shop.xmi --expression "shop.items.price->sum()"
# 29.5

swift-aql evaluate --model shop.xmi \
    --expression "shop.items->select(i | i.price < 10).title"
# ["Green Tea"]
```

## Choosing the Context

`--context` binds `self` to another object, found by its `xmi:id`, a
fragment path or its name:

```bash
swift-aql query shop.xmi "self.price" --context tea
# 4.5

swift-aql query shop.xmi "self.price" --context Teapot
# 25.0
```

## Queries in Files

Longer queries are easier to keep in files. AQL comments start with
`--`:

```bash
mkdir -p queries
printf -- "-- the items that cost more than 10\nself.items->select(i | i.price > 10).title\n" \
    > queries/expensive.aql
swift-aql query shop.xmi --query-file queries/expensive.aql
# ["Teapot"]
```

## Using Results in Scripts

Numbers print without decoration, so they can be compared in a shell
script, and a failing query stops a script that uses `set -e`:

```bash
set -e
count=$(swift-aql query shop.xmi "self.items->size()")
if [ "$count" -lt 1 ]; then
    echo "The shop has no items"
    exit 1
fi
```

## Next Steps

- <doc:swift-aql> - The commands, variables and output in detail
- The AQL tutorials of the Swift Modelling documentation
