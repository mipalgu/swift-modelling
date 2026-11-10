# Expected error: Ecore holds a single level of types, so the level must be chosen
swift-ecore convert products.mdepth products.ecore

# Output:
# Error: products.mdepth is a multi-level model: give --level <level> to write the metamodel of one level as ecore (levels: 2, 1, 0), or convert it to one of: xmi, json, uml, mdepth (MetaDepth)
