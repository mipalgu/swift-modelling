# Type Operations - Runtime Type Checking and Casting
# AQL provides OCL-compatible operations for working with types dynamically

# Conceptual examples (library domain):
# EObject.allInstances()->select(e | e.oclIsTypeOf(Book))
# elements->select(e | e.oclIsKindOf(Book))->collect(e | e.oclAsType(Book))
# book.eClass().name

# OCLISTYPEOF - Exact type match (not including subtypes)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->first().components->select(c | c.oclIsTypeOf(Form))"

# Output: [Form(TaskForm)] (only exact Form instances, not subtypes)

# OCLISKINDOF - Type match including subtypes
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->first().components->select(c | c.oclIsKindOf(Component))"

# Output: [Form(...), DataTable(...), Navigation(...)] (all are subtypes of Component)

# Difference between oclIsTypeOf and oclIsKindOf
swift-aql evaluate --model webapp-data.xmi \
  --expression "let components = webapp.pages->collect(p | p.components)->flatten() in
    Tuple{
      exactForms = components->select(c | c.oclIsTypeOf(Form))->size(),
      allForms = components->select(c | c.oclIsKindOf(Form))->size()
    }"

# Output: Tuple{exactForms=5, allForms=5} (Form has no subtypes in this metamodel)

# OCLASTYPE - Type casting for safe access to subtype features
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->first().components
    ->select(c | c.oclIsKindOf(Form))
    ->collect(c | c.oclAsType(Form).action)"

# Output: ['/api/tasks', '/api/projects', '/api/settings']

# Type casting with navigation
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.components)->flatten()
    ->select(c | c.oclIsKindOf(DataTable))
    ->collect(c | c.oclAsType(DataTable))
    ->collect(t | Tuple{
      name = t.name,
      paginated = t.isPaginated,
      pageSize = t.pageSize,
      columnCount = t.columns->size()
    })"

# Output: [
#   Tuple{name='TaskTable', paginated=true, pageSize=20, columnCount=5},
#   Tuple{name='ProjectGrid', paginated=true, pageSize=10, columnCount=4},
#   ...
# ]

# ECLASS - Get the EClass (metaclass) of an object
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->first().eClass().name"

# Output: 'Page'

# Get all EClass names in use
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.eAllContents()->collect(e | e.eClass().name)->asSet()"

# Output: Set{'WebApp', 'Page', 'Form', 'Field', 'DataTable', 'Column', 'Navigation', 'NavItem', 'Entity', 'Attribute', 'Relationship', 'Stylesheet'}

# Type-based filtering and transformation
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | e.attributes)->flatten()
    ->select(a | a.eClass().name = 'Attribute')
    ->collect(a | Tuple{
      name = a.name,
      type = a.dataType.toString(),
      isPK = a.isPrimaryKey
    })"

# Output: [
#   Tuple{name='id', type='integer', isPK=true},
#   Tuple{name='title', type='string', isPK=false},
#   ...
# ]

# ALLINSTANCES - Get all instances of a type (requires reflection)
swift-aql evaluate --model webapp-data.xmi \
  --expression "EObject.allInstances()->select(e | e.oclIsTypeOf(Entity))->collect(e | e.oclAsType(Entity).name)"

# Output: ['Task', 'Project', 'User', 'Comment', 'Category']

# Type guards for safe navigation
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.components)->flatten()
    ->collect(c |
      if c.oclIsKindOf(Form) then
        Tuple{type='Form', action=c.oclAsType(Form).action}
      else if c.oclIsKindOf(DataTable) then
        Tuple{type='DataTable', pageSize=c.oclAsType(DataTable).pageSize}
      else
        Tuple{type='Other', name=c.name}
      endif endif
    )"

# Output: [
#   Tuple{type='Form', action='/api/tasks'},
#   Tuple{type='DataTable', pageSize=20},
#   Tuple{type='Other', name='MainNav'},
#   ...
# ]

# Dynamic type-based aggregation
swift-aql evaluate --model webapp-data.xmi \
  --expression "let allComponents = webapp.pages->collect(p | p.components)->flatten() in
    Tuple{
      totalComponents = allComponents->size(),
      forms = allComponents->select(c | c.oclIsKindOf(Form))->size(),
      tables = allComponents->select(c | c.oclIsKindOf(DataTable))->size(),
      navigation = allComponents->select(c | c.oclIsKindOf(Navigation))->size(),
      other = allComponents->reject(c |
        c.oclIsKindOf(Form) or c.oclIsKindOf(DataTable) or c.oclIsKindOf(Navigation)
      )->size()
    }"

# Output: Tuple{totalComponents=15, forms=5, tables=4, navigation=3, other=3}

# Type introspection for metamodel analysis
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | Tuple{
    entity = e.name,
    eClass = e.eClass().name,
    ePackage = e.eClass().ePackage.name,
    eAttributes = e.eClass().eAllAttributes->collect(a | a.name),
    eReferences = e.eClass().eAllReferences->collect(r | r.name)
  })->first()"

# Output: Tuple{
#   entity='Task',
#   eClass='Entity',
#   ePackage='WebApp',
#   eAttributes=['name', 'tableName'],
#   eReferences=['attributes', 'relationships']
# }

# Polymorphic queries using type operations
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.components)->flatten()
    ->select(c | c.oclIsKindOf(Form))
    ->collect(f | f.oclAsType(Form))
    ->select(f | f.boundEntity <> null)
    ->collect(f | Tuple{
      form = f.name,
      entity = f.boundEntity.name,
      fieldCount = f.fields->size(),
      requiredFields = f.fields->select(fld | fld.isRequired)->size()
    })"

# Output: [
#   Tuple{form='TaskForm', entity='Task', fieldCount=7, requiredFields=3},
#   Tuple{form='ProjectForm', entity='Project', fieldCount=5, requiredFields=2},
#   ...
# ]

# Type operations enable safe downcasting and polymorphic behaviour
# Always use oclIsKindOf before oclAsType to avoid runtime errors
